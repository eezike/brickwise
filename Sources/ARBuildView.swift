import SwiftUI
import RealityKit
import ARKit
import Combine

/// Camera view that finds the printed marker and draws the build relative to it.
struct ARBuildView: UIViewRepresentable {
    @ObservedObject var session: BuildSession

    func makeCoordinator() -> Coordinator {
        Coordinator(buildSession: session)
    }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        view.renderOptions.insert(.disableMotionBlur)
        context.coordinator.start(in: view)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.render()
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, ARSessionDelegate {
        private let buildSession: BuildSession
        private weak var arView: ARView?
        private var anchorEntity: AnchorEntity?

        private let content = Entity()
        private let placedRoot = Entity()
        private let hologramRoot = Entity()

        private var updateSubscription: Cancellable?
        private var time: Float = 0

        private var build: Build { buildSession.build }

        init(buildSession: BuildSession) {
            self.buildSession = buildSession
            super.init()
            content.addChild(placedRoot)
            content.addChild(hologramRoot)
        }

        // MARK: Session setup

        func start(in view: ARView) {
            arView = view
            view.session.delegate = self

            let config = ARWorldTrackingConfiguration()
            if let reference = makeReferenceImage() {
                config.detectionImages = [reference]
                config.maximumNumberOfTrackedImages = 1
            } else {
                print("Brickwise: marker image \(build.marker.imageName).png not found in the app bundle")
            }
            view.session.run(config)

            updateSubscription = view.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
                MainActor.assumeIsolated {
                    self?.animate(deltaTime: Float(event.deltaTime))
                }
            }
        }

        private func makeReferenceImage() -> ARReferenceImage? {
            let spec = build.marker
            guard
                let url = Bundle.main.url(forResource: spec.imageName, withExtension: "png"),
                let image = UIImage(contentsOfFile: url.path),
                let cgImage = image.cgImage
            else { return nil }

            let reference = ARReferenceImage(
                cgImage,
                orientation: .up,
                physicalWidth: CGFloat(spec.physicalWidthMeters)
            )
            reference.name = spec.imageName
            return reference
        }

        // MARK: ARSessionDelegate (called on the main queue)

        nonisolated func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            MainActor.assumeIsolated { handle(anchors) }
        }

        nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            MainActor.assumeIsolated { handle(anchors) }
        }

        private func handle(_ anchors: [ARAnchor]) {
            for case let image as ARImageAnchor in anchors
            where image.referenceImage.name == build.marker.imageName {
                if anchorEntity == nil {
                    attach(to: image)
                }
                buildSession.markerVisible = image.isTracked
            }
        }

        private func attach(to image: ARImageAnchor) {
            guard let arView else { return }
            let entity = AnchorEntity(anchor: image)
            entity.addChild(content)
            arView.scene.addAnchor(entity)
            anchorEntity = entity
            render()
        }

        // MARK: Rendering

        /// Rebuilds the entities for the current step. Cheap enough to do on every step change.
        func render() {
            guard anchorEntity != nil else { return }

            placedRoot.children.removeAll()
            hologramRoot.children.removeAll()

            if buildSession.showBuiltPieces {
                for placement in buildSession.placed {
                    placedRoot.addChild(solidPiece(placement))
                }
            }

            for placement in buildSession.hologram {
                hologramRoot.addChild(hologramPiece(placement))
            }

            if buildSession.stepIndex == 0 {
                hologramRoot.addChild(baseplateOutline())
            }
        }

        /// Gentle float so the hologram reads as "not real yet".
        private func animate(deltaTime: Float) {
            time += deltaTime
            hologramRoot.position.y = 0.0025 * (1 + sin(time * 2.4))
        }

        // MARK: Entity builders

        private func solidPiece(_ p: Build.Placement) -> Entity {
            let color = UIColor(hex: build.hex(for: p.color))
            let material = SimpleMaterial(color: color, roughness: 0.35, isMetallic: false)
            return brick(for: p, bodyMaterial: material, studMaterial: material)
        }

        private func hologramPiece(_ p: Build.Placement) -> Entity {
            let material = hologramMaterial()
            let root = brick(for: p, bodyMaterial: material, studMaterial: material)
            root.addChild(wireframe(size: build.size(of: p)))
            return root
        }

        private func hologramMaterial() -> UnlitMaterial {
            var material = UnlitMaterial(color: UIColor(hex: "#4FE3F0"))
            material.blending = .transparent(opacity: .init(scale: 0.35))
            return material
        }

        /// A box body plus a grid of stud boxes on top, centered on the piece's local center.
        private func brick(for p: Build.Placement, bodyMaterial: Material, studMaterial: Material) -> Entity {
            let size = build.size(of: p)
            let footprint = build.footprint(of: p)
            let stud = build.units.studMeters

            let root = Entity()
            root.position = build.localCenter(of: p)

            let body = ModelEntity(
                mesh: .generateBox(size: size, cornerRadius: 0.0004),
                materials: [bodyMaterial]
            )
            root.addChild(body)

            // Boxes stand in for round studs. On iOS 18+ you can swap in cylinders.
            let studSize: SIMD3<Float> = [0.0048, 0.0017, 0.0048]
            let studMesh = MeshResource.generateBox(size: studSize, cornerRadius: 0.0008)
            for ix in 0..<footprint.x {
                for iz in 0..<footprint.z {
                    let studEntity = ModelEntity(mesh: studMesh, materials: [studMaterial])
                    studEntity.position = [
                        -size.x / 2 + (Float(ix) + 0.5) * stud,
                        size.y / 2 + studSize.y / 2,
                        -size.z / 2 + (Float(iz) + 0.5) * stud
                    ]
                    root.addChild(studEntity)
                }
            }
            return root
        }

        /// Thin glowing edges around a box, centered at the origin.
        private func wireframe(size: SIMD3<Float>, thickness: Float = 0.0007) -> Entity {
            let material = UnlitMaterial(color: UIColor(hex: "#4FE3F0"))
            let root = Entity()
            let half = size / 2
            let signs: [Float] = [-1, 1]

            func edge(_ edgeSize: SIMD3<Float>, _ position: SIMD3<Float>) {
                let entity = ModelEntity(mesh: .generateBox(size: edgeSize), materials: [material])
                entity.position = position
                root.addChild(entity)
            }

            for sy in signs {
                for sz in signs {
                    edge([size.x, thickness, thickness], [0, sy * half.y, sz * half.z])
                }
            }
            for sx in signs {
                for sz in signs {
                    edge([thickness, size.y, thickness], [sx * half.x, 0, sz * half.z])
                }
            }
            for sx in signs {
                for sy in signs {
                    edge([thickness, thickness, size.z], [sx * half.x, sy * half.y, 0])
                }
            }
            return root
        }

        /// Outline of the baseplate footprint, shown on step 1 to help line the real baseplate up.
        private func baseplateOutline() -> Entity {
            let stud = build.units.studMeters
            let plate = build.units.plateMeters
            let plateSpec = build.baseplate
            let origin = build.marker.baseplateCornerFromMarkerCenterStuds

            let size = SIMD3<Float>(
                Float(plateSpec.studsX) * stud,
                plate,
                Float(plateSpec.studsZ) * stud
            )
            let outline = wireframe(size: size)
            outline.position = [
                (origin.x + Float(plateSpec.studsX) / 2) * stud,
                -plate / 2,
                -(origin.z + Float(plateSpec.studsZ) / 2) * stud
            ]
            return outline
        }
    }
}

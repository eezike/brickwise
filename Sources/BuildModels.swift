import Foundation
import simd

// MARK: - JSON schema (matches Resources/demo-cabin.json)

struct Build: Codable {
    let schemaVersion: Int
    let id: String
    let title: String
    let units: Units
    let baseplate: Baseplate
    let marker: MarkerSpec
    let colors: [String: String]
    let parts: [String: PartSpec]
    let steps: [Step]

    struct Units: Codable {
        let studMeters: Float
        let plateMeters: Float
    }

    struct Baseplate: Codable {
        let studsX: Int
        let studsZ: Int
        let color: String
    }

    struct MarkerSpec: Codable {
        let imageName: String
        let physicalWidthMeters: Float
        /// Baseplate front-left corner relative to the marker center, in studs.
        /// x is to the builder's right, z is away from the builder.
        let baseplateCornerFromMarkerCenterStuds: StudOffset
    }

    struct StudOffset: Codable {
        let x: Float
        let z: Float
    }

    struct PartSpec: Codable {
        let label: String
        let kind: String
        let studsX: Int
        let studsZ: Int
        let heightPlates: Int
    }

    struct Step: Codable, Identifiable {
        let index: Int
        let title: String
        let instruction: String
        let placements: [Placement]
        var id: Int { index }
    }

    struct Placement: Codable, Hashable {
        let part: String
        let color: String
        let x: Int
        let z: Int
        let y: Int
        let rotation: Int
    }
}

// MARK: - Loading

enum BuildLoadError: Error {
    case missingFile(String)
}

extension Build {
    static func load(named name: String, bundle: Bundle = .main) throws -> Build {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw BuildLoadError.missingFile(name)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Build.self, from: data)
    }
}

// MARK: - Geometry (all results are meters, in the marker anchor's local space)

extension Build {
    /// Footprint in studs after rotation (a 90 or 270 degree turn swaps x and z).
    func footprint(of p: Placement) -> (x: Int, z: Int) {
        let part = parts[p.part]!
        return p.rotation % 180 == 90
            ? (part.studsZ, part.studsX)
            : (part.studsX, part.studsZ)
    }

    /// Box size of the piece body (width, height, depth) in meters. Studs are not included.
    func size(of p: Placement) -> SIMD3<Float> {
        let part = parts[p.part]!
        let f = footprint(of: p)
        return SIMD3(
            Float(f.x) * units.studMeters,
            Float(part.heightPlates) * units.plateMeters,
            Float(f.z) * units.studMeters
        )
    }

    /// Center of the piece body in the marker anchor's local space.
    ///
    /// ARKit's image anchor has +x along the image's right edge, +y out of the image
    /// (up, when the marker lies flat on the table), and +z toward the image's bottom edge.
    /// With the marker upright toward the builder, "away from the builder" is therefore -z,
    /// which is why build-space z is negated below.
    func localCenter(of p: Placement) -> SIMD3<Float> {
        let stud = units.studMeters
        let plate = units.plateMeters
        let s = size(of: p)
        let origin = marker.baseplateCornerFromMarkerCenterStuds

        let minX = (origin.x + Float(p.x)) * stud
        let minZAway = (origin.z + Float(p.z)) * stud
        let centerX = minX + s.x / 2
        let centerZAway = minZAway + s.z / 2
        let bottomY = Float(p.y) * plate

        return SIMD3(centerX, bottomY + s.y / 2, -centerZAway)
    }

    /// Hex color string for a named color. Falls back to mid gray.
    func hex(for colorName: String) -> String {
        colors[colorName] ?? "#888888"
    }
}

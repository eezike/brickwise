# Brickwise

Demo of an AR build assistant: step through a brick-set manual with holograms showing where each piece goes.

Status: early demo. Step data is hand-authored. Manual ingestion and parts detection are not built yet. The Swift code has not been compiled or run on a device yet.

## Layout

- `Resources/demo-cabin.json`: 12-step sample build (format below)
- `Resources/brickwise-marker.png`: printable tracking marker
- `Sources/BuildModels.swift`: `Codable` types, loader, geometry helpers
- `Sources/BuildSession.swift`: step state
- `Sources/ARBuildView.swift`: RealityKit view that detects the marker and draws the hologram
- `Sources/BuildScreen.swift`: SwiftUI overlay (step pill, instruction, Back/Next)
- `Sources/BrickwiseApp.swift`, `Sources/Support.swift`: app entry, colors
- `Tools/validate_build.py`: checks a build file for bounds, overlaps, and unsupported pieces
- `Tools/make_marker.py`: regenerates the marker image
- `project.yml`: XcodeGen spec

## Run it

1. `brew install xcodegen`
2. `xcodegen generate` (creates `Brickwise.xcodeproj` and `Info.plist`)
3. Open the project, set your signing team, and run on a physical iPhone (AR needs the real camera).
4. Print `Resources/brickwise-marker.png` at exactly 6 cm wide. Lay it flat in front of the baseplate, facing you, with its red corner at top left. Put the 8x8 baseplate just behind it, centered on the marker.

If the console says the marker image was not found or has low quality, check that the PNG is in the app bundle and the print size matches `physicalWidthMeters` in the JSON.

## Build file format

- `x`, `z`: studs from the baseplate front-left corner (x right, z away from the builder)
- `y`: plate heights above the baseplate top (a brick is 3 plates)
- `rotation`: 0, 90, 180, 270; `x`/`z` are the minimum corner of the rotated footprint
- `marker.baseplateCornerFromMarkerCenterStuds`: where the baseplate sits relative to the printed marker center

Validate a build:

```
python3 -I Tools/validate_build.py Resources/demo-cabin.json
```

## Known risks

- The marker-to-baseplate transform in `localCenter(of:)` assumes the marker lies flat and faces the builder. If holograms appear mirrored or behind the baseplate, check the z sign there first.
- Studs are drawn as small boxes. On iOS 18+ you can swap in cylinders.
- Marker tracking quality depends on print quality and lighting. Test in the demo room.

## Next

- Voice control ("next", "back") with a tap fallback
- Parts check (scripted first, real detection later)
- Manual ingestion (local script first)

# Brickwise

Demo of an AR build assistant: step through a brick-set manual with holograms showing where each piece goes.

Status: early demo. Step data is hand-authored. Manual ingestion and parts detection are not built yet.

## Layout

- `Resources/demo-cabin.json`: 12-step sample build (schema below)
- `Sources/BuildModels.swift`: `Codable` types, loader, and geometry helpers
- `Sources/BuildSession.swift`: step state (`placed` solid pieces, `hologram` current pieces)
- `Tools/validate_build.py`: checks a build file for bounds, overlaps, and unsupported pieces

## Build file format

- `x`, `z`: studs from the baseplate front-left corner (x right, z away from the builder)
- `y`: plate heights above the baseplate top (a brick is 3 plates)
- `rotation`: 0, 90, 180, 270; `x`/`z` are the minimum corner of the rotated footprint
- `marker.baseplateCornerFromMarkerCenterStuds`: where the baseplate sits relative to the printed marker

## Validate a build

```
python3 -I Tools/validate_build.py Resources/demo-cabin.json
```

## Xcode setup

1. Create an iOS app (SwiftUI) and add the files in `Sources/`.
2. Add `Resources/demo-cabin.json` to the app bundle.
3. Add a printed marker image to an AR Resource Group named `brickwise-marker` (physical width 0.06 m, matching the JSON).

The marker-to-baseplate transform in `localCenter(of:)` is untested on device. If holograms appear mirrored or behind the baseplate, check the z sign there first.

## Next

AR view: RealityKit `ARView` that detects the marker, draws `placed` as solid bricks and `hologram` as a glowing box, with Next and Back.

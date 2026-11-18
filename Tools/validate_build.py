import json
import sys


def footprint(part, rotation):
    w, d = part["studsX"], part["studsZ"]
    return (d, w) if rotation % 180 == 90 else (w, d)


def main(path):
    with open(path) as f:
        build = json.load(f)

    bx, bz = build["baseplate"]["studsX"], build["baseplate"]["studsZ"]
    parts, colors = build["parts"], build["colors"]
    occupied = {}
    problems = []

    for i, step in enumerate(build["steps"], start=1):
        if step["index"] != i:
            problems.append(f"step {i}: index is {step['index']}")
        for p in step["placements"]:
            if p["part"] not in parts:
                problems.append(f"step {i}: unknown part {p['part']}")
                continue
            if p["color"] not in colors:
                problems.append(f"step {i}: unknown color {p['color']}")
            if p["rotation"] % 90 != 0:
                problems.append(f"step {i}: rotation {p['rotation']} not a multiple of 90")
            part = parts[p["part"]]
            w, d = footprint(part, p["rotation"])
            h = part["heightPlates"]
            if p["x"] < 0 or p["z"] < 0 or p["x"] + w > bx or p["z"] + d > bz:
                problems.append(f"step {i}: {p['part']} outside baseplate")
            cells = [
                (p["x"] + dx, p["z"] + dz, p["y"] + dy)
                for dx in range(w)
                for dz in range(d)
                for dy in range(h)
            ]
            for c in cells:
                if c in occupied:
                    problems.append(f"step {i}: {p['part']} overlaps step {occupied[c]} at {c}")
                    break
            supported = p["y"] == 0 or any(
                (p["x"] + dx, p["z"] + dz, p["y"] - 1) in occupied
                for dx in range(w)
                for dz in range(d)
            )
            if not supported:
                problems.append(f"step {i}: {p['part']} at y={p['y']} has nothing under it")
            for c in cells:
                occupied[c] = i

    total = sum(len(s["placements"]) for s in build["steps"])
    print(f"{len(build['steps'])} steps, {total} placements")
    if problems:
        print("PROBLEMS:")
        for line in problems:
            print(" -", line)
        sys.exit(1)
    print("OK: in bounds, no overlaps, every piece supported")


main(sys.argv[1])

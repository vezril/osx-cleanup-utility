# App icon

Design source-of-truth for the application icon.

The committed master is **`docs/app-icon/AppIcon.png`** (1024×1024) — the single
source of truth and build input. The build reads it to generate the `.icns` that
becomes the distributed app's Finder/Dock icon. This folder also holds the design
spec and the generation prompt below.

## Concept

**External drive being swept clean.** A small external hard drive (rounded
enclosure at a slight angle, with green + blue LED indicator lights) with a broom
sweeping a file and a folder off to one side — clearing away digital clutter — on
a soft blue→teal squircle. The palette matches the app's safety-tier colors
(cache = teal, delegated = blue) and reads as a clean, trustworthy system tool.

## Design spec (Apple HIG-aligned)

| Aspect | Requirement |
| --- | --- |
| **Shape** | Apple "squircle" — continuous-curvature rounded square; background fills the whole frame (macOS masks the corners) |
| **Subject** | External drive (with depth + LEDs) + broom sweeping a file and folder aside; the drive is the clear focus |
| **Style** | Clean, modern macOS look with subtle depth; soft top-down lighting; not flat-rectangle, not cartoonish |
| **Color** | Blue→teal gradient (on-brand with the tier palette) |
| **Padding** | Comfortable; the composition stays simple and legible at small sizes |
| **Hard NOs** | No text/letters/numbers, no stars/sparkles/spark-or-gem logos (Gemini's own mark), no border, no external drop shadow |
| **Export** | 1024×1024 PNG master, square |

## Generation prompt (Gemini / Imagen)

This is the prompt that produced the current master. Gemini has no negative-
prompt field, so the "do not" instructions live inline; iterate via follow-up
messages ("remove the small sparkle", "make the drive bigger", "fewer files").

```text
Create a macOS application icon in the clean, simple style of Apple's Human
Interface Guidelines. It is a rounded square (Apple's smooth "squircle" shape)
whose background fills edge to edge with a soft gradient — light sky blue at the
top blending to a deeper teal-blue at the bottom. In the center, place a small
external hard drive: a rounded-rectangle enclosure shown at a slight angle so it
has clear three-dimensional depth (not a flat rectangle), in soft white/silver
with gentle shading, and two small glowing LED indicator lights on its front (one
green, one blue) as round dots. A simple, minimal broom or hand brush is sweeping
across the drive, pushing a few small, simple file and folder icons (a plain
document shape and a plain folder shape) off to one side, as if clearing away
clutter. Keep the composition simple and uncluttered with comfortable padding.
Soft top-down lighting, clean modern look. Crisp edges; it must stay clear and
legible at small sizes.

Important: do NOT include any text, letters, numbers, stars, sparkles,
four-pointed star shapes, spark or gem logos, or AI logos. The LED lights and the
files/folders should be simple solid shapes with no text or writing on them.
```

### Tuning knobs

```
  drive depth   "slight angle"  →  "gentle 3/4 view"   (more dimension)
  broom         "minimal broom" →  "small hand brush"  (cleaner silhouette)
  clutter       files + folder  →  fewer items if it gets busy at small sizes
  palette       blue→teal (default)  →  "indigo to violet" / "graphite to slate"
  fallback fix  "absolutely no text or sparkles anywhere; one clear external drive"
```

## How it's used

Turning the master into the actual app icon is handled by the `app-icon`
OpenSpec change:
- `scripts/make-icns.sh` generates `AppIcon.icns` (16→1024 px, @1x/@2x) from the
  master — generated at build time, never committed.
- `scripts/make-app-bundle.sh` assembles the `.app` with the icon and
  `CFBundleIconFile`, and is called by the release workflow.

> Note: the Finder/Dock icon applies to the assembled/released `.app`. Running
> via raw `swift run` (no `.app` bundle) shows a generic Dock icon — a runtime
> override was intentionally deferred (see the `app-icon` change's design D5).

To replace the icon, drop a new 1024×1024 PNG at `docs/app-icon/AppIcon.png` and
rebuild.

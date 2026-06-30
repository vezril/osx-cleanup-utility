# App icon

Design source-of-truth for the application icon. The icon is **not yet wired
into the app** — this folder holds the generation prompt and (once produced) the
master image, ready for a future `app-icon` change to turn into a real
`AppIcon.appiconset` / `.icns`.

## Concept

**Ultra-minimal "clean sparkle."** A single white sparkle/shine glyph centered
on a blue→teal squircle. The palette intentionally matches the app's safety-tier
colors (cache = teal, delegated = blue) and reads as *clean, fresh, trustworthy
system tool*.

## Design spec (Apple HIG-aligned)

| Aspect | Requirement |
| --- | --- |
| **Shape** | Apple "squircle" — continuous-curvature rounded square; background fills the whole frame (macOS masks the corners) |
| **Subject** | ONE simple, centered glyph; legible from 16px to 1024px |
| **Style** | Flat-modern with subtle depth (soft top-down light, gentle inner highlight); not skeuomorphic, not a sticker/cartoon |
| **Color** | Single blue→teal gradient (on-brand with the tier palette) |
| **Padding** | Generous negative space; glyph never touches edges |
| **Hard NOs** | No text/letters/numbers, no external drop shadow, no dock reflection, no busy detail, no photographic texture |
| **Export** | 1024×1024 PNG master, square, opaque (full-bleed) |

## Generation prompt

Paste into an image-generation model (Gemini / Imagen, DALL·E, etc.):

```text
A minimalist macOS application icon in the official Apple Human Interface
Guidelines style. The entire square frame is filled, edge to edge, by a smooth
soft gradient that blends from a light sky blue at the top to a deeper teal-blue
at the bottom, shaped as a rounded square with Apple's continuous-curvature
"squircle" corners. Perfectly centered on it is a single, simple, elegant white
sparkle/shine glyph (a clean four-point star-shine) with a soft glow, conveying
cleanliness, freshness, and reclaimed space. Generous negative space around the
glyph; calm and balanced. Soft top-down studio lighting, very subtle depth and
inner highlight, flat-modern (not skeuomorphic, not a sticker). Crisp,
high-resolution, vector-clean edges, no noise, no texture. Stays legible at very
small sizes. 1024x1024, square.
Negative: no text, no letters, no words, no numbers, no border, no outer drop
shadow, no dock reflection, no background scene, not cartoonish, not busy.
```

### Tuning knobs

```
  sparkle style   "a single four-point star-shine"  →  "a soft six-point sparkle"
                  or  "two sparkles, one large and one small, asymmetric"
  palette         blue→teal (default)  →  "indigo to violet"
                  or  "graphite to slate (pro/dark tool look)"
  finish          "flat-modern"  →  "with a subtle glassy / frosted highlight"
  fallback fix    if it adds text or a hard square, append:
                  "absolutely no text anywhere; perfectly smooth squircle corners"
```

## Where to put the generated image

Save your chosen master here as:

```
docs/app-icon/icon-1024.png      (1024×1024, PNG, square, opaque)
```

A larger square master (e.g. 2048×2048) is also welcome — name it
`icon-master.png` — but `icon-1024.png` is the one the build will downscale from.

## Next step (a future change, not done yet)

Once `icon-1024.png` is in place, an `app-icon` OpenSpec change will:
1. Generate the full size set (16, 32, 64, 128, 256, 512, 1024 px at @1x/@2x)
   into `Sources/OSXCleanupApp/Resources/AppIcon.appiconset/`.
2. Reference it from the app bundle so the icon shows in Finder/Dock.
3. Include it in the release `.app` produced by the CI release pipeline.

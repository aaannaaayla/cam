# cam

A focused iOS content creation app — camera, filters, collage, scrapbook, and feed planning. Built for creators who want Dazzcam's aesthetic, 17v28's editing, and a social grid planner, without the bloat of Canva.

## Features

| Feature | Free | Pro |
|---|---|---|
| Camera (photo) | ✓ | ✓ |
| Camera (video) | — | ✓ |
| Filters | 14 | 49 (63 total) |
| Adjustments | Brightness, Contrast, Saturation, Warmth | + Exposure, Highlights, Shadows, Sharpness, Vignette, Grain, Fade |
| Collage layouts | 4 | 9+ |
| Scrapbook templates | 3 | 9+ sticker packs |
| IG Feed Planner | 12 slots | Unlimited + multi-grid |
| TikTok Feed Planner | 9 slots | Unlimited |
| Export | HD | 4K |

**Subscription:** $4.99/mo · $34.99/yr

## Setup

### Requirements
- Xcode 15.4+
- iOS 17.0+ deployment target
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Steps

```bash
git clone https://github.com/aaannaaayla/cam
cd cam
brew install xcodegen          # one-time
bash scripts/setup-assets.sh   # downloads LUTs, stickers, fonts
xcodegen generate
open cam.xcodeproj
```

Then in Xcode:
1. Select your **Team** in Signing & Capabilities
2. In App Store Connect, create two subscriptions:
   - `com.annayladesigns.cam.pro.monthly` — $4.99/month
   - `com.annayladesigns.cam.pro.yearly` — $34.99/year
3. Add your **App Icon** to `cam/Resources/Assets.xcassets/AppIcon.appiconset/`
4. Build & run on a real device (camera requires physical device)

### Previewing screens (no device needed)

Every screen has a SwiftUI preview in `cam/Preview/Previews.swift`. Open that
file (or any view), show the canvas with **Editor ▸ Canvas (⌥⌘↩)**, and pick a
screen from the canvas dropdown — it renders instantly with sample data, no
simulator boot or camera required. The previews are DEBUG-only and never ship.

Only the **live camera** tab needs a real iPhone (the simulator has no camera);
everything else runs in the simulator or canvas.

## Architecture

```
cam/
├── App/               # Entry point, tab bar
├── Core/
│   ├── Models/        # FilterPreset, MediaItem, Project, GridPlannerModel
│   ├── Services/      # SubscriptionManager (StoreKit 2), PhotoLibraryService, StorageService
│   └── Extensions/    # Color+Extensions
├── Features/
│   ├── Camera/        # AVFoundation camera with real-time filter preview
│   ├── Editor/        # Filter strip + adjustment knobs (Core Image)
│   ├── Create/        # Collage builder + freeform scrapbook canvas
│   ├── Planner/       # Instagram & TikTok feed grid planner
│   └── Library/       # Photo library browser → editor
└── Components/        # FilterThumbnailView, ProBadge, PaywallView
```

## Filter System

- **Free (14):** Original, Linen, Bright, Warm, Cool, Fade, Matte, B&W, Golden, Haze, Pop, Vintage, Fresh, Tasty
- **Pro Film (7):** Portra, Kodak, Fuji, Ilford, Ektar, Cinestill, Disposable
- **Pro Moody (5):** Shadow, Deep, Noir, Moody, Cinematic
- **Pro Aesthetic (6):** Cream, Blush, Sage, Dusty, Peach, Morning
- **Pro Bright (4):** Clean, Airy, Sunlit, Overexposed
- **Pro Food (11):** Crispy, Yummy, Sweet, Picnic, Deli, Brunch, Café, Citrus, Garden, Bakery, Grill — *Foodie-inspired*
- **Pro Film/Aesthetic (11):** Warm Film, Matte Film, Golden Hr, Clean Film, Retro, Dreamy, Pastel, 70s, Cool Film, Faded Sun, Indie — *Tezza-inspired*
- **Pro Camera (2):** FXN R, FXN — *Dazz Cam-inspired* (warm yellow Fuji-style film)
- **Pro B&W (3):** Silver, Faded, Stark

All filters are original Core Image grades — no third-party LUTs copied. The
Foodie-, Tezza-, and Dazz Cam-*inspired* sets recreate the *aesthetic* (which
isn't copyrightable) with our own parameters; they do not use those apps'
proprietary filter files.

## Camera & Editing Flow

Filters work two ways, and they're connected:

1. **Live filter** — pick a filter in the camera and the viewfinder shows it applied
   in real time (Metal/Core Image at 60fps). What you see is what you get.
2. **Post-edit** — after capture, the editor opens with that same live filter already
   applied. Editing is **non-destructive**: the raw photo is kept underneath, so you
   can fine-tune, swap to a different filter, or reset to Original at any time.

Shooting clean? Leave the filter on Original and the editor opens with the untouched
photo. Editing a library photo always starts clean.

## Feed Planner

Local-only visual planning tool (no API/account connection required). Drag & drop to reorder slots. Previews your 3-column IG or TikTok grid before posting.

## Notes

- Video filtering runs on the device GPU via AVFoundation + Core Image
- Scrapbook canvas supports multi-touch drag, pinch-to-scale, and rotation per element
- All projects and grid plans stored locally via `FileManager` (JSON + Data)
- StoreKit 2 handles subscriptions; no server needed

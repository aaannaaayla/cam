# cam

A focused iOS content creation app — camera, filters, collage, scrapbook, and feed planning. Built for creators who want Dazzcam's aesthetic, 17v28's editing, and a social grid planner, without the bloat of Canva.

## Features

| Feature | Free | Pro |
|---|---|---|
| Camera (photo) | ✓ | ✓ |
| Camera (video) | — | ✓ |
| Filters | 12 | 50+ |
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

- **Free (12):** Original, Linen, Bright, Warm, Cool, Fade, Matte, B&W, Golden, Haze, Pop, Vintage
- **Pro Film (7):** Portra, Kodak, Fuji, Ilford, Ektar, Cinestill, Disposable
- **Pro Moody (6):** Shadow, Deep, Noir, Moody, Cinematic + Cinestill
- **Pro Aesthetic (6):** Cream, Blush, Sage, Dusty, Peach, Morning
- **Pro Bright (4):** Clean, Airy, Sunlit, Overexposed
- **Pro B&W (3):** Silver, Faded, Stark

All filters built on Core Image — no third-party dependencies.

## Feed Planner

Local-only visual planning tool (no API/account connection required). Drag & drop to reorder slots. Previews your 3-column IG or TikTok grid before posting.

## Notes

- Video filtering runs on the device GPU via AVFoundation + Core Image
- Scrapbook canvas supports multi-touch drag, pinch-to-scale, and rotation per element
- All projects and grid plans stored locally via `FileManager` (JSON + Data)
- StoreKit 2 handles subscriptions; no server needed

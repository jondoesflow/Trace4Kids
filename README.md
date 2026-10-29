# Trace4Kids

A native iPhone and iPad app that helps children aged 4 and up copy a picture onto paper.

Pick a picture from the photo library, and it appears over the live camera. Slide **See-through** until you can see both the picture and the paper, drag and pinch to fit it to the page, and **Lock** it. Prop the device over the paper, look at the screen and draw over the lines.

- **Pictures from the device only:** the system photo picker (no photo-library permission). Nothing is downloaded.
- **See-through:** a slider from 5% to 100%.
- **Move, resize, turn:** drag, pinch and twist anywhere on the screen. Turns snap to straight. **Fit** puts it back in the middle, **Turn** rotates a quarter turn, **Flip** mirrors it.
- **Lock:** stops gestures, hides the tools and (where iOS allows) stops the screen rotating while the device lies flat.
- **Corner marks:** pink brackets at the corners and ticks at the middle of each edge. Draw dots on the paper under them; next time, line the picture up with the dots.
- **Keep tracing:** the picture and its position, size, rotation and options are saved on the device automatically and restored next time, with a "Welcome back" prompt to line up the corners.
- **Lines:** shows the picture as outlines (Core Image line overlay), which are easier to trace.
- **Light box:** white screen at full brightness, for tracing with thin paper on the screen.
- **See more / Torch:** 0.5× ultra-wide camera and torch, on devices that have them.
- **Child-safe:** no ads, accounts, purchases, network access, analytics or links out (apart from iOS Settings when camera access is off). "Data Not Collected" privacy label. Age rating 4+.

## Building (no Mac needed)

This project is worked on from Windows. GitHub's hosted Macs build, test and ship it.

- **CI** (`.github/workflows/ci.yml`): every push to `main` or `claude/*` generates the Xcode project with XcodeGen, builds, runs the unit and UI tests on an iPhone simulator and pushes the build summary, test results and screenshots to the **`ci-reports`** branch.
- **TestFlight** (`.github/workflows/testflight.yml`): archives, signs with cloud-managed signing and uploads to App Store Connect. Run it from Actions → TestFlight → **Run workflow**, or push to the `testflight` branch. It needs the same four repository secrets as the other apps: `APPLE_TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`.
- **Pages** (`.github/workflows/pages.yml`): publishes `docs/` (home, support and privacy pages) for the App Store listing.

See [HANDOFF.md](HANDOFF.md) for the one-time App Store Connect setup.

### On a Mac

```bash
brew install xcodegen
xcodegen generate
open Trace4Kids.xcodeproj
```

Xcode 26 or later. iOS 17 or later. Select your team under Signing & Capabilities to run on a device. The camera needs a real device; the simulator shows a paper background instead.

## Project layout

```
project.yml              XcodeGen spec (iOS 17+, iPhone and iPad, com.jondoesflow.trace4kids)
Trace4Kids/
  App/                   Trace4KidsApp (launch arguments, orientation lock), AppModel (state, saving)
  Models/                TraceSettings (placement maths, options, Codable)
  Storage/               TraceStore (picture + settings in Application Support)
  Camera/                CameraController (back camera, zoom, torch), CameraPreview
  Rendering/             ImageTools (downscaling, line drawing)
  UI/                    Home, Trace, TraceCanvas (gestures, corner marks), How to trace, theme
  Demo/DemoPicture.png   Sample picture for UI tests (excluded from Release builds)
Trace4KidsTests/         Swift Testing unit tests
Trace4KidsUITests/       XCUITest flows with screenshots
docs/                    GitHub Pages: home, support, privacy
AppStore/metadata.md     App Store listing text, age rating and privacy answers
```

## Launch arguments (for testing)

| Argument | Effect |
|---|---|
| `-TraceDemo` | Paper background instead of the camera, "Try the sample picture" button, tracing kept in a temporary folder |
| `-TraceEmpty` | With `-TraceDemo`, starts with nothing saved |
| `-TraceStart` | With `-TraceDemo`, opens the sample picture straight away |

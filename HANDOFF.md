# Handoff: shipping Trace4Kids from the JonR PC

The JonR PC runs Windows, so nothing here builds locally. GitHub's hosted Macs build, sign and upload the app (`.github/workflows/testflight.yml`, the same workflow as Grade and Steady). The PC's job is the one-time setup in the browser and pressing **Run workflow**.

You can do these steps yourself, or open Claude Code on the PC in a clone of this repo (with Chrome connected) and say: *"Follow HANDOFF.md to get Trace4Kids onto TestFlight."*

## 0. Get the code

```powershell
git clone https://github.com/jondoesflow/Trace4Kids.git
# or, in an existing clone
git pull origin main
```

## 1. Register the bundle ID (one time)

[developer.apple.com → Identifiers → +](https://developer.apple.com/account/resources/identifiers/list) → App IDs → App → Description `Trace4Kids`, Explicit bundle ID **`com.jondoesflow.trace4kids`**. No extra capabilities are needed (the camera needs no entitlement).

## 2. Create the app record (one time)

[App Store Connect → Apps → + → New App](https://appstoreconnect.apple.com/apps):

- Platform: iOS
- Name: `Trace4Kids` (if taken: `Trace4Kids – Draw & Trace`; the home-screen name stays Trace4Kids)
- Primary language: English (UK)
- Bundle ID: `com.jondoesflow.trace4kids`
- SKU: `trace4kids`
- User access: Full access

## 3. Add the four repository secrets (one time)

GitHub → jondoesflow/Trace4Kids → Settings → Secrets and variables → Actions → New repository secret. Use the same values as Photoeditor/RSD:

| Secret | Value |
|---|---|
| `APPLE_TEAM_ID` | 10-character Team ID (developer.apple.com → Membership details) |
| `ASC_KEY_ID` | App Store Connect API key ID |
| `ASC_ISSUER_ID` | App Store Connect API issuer ID |
| `ASC_KEY_P8` | Full text of `AuthKey_XXXX.p8`, including the BEGIN/END lines |

Secrets are per repository, so they have to be added again here even though the other apps have them.

## 4. Upload a build

GitHub → Actions → **TestFlight** → **Run workflow** (branch `main`). It takes about 10–15 minutes, then Apple processes the build for another 5–30 minutes. Each run gets a new build number. Logs land on the `testflight-reports` branch.

Then in App Store Connect → Trace4Kids → TestFlight, add yourself (Internal Testing) and install it with the TestFlight app on your iPhone and iPad.

## 5. Support and privacy pages

App Store Connect needs a Support URL and a Privacy Policy URL. `docs/` holds both pages, and `.github/workflows/pages.yml` publishes them to `https://jondoesflow.github.io/Trace4Kids/` on every push to `main`.

- The pages give jon@jondoesflow.com as the contact address.
- The repo is public, so GitHub Pages and the Mac build minutes are free.

## 6. Fill in the listing and submit

Everything to paste is in [`AppStore/metadata.md`](AppStore/metadata.md): name, subtitle, description, keywords, category, the 4+ age rating answers, the "Data Not Collected" privacy answer and the App Review notes.

Screenshots: every CI run saves simulator screenshots to the `ci-reports` branch under `screenshots/`. Apple needs iPhone 6.9" and iPad 13" sizes; real-device shots of tracing over paper make the best first screenshot.

## Checklist

- [ ] Bundle ID `com.jondoesflow.trace4kids` registered
- [ ] App record created in App Store Connect
- [ ] Four secrets added to this repo
- [ ] TestFlight workflow run, build installed on iPhone and iPad
- [ ] Tested on a real device: camera view, see-through, pinch/drag, lock, corner marks, leave and come back
- [ ] Support and privacy pages live at jondoesflow.github.io/Trace4Kids
- [ ] Listing, age rating (4+), privacy (Data Not Collected) filled in
- [ ] Submitted for review

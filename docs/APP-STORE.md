# App Store

## App Store Connect

The app record is **Hitch: Daily Word Chain**, Apple ID **6816792614**, bundle ID
`co.nsgsolutions.hitch`, SKU `hitch-ios`. It's on the Individual account, so the seller name is
Noah Greensweig (team `S6QW7SV228`).

### Done (September 28–29, 2026)

| Item | Value |
|---|---|
| Name / subtitle | Hitch: Daily Word Chain / A compound word puzzle |
| Category | Games > Word, Puzzle |
| Content rights | No third-party content |
| Age rating | 4+, every answer None or No (see note below) |
| Privacy Policy URL | `https://nsgnoah.github.io/hitch/privacy.html` |
| App Privacy | Data Not Collected, published |
| Price / availability | Free in all 175 countries or regions, the same as Spinola |
| Apple silicon Mac, Apple Vision Pro | Turned off until the app is tested there |
| Trader status (EU) | Non-trader, already set on the account |
| Promotional text, description, keywords | Filled; keywords use 93 of 100 characters |
| Support URL | `https://nsgnoah.github.io/hitch/` |
| Copyright | `2026 Noah Greensweig` |
| Build | 4 (version 1.0), uploaded October 2 with yellow revealed letters, the five-letter limit and the new share. Build 3 was the first with `PrivacyInfo.xcprivacy`; the slimmer gold-and-cream icon needs build 5 |
| Release | Automatically after approval |

Age rating note: a few chains contain ordinary compound words such as "root beer", "beer garden",
"shot glass", "gun shot" and "gun powder". These were treated as vocabulary rather than alcohol or
weapon content, the way word games are usually rated. Revisit this if a chain ever becomes
thematic.

### Still to do

1. **Screenshots.** In Media Manager, drag `appstore/screenshots/iphone-6.9/*` into iPhone 6.9"
   Display and `appstore/screenshots/ipad-13/*` into iPad 13" Display, in filename order. They are
   1320×2868 and 2064×2752 JPEGs with no alpha channel. The iPad set leaves out Results and How to
   Play because those sheets cut off inside the iPad's centered card.
2. **App Review Information.** Untick "Sign-in required" and fill the contact: Noah Greensweig,
   `noah@nsgsolutions.co`, and a phone number starting with `+1`. App Store Connect won't save this
   section without the phone number. Notes:

   > Hitch is a daily word puzzle with no accounts, sign-in, purchases, ads, or network access, so
   > every feature is available right away.
   >
   > To play: tap Play on the home screen, type a guess, and press Go (return). Each wrong guess,
   > or "Reveal a letter", shows one more letter. Tap a highlighted row to switch between the top
   > and bottom ends. Earlier chains are under Archive, Statistics is the bar-chart button, and How
   > to Play is the ? button.
   >
   > The privacy policy and contact email are in the app under How to Play > About.

3. **Add for Review**, then **Submit for Review**.

## Screenshots

The screenshots (retaken October 2 for build 4) show a seeded play history: 29 chains played, 93%
won (two broken chains), a 19-day streak, today's chain finished with one revealed letter, and
No. 10 half played with two of the five spare letters used. They were taken on an iPhone 17 Pro Max
and an iPad Pro 13-inch (M5) simulator, iOS 26, at 9:41 with a full battery.

## Support site

`site/` holds the support page and privacy policy. `.github/workflows/pages.yml` publishes it to
`https://nsgnoah.github.io/hitch/` whenever `site/` changes on `main`. GitHub Pages only serves it
while this repo is public; the Spinola policy at `nsgnoah.github.io/ola/` stopped resolving when
the `ola` repo went private.

The privacy policy also lives in the app (`PrivacyPolicyView` in `Hitch/Views/InfoViews.swift`).
Change both together.

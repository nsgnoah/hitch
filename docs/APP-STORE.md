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
| Build | 6 (version 1.0), attached to the version October 2, with the cream ink-and-pine icon. Build 4 added yellow revealed letters, the five-letter limit and the new share; build 3 was the first with `PrivacyInfo.xcprivacy` |
| Release | Automatically after approval |
| Screenshots | iPhone 6.9" (6) and iPad 13" (4) from `appstore/screenshots`, uploaded October 2. The 6.9" set also covers the 6.5" and 6.7" sizes |
| App Review Information | No sign-in required; contact Noah Greensweig, `noah@nsgsolutions.co`, and the same phone number as Spinola; notes below |

Age rating note: a few chains contain ordinary compound words such as "root beer", "beer garden",
"shot glass", "gun shot" and "gun powder". These were treated as vocabulary rather than alcohol or
weapon content, the way word games are usually rated. Revisit this if a chain ever becomes
thematic.

### Submitted

Version 1.0 (build 6) was submitted for App Review on October 2, 2026 at 12:39 PM CDT and is
Waiting for Review. It releases automatically once approved.

App Review notes, as entered:

> Hitch is a daily word puzzle with no accounts, sign-in, purchases, ads, or network access, so
> every feature is available right away.
>
> To play: tap Play on the home screen, type a guess, and press Go (return). Each wrong guess, or
> "Reveal a letter", shows one more letter. Each chain allows five extra letters; a wrong guess
> after those are used ends the game and shows the full chain. Tap a highlighted row to switch
> between the top and bottom ends. Earlier chains are under Archive, Statistics is the bar-chart
> button, and How to Play is the ? button.
>
> The privacy policy and contact email are in the app under How to Play > About.

## Screenshots

The screenshots (retaken October 2 for build 4) show a seeded play history: 29 chains played, 93%
won (two broken chains), a 19-day streak, today's chain finished with one revealed letter, and
No. 10 half played with two of the five spare letters used. They were taken on an iPhone 17 Pro Max
and an iPad Pro 13-inch (M5) simulator, iOS 26, at 9:41 with a full battery.

## Support site

`site/` holds the support page and privacy policy. `.github/workflows/pages.yml` publishes it to
`https://nsgnoah.github.io/hitch/` whenever `site/` changes on `main`. GitHub Pages only serves it
while this repo is public. Spinola's pages at `nsgnoah.github.io/ola/` went down while the `ola`
repo was private; it was made public again on October 2.

The privacy policy also lives in the app (`PrivacyPolicyView` in `Hitch/Views/InfoViews.swift`).
Change both together. The October 2 update (describing the new share) is live on the site and
in the repo, but build 6, the one in review, still shows the September 27 wording in the app;
the next build brings it in line.

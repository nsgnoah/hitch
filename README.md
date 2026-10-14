# Hitch

A daily word-chain puzzle for iPhone and iPad. Each day there's a chain of seven words where every word joins the next to make a compound word or familiar phrase (SNOW → BALL → ROOM → SERVICE → …). You get the top and bottom words and fill in the five between, working inward from either end. Wrong guesses cost letters; fewest extra letters wins.

No accounts, ads, analytics, purchases, or network access. Everything stays on the device.

## What it does

- **Home** — today's number and date, a miniature of today's chain showing which words are solved, Play / Continue / See Today's Chain, and links to the Archive, Statistics, and How to Play. How to Play opens on first launch. A new chain is out at midnight local time; the home screen picks it up when the app returns to the foreground or the day changes.
- **Game** — the chain hangs on a vertical line, one knot per word. The two open ends are highlighted; tap one (or press Tab / an arrow key on a hardware keyboard) to switch. The first letter of each word is free. A wrong guess, or *Reveal a letter* (⌘R), shows one more letter. Each chain has five extra letters to spare; a miss after they're gone breaks the chain and shows the rest. A word whose last letter gets revealed counts as revealed, not solved. As two neighbors are solved, the phrase they make appears on the link between them.
- **Results** — headline (*A perfect chain.*, *2 extra letters.*, *The chain broke.*), one dot per hidden word (pine for no extra letters, amber for one, ember for more, stone for revealed or missed), played / win % / streak / best, the full chain with each link spelled out, Share, and a countdown to the next chain.
- **Statistics** — played, win %, current and max streak, and a distribution of wins by extra letters used (0–5).
- **Archive** — every chain from No. 1 to today, with its result or *In progress*. Any of them can be played.
- **How to Play** — rules, an example board, a color legend, and an About section with the privacy policy, support email, and version.

The keyboard is the system one, driven by an invisible `UIKeyInput` view (`Views/KeyCatcher.swift`): capitals only, no autocorrect or suggestions, return key labeled Go. Tapping the board brings it back if it's dismissed. iPad supports all orientations and hardware keyboards; the app is limited to one window, since two windows would each hold a copy of a puzzle and overwrite each other's progress.

Accessibility: VoiceOver labels and announcements for every guess and solve, Dynamic Type, alternate colors under Increase Contrast, shapes instead of color alone under Differentiate Without Color, and a flash instead of a shake under Reduce Motion. Haptics on wrong guesses and solves.

## Layout

- `Hitch/HitchApp.swift` — entry point; puts the shared `ProgressStore` in the environment.
- `Hitch/Model/` — `PuzzleBook` (which chain is today's), `Game` (one puzzle's rules and input), `Progress` (saved records and statistics).
- `Hitch/Views/` — `HomeView`, `GameView` (board, knots, letter slots), `ResultsView`, `InfoViews` (How to Play, Privacy Policy, Statistics, Archive), `KeyCatcher`, `Theme` (colors, fonts, button styles).
- `Hitch/Resources/chains.json` — the puzzles: 100 chains of seven words.
- `Hitch/PrivacyInfo.xcprivacy` — privacy manifest.
- `scripts/make_icon.swift` — draws the app icon.
- `site/` — support page and privacy policy, published with GitHub Pages.
- `appstore/screenshots/` — App Store screenshots (iPhone 6.9", iPad 13").
- `docs/APP-STORE.md` — App Store Connect record, submission history, review notes.
- `project.yml` — [xcodegen](https://github.com/yonaskolb/XcodeGen) spec. The generated `Hitch.xcodeproj` is committed; regenerate it after editing `project.yml` and commit both.

## Build

```bash
xcodegen generate
open Hitch.xcodeproj
```

Pick the `Hitch` scheme and run on an iPhone or iPad (iOS 17+). There are no capabilities, entitlements, or permission prompts. Automatic signing with the team in `project.yml`.

From the command line:

```bash
xcodebuild build -scheme Hitch -destination 'generic/platform=iOS Simulator'
```

There's no test target.

Version and build number are `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml`.

## How puzzles are chosen

`Hitch/Model/PuzzleBook.swift`:

- No. 1 is September 1, 2026, backdated so the Archive had chains on day one. Each calendar day after that is the next number.
- Day math uses the Gregorian calendar in the device's current time zone, whatever calendar the user displays, so the chain changes at local midnight.
- Puzzle *n* is chain `(n - 1) % 100` from `chains.json`, so the 100 chains start over at No. 101 (December 10, 2026) unless more are added.

## Rules and saving

`Hitch/Model/Game.swift` holds one puzzle's state: which letters show on each word, which words are solved or given, and which end the keyboard is typing into. Only the first and last unsolved words are playable; solving one moves that end inward. Each newly opened word shows its first letter for free. Extra letters are counted per word beyond that first letter, and `PuzzleRecord.spareLetters` (5) caps the total.

`Hitch/Model/Progress.swift` saves a `PuzzleRecord` per puzzle number as JSON in `UserDefaults` (`hitch.records.v1`) after every move, so a chain can be left and resumed. Each record stores the chain's words; if a chain in `chains.json` is edited, the old record no longer matches and that puzzle starts fresh. Statistics (played, win %, streaks, distribution) are computed from these records. Streaks count consecutive daily numbers won, ending today or, if today isn't finished, yesterday.

## Sharing

Share sends plain text to the iOS share sheet: the puzzle number and result, the top and bottom words, and a row of squares for each word between — 🟩 guessed, 🟨 revealed, ⬜ for a word that was fully revealed or left unsolved.

```
Hitch No. 1 · 2 extra letters
CANOE
🟩🟨🟩🟩
…
LAMP
```

## App icon

`scripts/make_icon.swift` draws two interlocking links, ink over pine on cream, with gaps at the crossings like a knot diagram:

```bash
swift scripts/make_icon.swift Hitch/Assets.xcassets/AppIcon.appiconset/icon.png light
swift scripts/make_icon.swift Hitch/Assets.xcassets/AppIcon.appiconset/icon-dark.png dark
swift scripts/make_icon.swift Hitch/Assets.xcassets/AppIcon.appiconset/icon-tinted.png tinted
```

The light icon has no alpha channel (the App Store requires that); the dark and tinted variants have a clear background.

## Support site

`site/index.html` (support and FAQ) and `site/privacy.html` (privacy policy). `.github/workflows/pages.yml` publishes `site/` to <https://nsgnoah.github.io/hitch/> on every push to `main` that touches it, or by hand from the Actions tab. GitHub Pages only serves it while the repo is public.

The privacy policy also lives in the app (`PrivacyPolicyView` in `Hitch/Views/InfoViews.swift`). Change both together.

## Privacy

Hitch makes no network requests and includes no third-party code. The privacy manifest declares no tracking and no collected data, and one required-reason API: `UserDefaults` (reason `CA92.1`, the app's own data). App Store Connect's App Privacy is *Data Not Collected*. Export compliance: `ITSAppUsesNonExemptEncryption` is `NO`.

## App Store

Listed as **Hitch: Daily Word Chain** (bundle ID `co.nsgsolutions.hitch`), free, Games > Word and Puzzle, rated 4+. iPhone and iPad; Mac and Vision Pro availability are off.

As of the last update to `docs/APP-STORE.md` (October 6, 2026):

- Version 1.0 (build 6) was submitted for App Review on October 2 and was Waiting for Review, set to release automatically.
- Version 1.0.1 (build 8, the current `project.yml`) was uploaded to App Store Connect on October 6. It brings the in-app privacy policy in line with the site. It can't be submitted until 1.0 is live.

See `docs/APP-STORE.md` for the full listing, review notes, screenshot setup, and TestFlight groups.

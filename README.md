# Hadisak

**Hadisak** is an offline, Anki-inspired flashcard app for iOS. It helps you learn with Front/Back cards, spaced repetition (SM-2), decks, and bilingual English/Persian support — with no network and no cloud sync required.

---

## What it does

Hadisak is built for focused study on your device:

1. **Create decks** — group cards by topic (languages, exams, notes, etc.).
2. **Add flashcards** — each card has a front (prompt) and back (answer), plus optional tags.
3. **Study with spaced repetition** — rate each card Again / Hard / Good / Easy; the SM-2 scheduler decides when you see it next.
4. **Import & export** — bring cards in from TXT/CSV/JSON, or back up your collection as JSON or SQL.
5. **Switch language & theme** — English or Persian UI (RTL when Persian), and several visual themes.

Everything stays on-device via **SwiftData**. There is no account, analytics, or remote sync.

---

## Features

| Area | Details |
|------|---------|
| **Cards** | Front / Back text, tags, suspend & bury |
| **Decks** | Create, rename, duplicate, search; due / new / learning stats |
| **Study** | Flip card, progress bar, reverse mode (show back first) |
| **Scheduler** | SM-2: learning steps, new → learning → review, daily new-card limit |
| **Import** | TXT (`---` blocks), CSV (`front,back[,tags]`), JSON backups |
| **Export** | Full or single-deck JSON; SQLite-style SQL dump |
| **Languages** | English & Persian UI; card text keeps its own LTR/RTL per side |
| **Themes** | Light, Dark, Coffee, Ocean, Forest, Midnight, Sakura, Matcha, Ember, Slate |

---

## Requirements

- Xcode 15+ (project created with Xcode 26 tooling)
- iOS 17+
- Swift 5.9+ / SwiftUI / SwiftData

---

## Build & Run

1. Open `hadisak.xcodeproj` in Xcode.
2. Select an iOS Simulator or device (iOS 17+).
3. Press **Run** (`⌘R`).

Unit tests:

```bash
xcodebuild test -scheme hadisak -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Project structure

```
hadisak/
├── Models/                  # SwiftData: Deck, Card, ReviewLog + enums
├── Services/
│   ├── Scheduler/           # Pure SM-2 engine (Again / Hard / Good / Easy)
│   ├── ImportExport/        # TXT, CSV, JSON, SQLite SQL dump
│   └── TextDirection/       # Per-side RTL / LTR detection
├── Theme/                   # App themes & color palettes
├── Settings/                # AppSettings (@Observable, UserDefaults)
├── ViewModels/              # MVVM with Observation framework
├── Views/
│   ├── Root/                # Tab shell (Decks + Settings)
│   ├── Decks/               # List, detail, create / rename
│   ├── Cards/               # Editor, rows, paste-import
│   ├── Study/               # Session, flip card, ratings
│   ├── Settings/            # Preferences + import / export
│   └── Components/          # DirectionalText, EmptyState, badges
├── Utilities/               # Haptics, date helpers
├── Resources/
│   ├── en.lproj/            # English strings
│   └── fa.lproj/            # Persian strings (RTL UI)
└── hadisakApp.swift         # @main entry
```

---

## Architecture

- **SwiftUI** + **SwiftData** — fully offline `ModelContainer`
- **MVVM** — `@Observable` view models (not `ObservableObject`)
- **NavigationStack** — deck → detail → study
- **Dependency injection** — `Environment(AppSettings.self)` and `modelContext`
- Business logic (scheduler, import/export, text direction) lives in pure/service types, separate from views

### Data models

| Model | Role |
|--------|------|
| `Deck` | Named collection of cards; cascade delete |
| `Card` | Front/Back, tags, SM-2 fields, suspend/bury; extensible `cardType` |
| `ReviewLog` | Immutable review history |

### Spaced repetition

`SM2Scheduler` implements a simplified Anki-like SM-2 flow:

- Learning steps (default **1m**, **10m**, configurable)
- States: New → Learning → Review (and Relearning after lapses)
- Ratings: Again / Hard / Good / Easy
- Daily new-card limit (default **20**)

**Reverse mode** only swaps which side is shown first; scheduling and storage are unchanged (no duplicated cards).

### Text direction

`TextDirectionDetector` inspects each card side independently. Persian / Arabic / Hebrew → RTL; Latin scripts → LTR. App language does not change how card content is aligned.

### Themes

| Theme | Character |
|--------|-----------|
| Light | Clean light surfaces, blue accent |
| Dark | High-contrast dark UI |
| Coffee | Warm parchment / brown accent |
| Ocean | Misty aqua, deep teal |
| Forest | Sage paper, evergreen |
| Midnight | Navy night sky, cyan highlights |
| Sakura | Soft blush petals, rose accent |
| Matcha | Quiet tea-room green |
| Ember | Charcoal night with amber glow |
| Slate | Cool graphite, steel-blue |

Theme changes animate via the theme environment. Pick themes in **Settings**.

### Import / Export

| Format | Direction | Notes |
|--------|-----------|--------|
| TXT | Import | Blocks separated by `---` (`Front` / `Back` / optional tags) |
| CSV | Import | `front,back[,tags]` |
| JSON | Import & Export | Full collection or single deck + scheduling + review logs |
| SQLite SQL | Export | Portable SQL dump of decks / cards / logs |

---

## Localization

UI strings live in:

- `Resources/en.lproj/Localizable.strings`
- `Resources/fa.lproj/Localizable.strings`

Switch language in **Settings**. Persian enables RTL layout for the app chrome. Flashcard content is never auto-translated.

---

## Future-proofing

`Card.cardType` (default `"basic"`) and modular services are ready for later features without a big restructure:

- Images / audio attachments
- Cloze deletion & image occlusion
- Statistics & heatmaps
- Tag filters & custom study sessions
- Optional iCloud sync (SwiftData CloudKit)

---

## License

Private project — all rights reserved unless otherwise noted.

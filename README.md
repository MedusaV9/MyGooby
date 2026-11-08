# Gooby

Gooby ist eine offline iOS-App (iOS 17 oder neuer). Ein runder, cremefarbener Hase begleitet kleine Gewohnheiten, Ruheübungen und selbstgeschriebene Abenteuer. Es gibt kein Konto, keinen Server und keine Analyse.

Gooby is an offline iOS app (iOS 17 or newer). A round cream-colored bunny keeps company with small habits, calm exercises, and original adventures. There is no account, no server, and no analytics.

## Bauen / Build

- Xcode 16 oder neuer, Scheme **Gooby**, Ziel **iOS 17**.
- Xcode 16 or newer, scheme **Gooby**, deployment target **iOS 17**.
- Projekt: `Gooby.xcodeproj`. In Xcode öffnen und auf einem Simulator oder einem signierten Gerät starten.
- Open `Gooby.xcodeproj` in Xcode and run it on a simulator or a signed device.

```bash
xcodebuild \
  -project Gooby.xcodeproj \
  -scheme Gooby \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  DEVELOPMENT_TEAM="" \
  build
```

Dieser Befehl erzeugt eine unsignierte Geräte-App. Er installiert sie nicht.

This command produces an unsigned device app. It does not install it.

## GitHub Actions

`.github/workflows/build-ios.yml` startet bei einem Push auf `main` und über `workflow_dispatch`. Der macOS-Runner baut für `generic/platform=iOS` mit abgeschalteter Signierung und lädt das Artefakt **Gooby-unsigned.ipa** hoch.

The workflow runs on a push to `main` and via `workflow_dispatch`. The macOS runner builds for `generic/platform=iOS` with signing off and uploads the artifact **Gooby-unsigned.ipa**.

Andere Branches baut ein manueller Start mit `ref=<branch>` (`Tools/ci.sh build <branch>` erledigt das über `gh api` und wartet auf das Ergebnis). Bei einem manuellen Start läuft zusätzlich der Job `screenshots`: ein Debug-Build im Simulator startet die App mit `-GoobyShot <route> -GoobyLang <de|en>` auf einem Speicher im Arbeitsspeicher mit Beispieldaten und lädt die Bilder als **Gooby-screenshots** hoch. Dieser Job kann den IPA-Build nicht scheitern lassen.

Other branches are built by a manual start with `ref=<branch>` (`Tools/ci.sh build <branch>` does this through `gh api` and waits for the result). A manual start also runs the `screenshots` job: a Debug simulator build launches the app with `-GoobyShot <route> -GoobyLang <de|en>` on an in-memory store with demo data and uploads the images as **Gooby-screenshots**. This job cannot fail the IPA build.

**Eine unsignierte IPA lässt sich auf einem normalen iPhone nicht installieren**, bis sie mit einem gültigen Zertifikat und einem passenden Provisioning Profile neu signiert wurde. Die Datei ist ein Build-Artefakt, keine installationsfertige App.

**An unsigned IPA cannot be installed on a normal iPhone** until it is re-signed with a valid certificate and a matching provisioning profile. The file is a build artifact, not an app that is ready to install.

## Widgets und Live-Aktivitäten / Widgets and Live Activities

Die App bettet die Widget-Erweiterung `GoobyWidgets.appex` (Ordner `GoobyWidgets/`, Ziel **GoobyWidgets**) in `Gooby.app/PlugIns` ein. Sie enthält die Home- und Sperrbildschirm-Widgets und die Oberfläche der Live-Aktivitäten. Code, den App und Erweiterung teilen, liegt in `GoobyShared/`.

The app embeds the widget extension `GoobyWidgets.appex` (folder `GoobyWidgets/`, target **GoobyWidgets**) in `Gooby.app/PlugIns`. It holds the Home and Lock Screen widgets and the Live Activity UI. Code that the app and the extension share lives in `GoobyShared/`.

- **Live-Aktivitäten** (Abenteuer-, Fokus- und Atemtimer) bekommen ihre Inhalte über ActivityKit direkt von der App. Sie brauchen keine Berechtigung und keinen Server und funktionieren nach jeder Signierung.
- **Widgets** lesen den Spielstand aus der App-Gruppe `group.app.mygooby.gooby` (`Gooby/Gooby.entitlements`, `GoobyWidgets/GoobyWidgets.entitlements`). Die unsignierte IPA trägt keine Berechtigungen. Erst wenn du sie mit einem Profil signierst, das diese App-Gruppe für App und Erweiterung enthält, zeigen die Widgets deine Ziele. Ohne App-Gruppe zeigen sie Gooby mit Gruß und Datum, und ein Tipp öffnet die App.
- **Live Activities** (adventure, focus and breathing timers) get their content from the app through ActivityKit. They need no entitlement and no server and work with any signing.
- **Widgets** read the save from the App Group `group.app.mygooby.gooby` (`Gooby/Gooby.entitlements`, `GoobyWidgets/GoobyWidgets.entitlements`). The unsigned IPA carries no entitlements. Only when you sign it with a profile that has this App Group for the app and the extension do the widgets show your goals. Without the App Group they show Gooby with a greeting and the date, and a tap opens the app.

Die Dateien in der App-Gruppe sind ebenfalls vom iCloud-Backup ausgenommen.

The files in the App Group are excluded from iCloud backup as well.

## Daten und iCloud / Data and iCloud

Spielstand, Profilbild und Datenbank liegen lokal im App-Ordner unter Application Support. Dieser Ordner und die Dateien darin sind mit `isExcludedFromBackup` vom iCloud-Backup und von einem iCloud-Geräte-Restore ausgenommen. Nach einer Wiederherstellung aus iCloud ist der Spielstand weg. Eine Kopie entsteht nur, wenn du in den Einstellungen exportierst. Die Exportdatei liegt nur dort, wo du sie selbst ablegst, zum Beispiel in der Dateien-App. Sie wandert nur dann in iCloud, wenn du sie in einen iCloud-Ordner schiebst.

The save, profile photo, and database live in the app’s Application Support folder. That folder and the files inside it are excluded from iCloud backup and from an iCloud device restore via `isExcludedFromBackup`. After an iCloud restore, the save is gone. A copy exists only if you export it in Settings. The export file lives only where you put it, for example in Files. It reaches iCloud only if you move it into an iCloud folder.

## Klänge / Sounds

Alle Klänge liegen im App-Bundle, nichts wird gestreamt. Die Soundeffekte (`Gooby/Resources/Sounds/sfx-*.wav`, eine Liste der Anlässe steht in `GoobySounds.swift`) sind Takes aus der Klangbank von [earshot](https://github.com/Leonxlnx/earshot) (MIT, © 2026 Leon Lin): Klänge, die als Code gespeichert sind und per ID gerendert werden. `Tools/make_sounds.py` schichtet sie, stimmt sie auf eine Tonart und gleicht die Lautstärke an. Die sechs Klangwelten (`Gooby/Resources/Shell/Audio/sound-*.caf`, 48-Sekunden-Schleifen ohne Naht, IMA4) synthetisiert dasselbe Skript mit numpy/scipy, ohne Aufnahmen. `Tools/check_sounds.py` hört jede Datei mit earshot an (describe, match, realness, sfx check, Nahtprüfung), und der Build-Workflow dekodiert jede gebündelte Datei mit Core Audio. Soundeffekte folgen dem Schalter „Soundeffekte“ und, solange keine Klangwelt läuft, dem Stummschalter des iPhones. Eine gestartete Klangwelt spielt auch bei stummgeschaltetem iPhone und mischt sich mit anderer Musik.

Every sound ships in the app bundle; nothing streams. The sound effects (`Gooby/Resources/Sounds/sfx-*.wav`; `GoobySounds.swift` lists what plays each one) are takes from the sound bank of [earshot](https://github.com/Leonxlnx/earshot) (MIT, © 2026 Leon Lin): sounds stored as code and rendered by id. `Tools/make_sounds.py` layers them, tunes them to one key, and levels them. The same script synthesizes the six soundscapes (`Gooby/Resources/Shell/Audio/sound-*.caf`, seamless 48-second IMA4 loops) with numpy/scipy, without recordings. `Tools/check_sounds.py` listens to every file with earshot (describe, match, realness, sfx check, seam check), and the build workflow decodes every bundled file with Core Audio. Sound effects follow the Sound effects switch and, while no soundscape plays, the iPhone's Ring/Silent switch. A soundscape you start also plays with the iPhone on silent and mixes with other music.

Zwei der Bank-Klänge sind aus CC0-Aufnahmen (gemeinfrei) nachgebaut: `fit/pop/mouth_plop` nach „Mouth Plops.wav“ von CapsLok ([freesound 181907](https://freesound.org/people/CapsLok/sounds/181907/)) und `fit/tick/domino` nach „Domino pieces hit“ von Macif ([freesound 329098](https://freesound.org/people/Macif/sounds/329098/)).

Two of the bank sounds are fitted from CC0 (public-domain) recordings: `fit/pop/mouth_plop` after "Mouth Plops.wav" by CapsLok ([freesound 181907](https://freesound.org/people/CapsLok/sounds/181907/)) and `fit/tick/domino` after "Domino pieces hit" by Macif ([freesound 329098](https://freesound.org/people/Macif/sounds/329098/)).

## Sprache / Language

Deutsch ist die Voreinstellung. Englisch gilt sofort, ohne Neustart. Die Oberflächen lesen `l10n-*.json` zur Laufzeit. `Localizable.xcstrings` spiegelt dieselben Schlüssel. Inhalte (Geschichten, Orte, Gegenstände, Quests) liegen in `content-*.json` und werden zur Laufzeit zusammengeführt. Weitere Module können eigene Dateien mit diesen Präfixen dazulegen.

German is the default. English applies immediately, without a restart. The interface reads `l10n-*.json` at runtime. `Localizable.xcstrings` mirrors the same keys. Stories, places, items, and quests live in `content-*.json` and are merged at runtime. Other modules can add their own files with these prefixes.

## Entwicklermenü / Developer menu

In den Einstellungen die Zeile **English** dreimal innerhalb von zwei Sekunden antippen. Ein einzelner Tipp wählt nur die Sprache, auch wenn Englisch schon aktiv ist. In der App gibt es keinen Hinweis auf diese Geste. Das Menü kann die App-Zeit verschieben, ohne die Geräteuhr zu ändern, Belohnungen, Inventar, Abenteuer, Events und Quests prüfen und den Spielstand zurücksetzen. Ein vollständiger Reset braucht eine zweite Bestätigung.

In Settings, tap the **English** row three times within two seconds. A single tap only selects the language, including when English is already selected. The app shows no hint for this gesture. The menu can move app time without changing the device clock, inspect rewards, inventory, adventures, events, and quests, and erase the save. A full reset needs a second confirmation.

## Module

Ein Xcode-Projekt mit den synchronisierten Ordnern `Gooby/` (App), `GoobyWidgets/` (Widget-Erweiterung) und `GoobyShared/` (beide Ziele). Die Hülle besitzt die Modelle, die Engine und einen lauffähigen Bildschirm für jedes System. `FeatureHost` hält Ersetzungen. Ein optionales Modul kann sich beim Start anmelden, ohne dass die Hülle seine Typen kennt:

One Xcode project with the synchronized folders `Gooby/` (app), `GoobyWidgets/` (widget extension) and `GoobyShared/` (both targets). The shell owns the models, the engine, and a working screen for every system. `FeatureHost` holds replacements. An optional module can register at launch without the shell naming its types:

`AdventuresIntegration`, `ShopIntegration`, `RoomIntegration`, `WardrobeIntegration`, `HabitsIntegration`, `MoodIntegration`, `JournalIntegration`, `CalmIntegration`, `EventsIntegration`, `QuestsIntegration`, `CompanionsIntegration`.

Jede Klasse ist `@objc`, erbt von `NSObject` und bietet `@objc class func register()`. `register` darf nur Closures auf `FeatureHost.shared` setzen.

Each class is `@objc`, subclasses `NSObject`, and provides `@objc class func register()`. `register` may only assign closures on `FeatureHost.shared`.

Reservierte Typnamen der Hülle: `GoobyApp`, `GoobyEngine`, `FeatureHost`, `PlayerProfile`, `Wallet`, `GoobyPet`, `Habit`, `HabitLog`, `RewardLedger`, `AdventureRun`, `OwnedItem`, `SavedOutfit`, `RoomLayout`, `MoodEntry`, `JournalEntry`, `QuestRecord`, `EventRecord`, `MiniFriend`, `EggBinding`, `PlaceProgress`, `DiscoveryRecord`, `FocusSession`, `DailyStat`, `AppLogEntry`, `ContentCatalog`, `StringTable`, `Theme`, `GoobyCharacterView`, `WornLook`, `GoobyAnimation`, `HabitCalendar`, `ShopRotation`, `Growth`, `GoobyFiles`, `SoundscapePlayer`, `GoobyHaptics`, `GoobyAlerts`.

Die Kataloge lassen sich mit `python3 Tools/finish_catalog.py` neu schreiben. Die App selbst braucht dafür kein Netz.

The catalogs can be rewritten with `python3 Tools/finish_catalog.py`. The app itself does not need a network for that.

## Was die App bewusst nicht ist / What this app is not

Gooby stellt keine Diagnose, verspricht keine Therapie und nennt keine Beratungsstellen. Atmung, Fokus, Bewegung und Erdung sind kleine Alltagsübungen.

Gooby does not diagnose, does not promise therapy, and does not list helplines. Breathing, focus, movement, and grounding are small everyday exercises.

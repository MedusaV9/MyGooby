# Gooby

Gooby ist eine iOS-App (iOS 17 oder neuer). Ein runder, cremefarbener Hase begleitet kleine Gewohnheiten, Ruheübungen und selbstgeschriebene Abenteuer. Der Spielstand bleibt auf dem Gerät. Es gibt kein Konto und keine Analyse. Freunde können den Gooby-Stand verschlüsselt austauschen: in der Nähe über Bluetooth, und über einen Server, den du selbst betreibst.

Gooby is an iOS app (iOS 17 or newer). A round cream-colored bunny keeps company with small habits, calm exercises, and original adventures. The save stays on the device. There is no account and no analytics. Friends can exchange Gooby status, encrypted: nearby over Bluetooth, and through a server you host yourself.

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

`.github/workflows/build-ios.yml` startet bei einem Push auf `main`, bei Pull Requests auf `main` und über `workflow_dispatch`. Der macOS-Runner baut für `generic/platform=iOS` mit abgeschalteter Signierung und lädt das Artefakt **Gooby-unsigned-ipa** mit der Datei `Gooby-unsigned.ipa` hoch.

The workflow runs on a push to `main`, on pull requests to `main`, and via `workflow_dispatch`. The macOS runner builds for `generic/platform=iOS` with signing off and uploads the artifact **Gooby-unsigned-ipa**, which holds `Gooby-unsigned.ipa`.

**Eine unsignierte IPA lässt sich auf einem normalen iPhone nicht installieren**, bis sie mit einem gültigen Zertifikat und einem passenden Provisioning Profile neu signiert wurde. Die Datei ist ein Build-Artefakt, keine installationsfertige App.

**An unsigned IPA cannot be installed on a normal iPhone** until it is re-signed with a valid certificate and a matching provisioning profile. The file is a build artifact, not an app that is ready to install.

### Neu signieren / Re-signing

Die IPA enthält die Widget-Erweiterung `Payload/Gooby.app/PlugIns/GoobyWidgets.appex`. Beim Neu-Signieren müssen diese Erweiterung und die App-Gruppe `group.app.mygooby.gooby` erhalten bleiben, mit derselben Kennung in der App und in der Erweiterung. In der App liegt `Gooby.entitlements`, in der Erweiterung `GoobyWidgets.entitlements`. `NSSupportsLiveActivities` in der Info.plist der App muss bleiben, sonst gibt es keine Live-Aktivitäten und keine Dynamic Island. Fehlt die App-Gruppe danach, startet Gooby trotzdem. Widgets zeigen dann nur den Hinweis, die App einmal zu öffnen.

The IPA contains the widget extension `Payload/Gooby.app/PlugIns/GoobyWidgets.appex`. Re-signing has to keep that extension and the App Group `group.app.mygooby.gooby`, the same identifier on the app and the extension. `Gooby.entitlements` is in the app and `GoobyWidgets.entitlements` is in the extension. `NSSupportsLiveActivities` has to stay in the app Info.plist, or there are no Live Activities and no Dynamic Island. If the App Group is missing afterwards, Gooby still launches and widgets only show a hint to open the app once.

## Daten und iCloud / Data and iCloud

Spielstand, Profilbild und Datenbank liegen lokal im App-Ordner unter Application Support. Dieser Ordner und die Dateien darin sind mit `isExcludedFromBackup` vom iCloud-Backup und von einem iCloud-Geräte-Restore ausgenommen. Nach einer Wiederherstellung aus iCloud ist der Spielstand weg. Eine Kopie entsteht nur, wenn du in den Einstellungen exportierst. Die Exportdatei liegt nur dort, wo du sie selbst ablegst, zum Beispiel in der Dateien-App. Sie wandert nur dann in iCloud, wenn du sie in einen iCloud-Ordner schiebst.

The save, profile photo, and database live in the app’s Application Support folder. That folder and the files inside it are excluded from iCloud backup and from an iCloud device restore via `isExcludedFromBackup`. After an iCloud restore, the save is gone. A copy exists only if you export it in Settings. The export file lives only where you put it, for example in Files. It reaches iCloud only if you move it into an iCloud folder.

## Online

Beide Wege benutzen denselben Umschlag, `SyncEnvelope`: Gooby-Name, Spitzname, Freundescode, Wachstumsstufe, Fell, die Stimmung von heute, die Serie, der Fortschritt von heute, Pflegetage, die Art des Begleiters, und Geschenke (ein Herz oder fünf Sternenfunken, jeweils einmal am Tag). Tagebuch, Notizen, Profilfoto und der übrige Spielstand gehen nicht mit. Der Umschlag wird mit AES-GCM aus CryptoKit verschlossen. Den Schlüssel haben nur die beiden Freunde. Deshalb bleibt `ITSAppUsesNonExemptEncryption` auf falsch: es ist die übliche Systemverschlüsselung.

Both paths use the same envelope, `SyncEnvelope`: Gooby name, nickname, friend code, growth stage, fur, today's mood, the streak, today's progress, care days, the companion species, and gifts (one heart or five star sparks, each once a day). The journal, notes, profile photo, and the rest of the save stay behind. The envelope is sealed with AES-GCM from CryptoKit. Only the two friends hold the key. `ITSAppUsesNonExemptEncryption` stays false because this is ordinary system encryption.

**In der Nähe.** Zum ersten Treffen öffnen beide auf dem Freundesbaum das Blatt **In der Nähe koppeln**. Das nutzt MultipeerConnectivity (`gooby-pass`) und läuft nur, solange das Blatt offen ist. Jede Seite steuert die Hälfte des Schlüssels bei. Danach schaltest du **In der Nähe** ein. Beim Wiedersehen tauschen die iPhones den Umschlag über Bluetooth LE, ohne stabile Kennung: stündlich wechselnde Marken sagen nur „wir kennen uns“. Das ist kein StreetPass mit UWB. Nearby Interaction bräuchte eine besondere Capability und trägt den Umschlag nicht.

**Nearby.** For the first meeting, both open **Pair nearby** on the friends tree. That uses MultipeerConnectivity (`gooby-pass`) and works only while the sheet is open. Each side contributes half of the key. Then turn **Nearby** on. When you meet again, the iPhones exchange the envelope over Bluetooth LE, without a stable identifier: tags that change every hour only say “we know each other”. This is not StreetPass over UWB. Nearby Interaction would need a special capability and does not carry the envelope.

iOS hält Bluetooth im Hintergrund kurz wach, wenn die Modi `bluetooth-central` und `bluetooth-peripheral` gesetzt sind, verspricht aber nicht, wie oft. Am zuverlässigsten ist es, wenn Gooby bei einem von euch offen ist. Nach dem Wegwischen der App ruht Bluetooth, bis du Gooby wieder öffnest. Eine lokale Mitteilung gibt es höchstens einmal pro Stunde und nur, wenn Mitteilungen erlaubt sind. Push gibt es nicht.

iOS may keep Bluetooth awake briefly in the background when the `bluetooth-central` and `bluetooth-peripheral` modes are set, and it does not promise how often. It is most reliable when Gooby is open on one of the phones. After you swipe the app away, Bluetooth rests until you open Gooby again. A local notification happens at most once an hour, and only if notifications are allowed. There is no push.

**Server.** Für Tage ohne Treffen liegt ein Node-Server in `Server/`. Deployment, Dockerfile und die API stehen auf Deutsch in `Server/README.md`. In der App trägst du unter **Einstellungen → Online** die Adresse ein, zum Beispiel `https://sync.example.com`, und den Serverschlüssel. Dieselben Angaben auf beiden iPhones. Dort legst du auch ein Konto an: Name und Passwort. Dasselbe Konto auf einem zweiten Gerät holt denselben Spielstand und denselben `SyncEnvelope`. Der Serverschlüssel ist nur die Tür, jedes Konto bleibt für sich. Der Abgleich läuft beim Öffnen, alle zwei Minuten solange die App offen ist, einmal kurz beim Wechsel in den Hintergrund, und über einen Hintergrundabruf (`gooby.online.refresh`), wenn iOS ihn gewährt. Der Abruf ist frühestens nach 20 Minuten fällig und kann ausbleiben. Der Server sieht von den Freundschaften nur Chiffre. Eine Einladung gilt 72 Stunden und einmal. Den Code löst der Freund auf dem Freundesbaum ein. In der Nähe bleibt Bluetooth, ohne Konto.

**Server.** For days you do not meet, a Node server lives in `Server/`. Deployment, the Dockerfile, and the API are in German in `Server/README.md`. In the app, under **Settings → Online**, enter the address, for example `https://sync.example.com`, and the server key. Use the same values on both iPhones. You also create an account there: a name and a password. The same account on a second device fetches the same save and the same `SyncEnvelope`. The server key is only the door, and each account stays separate. Sync runs when the app opens, every two minutes while it stays open, once briefly when it goes to the background, and through a background refresh (`gooby.online.refresh`) when iOS grants one. The refresh is due after 20 minutes at the earliest and may never run. For friendships, the server sees only ciphertext. An invite lasts 72 hours and works once. The friend redeems the code on the friends tree. Nearby stays Bluetooth, without an account.

`http://` geht nur im lokalen Netz (`NSAllowsLocalNetworking`). Eine öffentliche Adresse braucht HTTPS.

`http://` works only on the local network (`NSAllowsLocalNetworking`). A public address needs HTTPS.

**Neu signieren.** Die unsignierte IPA braucht keine zusätzliche Capability und keine Entitlements. Nicht gesetzt und nicht nötig: Push (`aps-environment`), Associated Domains, Nearby Interaction, Multicast. Beim Signieren mit dem eigenen Zertifikat muss die `Info.plist` im App-Bündel diese Schlüssel behalten:

**Re-signing.** The unsigned IPA needs no extra capability and no entitlements. Not set, and not needed: push (`aps-environment`), Associated Domains, Nearby Interaction, multicast. When you sign with your own certificate, the `Info.plist` inside the app bundle has to keep these keys:

- `UIBackgroundModes`: `bluetooth-central`, `bluetooth-peripheral`, `fetch`
- `BGTaskSchedulerPermittedIdentifiers`: `gooby.online.refresh`
- `NSBonjourServices`: `_gooby-pass._tcp`, `_gooby-pass._udp`
- `NSBluetoothAlwaysUsageDescription`
- `NSLocalNetworkUsageDescription`
- `NSAppTransportSecurity` / `NSAllowsLocalNetworking`

Ein normales Provisioning Profile genügt. Die Hintergrundmodi stehen in der `Info.plist`, nicht im Profile.

An ordinary provisioning profile is enough. The background modes live in `Info.plist`, not in the profile.

## Sprache / Language

Deutsch ist die Voreinstellung. Englisch gilt sofort, ohne Neustart. Die Oberflächen lesen `l10n-*.json` zur Laufzeit. `Localizable.xcstrings` spiegelt dieselben Schlüssel. Inhalte (Geschichten, Orte, Gegenstände, Quests) liegen in `content-*.json` und werden zur Laufzeit zusammengeführt. Weitere Module können eigene Dateien mit diesen Präfixen dazulegen.

German is the default. English applies immediately, without a restart. The interface reads `l10n-*.json` at runtime. `Localizable.xcstrings` mirrors the same keys. Stories, places, items, and quests live in `content-*.json` and are merged at runtime. Other modules can add their own files with these prefixes.

## Entwicklermenü / Developer menu

In den Einstellungen die Zeile **English** dreimal innerhalb von zwei Sekunden antippen. Ein einzelner Tipp wählt nur die Sprache, auch wenn Englisch schon aktiv ist. In der App gibt es keinen Hinweis auf diese Geste. Das Menü kann die App-Zeit verschieben, ohne die Geräteuhr zu ändern, Belohnungen, Inventar, Abenteuer, Events und Quests prüfen und den Spielstand zurücksetzen. Ein vollständiger Reset braucht eine zweite Bestätigung.

In Settings, tap the **English** row three times within two seconds. A single tap only selects the language, including when English is already selected. The app shows no hint for this gesture. The menu can move app time without changing the device clock, inspect rewards, inventory, adventures, events, and quests, and erase the save. A full reset needs a second confirmation.

## Tabs

Die Hülle zeichnet die Tab-Leiste einmal (`HomeTabBar`): Home, Fest, Shop, Freunde, Tasche und Gooby (Profil). Das Fest zeigt die laufende Saison und einen eigenen Kahn; die Aufgaben öffnen sich von dort. Feature-Bildschirme zeichnen keine eigene Leiste. Das Menü öffnet sich über die drei Striche auf Home oder auf dem Profil; die Einstellungen liegen hinter der Namenszeile im Menü und hinter dem Zahnrad in der Tasche.

The shell draws the tab bar once (`HomeTabBar`): Home, Event, Shop, Friends, Bag, and Gooby (profile). Event shows the current season and an original boat; quests open from there. Feature screens do not draw their own bar. The menu opens from the three lines on Home or on the profile; Settings sit behind the name row in the menu and behind the gear in the bag.

Swift-Dateinamen müssen im ganzen Ordner `Gooby/` eindeutig sein, auch in verschiedenen Unterordnern. Swift file names must be unique across the whole `Gooby/` folder, even in different subfolders.

## Module

Ein Xcode-Projekt, synchronisierter Ordner `Gooby/`. Die Hülle besitzt die Modelle, die Engine und einen lauffähigen Bildschirm für jedes System. `FeatureHost` hält Ersetzungen. Ein optionales Modul kann sich beim Start anmelden, ohne dass die Hülle seine Typen kennt:

One Xcode project, synchronized `Gooby/` folder. The shell owns the models, the engine, and a working screen for every system. `FeatureHost` holds replacements. An optional module can register at launch without the shell naming its types:

`AdventuresIntegration`, `ShopIntegration`, `RoomIntegration`, `WardrobeIntegration`, `HabitsIntegration`, `MoodIntegration`, `JournalIntegration`, `CalmIntegration`, `EventsIntegration`, `QuestsIntegration`, `CompanionsIntegration`, `SystemIntegration`.

Jede Klasse ist `@objc`, erbt von `NSObject` und bietet `@objc class func register()`. `register` darf nur Closures auf `FeatureHost.shared` setzen.

Each class is `@objc`, subclasses `NSObject`, and provides `@objc class func register()`. `register` may only assign closures on `FeatureHost.shared`.

Reservierte Typnamen der Hülle: `GoobyApp`, `GoobyEngine`, `FeatureHost`, `PlayerProfile`, `Wallet`, `GoobyPet`, `Habit`, `HabitLog`, `RewardLedger`, `AdventureRun`, `OwnedItem`, `SavedOutfit`, `RoomLayout`, `MoodEntry`, `JournalEntry`, `QuestRecord`, `EventRecord`, `MiniFriend`, `EggBinding`, `PlaceProgress`, `DiscoveryRecord`, `FocusSession`, `DailyStat`, `AppLogEntry`, `ContentCatalog`, `StringTable`, `Theme`, `GoobyCharacterView`, `WornLook`, `GoobyAnimation`, `HabitCalendar`, `ShopRotation`, `Growth`, `GoobyFiles`, `SoundscapePlayer`, `GoobyHaptics`, `GoobyAlerts`, `GoobyFeedback`, `GoobyCue`, `GoobySoundEffects`.

Die Kataloge lassen sich mit `python3 Tools/finish_catalog.py` neu schreiben. Dieses Skript braucht kein Netz.

The catalogs can be rewritten with `python3 Tools/finish_catalog.py`. That script does not need a network.

## Töne und Haptik / Sounds and haptics

`GoobyFeedback` ist die einzige Stelle für Klänge und Vibration. Ein Bildschirm oder Modul fragt nur nach einem Moment: `GoobyFeedback.play(.goalDone)`, `engine.cue(.coins)` oder `.goobyCue(.sheet, opening: showSheet)`. Welche Datei und welches Haptikmuster dazu gehören, steht in `GoobyCue`. Die Engine spielt die großen Momente selbst (Ziel erledigt, Tagesziel, Wachstumsstufe, Kauf, Quest, Ei, Abenteuer), deshalb brauchen neue Bildschirme dafür keinen eigenen Aufruf. Tab-Leiste, `LookSwitch` und `GoobyButtonStyle` klingen von selbst.

`GoobyFeedback` is the only place for sounds and haptics. A screen or module asks for a moment: `GoobyFeedback.play(.goalDone)`, `engine.cue(.coins)`, or `.goobyCue(.sheet, opening: showSheet)`. `GoobyCue` maps each moment to its file and haptic. The engine plays the big moments itself (goal done, all goals done, growth stage, purchase, quest, egg, adventure), so new screens need no call for them. The tab bar, `LookSwitch`, and `GoobyButtonStyle` sound on their own.

- Einstellungen → Vorlieben: **Töne** und **Vibration**, gespeichert in `UserDefaults` (`gooby.feedback.sounds`, `gooby.feedback.haptics`), nicht im Spielstand.
- Settings → Preferences: **Sounds** and **Haptics**, stored in `UserDefaults`, not in the save.
- Die Effekte laufen in der Audio-Session `.ambient`: Der Lautlos-Schalter macht sie stumm, Musik anderer Apps läuft weiter. `UIFeedbackGenerator` folgt zusätzlich „System-Haptik“; die Core-Haptics-Muster (Feiern, Ei, Stufe, Atmung) folgen nur dem Schalter in Gooby.
- Effects use the `.ambient` audio session: the Ring/Silent switch mutes them and other apps' music keeps playing. `UIFeedbackGenerator` also follows System Haptics; the Core Haptics patterns (celebrations, egg, growth, breathing) follow only Gooby's own switch.
- Das Entwicklermenü hat einen Abschnitt zum Probehören aller Cues. The developer menu lists every cue to audition.

Die Dateien `Gooby/Resources/Feedback/Audio/sfx-*.wav` entstehen mit [earshot](https://github.com/Leonxlnx/earshot) (MIT) aus dessen Code-Soundbank, ohne Aufnahmen Dritter: `Tools/make_feedback_sounds.py` beschreibt die Installation und schreibt alle Dateien neu.

The `sfx-*.wav` files are rendered with [earshot](https://github.com/Leonxlnx/earshot) (MIT) from its code-only sound bank, with no third-party recordings: `Tools/make_feedback_sounds.py` explains the setup and rewrites every file.

## Was die App bewusst nicht ist / What this app is not

Gooby stellt keine Diagnose, verspricht keine Therapie und nennt keine Beratungsstellen. Atmung, Fokus, Bewegung und Erdung sind kleine Alltagsübungen.

Gooby does not diagnose, does not promise therapy, and does not list helplines. Breathing, focus, movement, and grounding are small everyday exercises.

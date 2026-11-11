# Gooby-Server

Kleiner Relay für Gooby. Freundschaftsumschläge und Einladungen liegen nur als Chiffre. Den Schlüssel zu einem Umschlag haben nur die beiden Freunde. Dieselbe Person kann sich auf mehreren iPhones oder iPads anmelden und bekommt denselben Spielstand.

Der Serverschlüssel ist das gemeinsame Türschloss für alle, die diesen Server benutzen dürfen. Er trennt die Personen nicht. Dafür gibt es Konten: Name oder E-Mail plus Passwort. Jedes Konto hat einen eigenen verschlossenen Spielstand. Das Passwort liegt als scrypt-Hash auf der Platte, nie im Klartext. Der Spielstand ist ein undurchsichtiger Block. Darin stecken der Export der App, die Freundesliste mit den Paarschlüsseln und ein `SyncEnvelope`. Wer das Passwort nicht hat, liest das nicht. Bluetooth in der Nähe bleibt ohne Konto, wie bisher.

## Lokal starten

Node.js 20 oder neuer.

```bash
cd Server
export GOOBY_SERVER_KEY="$(openssl rand -hex 24)"
export GOOBY_PORT=8080
export GOOBY_DATA="$PWD/data/store.json"
node src/server.js
```

Prüfung:

```bash
curl -s http://127.0.0.1:8080/v1/info
```

Die Antwort ist `{"service":"gooby-sync","version":1,"keyRequired":true}`.

In der App unter **Einstellungen → Online** die Adresse `http://192.168.x.x:8080` eintragen, wenn das iPhone im selben Netz ist. iOS erlaubt `http` nur im lokalen Netz. Für alles andere brauchst du `https`.

Tests, ebenfalls mit echten HTTP-Anfragen:

```bash
cd Server
npm test
```

## Docker

```bash
docker build -t gooby-sync Server
docker run --rm -p 8080:8080 \
  -e GOOBY_SERVER_KEY="$(openssl rand -hex 24)" \
  -v gooby-data:/data \
  gooby-sync
```

Der Prozess hört auf `PORT`, sonst auf `GOOBY_PORT`, sonst auf `8080`. Die Daten liegen in `GOOBY_DATA` (im Image `/data/store.json`). Das Volume gehört dem Benutzer `node` (uid 1000). Wenn ein gemounteter Ordner nicht beschreibbar ist: `sudo chown -R 1000:1000` auf diesen Ordner.

## Umgebungsvariablen

| Name | Bedeutung |
| --- | --- |
| `GOOBY_SERVER_KEY` | Türschloss. Leer lassen heißt: jeder, der die Adresse kennt, darf schreiben. In Betrieb setzen. |
| `PORT` | Port. App Runner setzt ihn selbst. Hat Vorrang vor `GOOBY_PORT`. |
| `GOOBY_PORT` | Port, wenn `PORT` fehlt. |
| `GOOBY_DATA` | Pfad der JSON-Datei. |
| `GOOBY_INVITE_TTL_MS` | Lebensdauer einer Einladung. Voreinstellung 72 Stunden. |
| `GOOBY_SLOT_TTL_MS` | Lebensdauer eines Umschlags. Voreinstellung 14 Tage. |
| `GOOBY_MAX_BLOB` | Größter Umschlag in Bytes. Voreinstellung 24576. |

Den Schlüssel nie ins Repository schreiben. `Server/.env.example` zeigt nur die Namen.

## HTTPS auf der eigenen Domain

Die App spricht den Server direkt an. Davor sitzt HTTPS.

Beispiel mit Caddy auf demselben Rechner:

```caddy
sync.example.com {
  reverse_proxy 127.0.0.1:8080
}
```

In der App dann `https://sync.example.com`, ohne Pfad und ohne Port, plus derselbe `GOOBY_SERVER_KEY` auf beiden iPhones.

## AWS App Runner

Eine Instanz reicht. Mehrere Instanzen sehen dieselbe Datei nicht, und der Abgleich geht daneben. Minimum 1, Maximum 1.

1. App Runner, Quelle dieses Repository.
2. Entweder das Dockerfile `Server/Dockerfile` und Port `8080`, oder die Laufzeit Node mit Arbeitsverzeichnis `Server`, Startbefehl `npm start`.
3. Umgebungsvariable `GOOBY_SERVER_KEY` setzen. `PORT` setzt App Runner. Optional `GOOBY_DATA=/tmp/gooby-store.json`.
4. Health Check: HTTP, Pfad `/v1/info`, Erfolg bei Status 200.
5. Eigene Domain in App Runner verknüpfen und die angezeigten DNS-Einträge setzen. Warten, bis das Zertifikat aktiv ist.
6. In Gooby die Adresse `https://deine-domain` und den Schlüssel speichern.

Die Platte von App Runner ist flüchtig. Ein neues Deployment leert die Datei. Konten, Sitzungen und der verschlossene Spielstand sind dann weg. Auf den iPhones bleibt der Spielstand liegen. Danach das Konto neu anlegen und sich anmelden: der nächste Abgleich lädt ihn wieder hoch. Freundschaftsschlüssel liegen ebenfalls auf den Geräten, der nächste Abgleich schreibt die Umschläge neu. Offene Einladungen überleben das nicht. Wer die Datei behalten will, betreibt den Container mit einem Volume, zum Beispiel auf einem kleinen Rechner oder einer einzelnen virtuellen Maschine.

## Was der Server annimmt

Alle Nutzdatenpfade verlangen den Header `X-Gooby-Key`, sobald `GOOBY_SERVER_KEY` gesetzt ist. `GET /v1/info` bleibt ohne Schlüssel lesbar, damit die App und der Health Check die Adresse prüfen können.

- `GET /v1/info`
- `GET /v1/channels/:channel` mit `Authorization: Bearer <token>`
- `PUT /v1/channels/:channel/:slot` mit JSON `{ "blob": "<base64>" }`
- `POST /v1/invites` mit JSON `{ "id": "<64 hex>", "blob": "<base64>" }`
- `POST /v1/invites/:id/claim`
- `POST /v1/accounts` mit JSON `{ "name", "password", "memberId" }`. Antwort 201: `accountId`, `memberId`, `token`
- `POST /v1/sessions` mit JSON `{ "name", "password" }`. Antwort 200, dieselbe Form. Ein Gerät, eine Sitzung
- `DELETE /v1/sessions` mit `Authorization: Bearer <token>` meldet nur diese Sitzung ab
- `GET /v1/account` mit dem Sitzungstoken. Antwort `{ "revision" }` oder `{ "revision", "blob" }`
- `PUT /v1/account` mit JSON `{ "revision", "blob" }`. Die Revision muss genau die nächste Zahl sein. Sonst 409 mit der aktuellen Revision und dem aktuellen Block

`:channel` und die Einladungs-`id` sind 64 Hex-Zeichen, `:slot` sind 32. Der Kanal-Token und der Sitzungstoken sind 64 Hex-Zeichen. Beim ersten Schreiben eines Kanals merkt sich der Server den SHA-256 des Kanal-Tokens und verlangt ihn danach wieder. Den Sitzungstoken vergleicht er ebenfalls nur über seinen SHA-256. Wer den Kanal nicht kennt, kann ihn nicht erraten. Ein anderes Konto sieht den Spielstand nicht.

Ein Umschlag, der älter als 14 Tage ist, fällt weg. Eine Einladung gilt 72 Stunden und genau einmal. Pro Kanal bleiben höchstens vier Slots, insgesamt höchstens 5000 Kanäle und 2000 offene Einladungen. Mehr als 180 Anfragen pro Minute von einer Adresse antworten mit Status 429.

Die Datei enthält die Kontonamen, die Passwort-Hashes und Base64. Wer die Platte kopiert, kann die Umschläge und den Spielstand ohne die Schlüssel auf den iPhones nicht lesen. Ein Konto-Block darf 8 MB Chiffre groß sein. Es gibt höchstens 500 Konten und 8 Sitzungen pro Konto. Die älteste Sitzung fällt weg, wenn eine neunte dazukommt.

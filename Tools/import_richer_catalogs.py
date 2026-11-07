#!/usr/bin/env python3
"""Copy richer catalogs from the other slices into the shell content format."""

import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Gooby" / "Resources" / "Shell" / "content-imported.json"
SHELL = json.loads((ROOT / "Gooby" / "Resources" / "Shell" / "content-shell.json").read_text())
KNOWN_ITEMS = {row["id"] for row in SHELL["items"]}
KNOWN_STORIES = {row["id"] for row in SHELL["stories"]}
KNOWN_EVENTS = {row["id"] for row in SHELL["events"]}
KNOWN_PROMPTS = {row["id"] for row in SHELL["prompts"]}

PLACE = {
    "flower-meadow": "meadow",
    "fairy-garden": "garden",
    "cherry-park": "cherry",
    "sunny-beach": "beach",
    "crystal-lake": "crystal",
    "cloud-land": "clouds",
    "sugar-island": "sugar",
    "star-forest": "starwood",
    "moon-valley": "moon",
    "snow-village": "snow",
}
TRAITS = {"curiosity", "courage", "kindness", "playfulness", "confidence", "calm", "empathy"}
ANCHOR = {
    "pillow": "cushion",
    "wall": "wall",
    "floor": "floor",
    "bed": "bed",
    "rug": "rug",
    "lamp": "lamp",
    "window": "window",
    "plant": "plant",
    "shelf": "shelf",
    "picture": "picture",
    "sofa": "sofa",
    "table": "table",
    "hat": "hat",
    "bow": "bow",
    "glasses": "glasses",
    "shirt": "shirt",
    "sweater": "sweater",
    "jacket": "jacket",
    "dress": "dress",
    "pants": "pants",
    "shoes": "shoes",
    "backpack": "backpack",
    "scarf": "scarf",
    "accessory": "accessory",
    "pin": "accessory",
}
RARITY = {"common": "common", "uncommon": "uncommon", "rare": "rare", "epic": "special", "legendary": "special"}
METRIC = {
    "reflections": "journal",
    "habitDays": "habits",
    "visits": "adventure",
    "companionPlays": "pet",
    "habitCount": "habits",
    "calmSessions": "breath",
}


def git_show(rev, path):
    return subprocess.check_output(["git", "show", f"{rev}:{path}"], cwd=ROOT, text=True)


def loc(de, en):
    return {"de": de, "en": en}


def stories_and_discoveries():
    raw = json.loads(git_show("origin/gooby-adventures", "Gooby/Resources/Adventures/adventure-catalog.json"))
    discs = {place["id"]: {row["id"]: row for row in place["discoveries"]} for place in raw["places"]}
    stories = []
    extra = {pid: [] for pid in PLACE.values()}
    for story in raw["stories"]:
        if story["id"] in KNOWN_STORIES:
            continue
        place = PLACE[story["placeID"]]
        choices = []
        for choice in story["choices"]:
            found = choice.get("discoveryID") or ""
            if found:
                source = discs.get(story["placeID"], {}).get(found)
                if source:
                    packed = f"{place}-{found}"
                    extra[place].append({
                        "id": packed,
                        "name": source["name"],
                        "detail": source["detail"],
                    })
                    found = packed
            deltas = {}
            for key, value in (choice.get("traits") or {}).items():
                if key in TRAITS and value:
                    deltas[key] = round(0.04 * abs(int(value)), 3)
            choices.append({
                "id": choice["id"],
                "text": clean(choice["text"]),
                "outcome": clean(choice["outcome"]),
                "deltas": deltas,
                "sparks": int(story.get("sparkReward") or 8),
                "discoveryID": found,
            })
        stories.append({
            "id": story["id"],
            "placeID": place,
            "title": clean(story["title"]),
            "body": clean(story["body"]),
            "choices": choices,
        })
    places = []
    for pid, rows in extra.items():
        if not rows:
            continue
        seen = set()
        unique = []
        for row in rows:
            if row["id"] in seen:
                continue
            seen.add(row["id"])
            unique.append(row)
        base = next(place for place in SHELL["places"] if place["id"] == pid)
        places.append({**base, "discoveries": unique})
    return stories, places


def clean(text):
    return {key: value.replace("{{name}}", "Gooby").replace("{{bunny}}", "Gooby") for key, value in text.items()}


def parse_items(swift):
    pattern = re.compile(
        r'make\(\s*"([^"]+)"\s*,\s*\.(\w+)\s*,\s*\.(\w+)\s*,\s*\.(\w+)\s*,\s*\.(\w+)\s*,\s*(\d+)\s*,\s*"(.*?)"\s*,\s*"(.*?)"\s*,\s*"(.*?)"\s*,\s*"(.*?)"\s*,\s*(0x[0-9A-Fa-f]+)\s*,\s*(0x[0-9A-Fa-f]+)',
        re.S,
    )
    rows = []
    for match in pattern.finditer(swift):
        iid, dept, anchor, _draw, rarity, price, de, en, bde, ben, color, color2 = match.groups()
        slot = ANCHOR.get(anchor)
        if not slot or iid in KNOWN_ITEMS:
            continue
        shop = "wardrobe" if dept == "wardrobe" else "furniture"
        rows.append({
            "id": iid,
            "kind": "clothing" if shop == "wardrobe" else "furniture",
            "slot": slot,
            "style": sum(ord(ch) for ch in iid) % 4,
            "price": int(price),
            "rarity": RARITY.get(rarity, "common"),
            "color": color[2:].upper(),
            "color2": color2[2:].upper(),
            "name": loc(de, en),
            "blurb": loc(bde, ben),
            "shop": shop,
            "starter": False,
            "seasonalEvent": "",
        })
    return rows


def events():
    raw = json.loads(git_show("origin/gooby-events", "Gooby/Resources/Events/seasonal-events.json"))
    rows = []
    items = []
    for event in raw:
        if event["id"] in KNOWN_EVENTS:
            continue
        tasks = []
        for index, objective in enumerate(event["objectives"]):
            tasks.append({
                "id": f"{event['id']}-{objective['id']}",
                "metric": METRIC.get(objective["kind"], "habits"),
                "goal": int(objective["target"]),
                "rewardSparks": int(event["rewardSparks"]) if index == 0 else 15,
                "rewardItemID": f"fest-{event['id']}" if index == 0 else "",
                "title": loc(objective["titleDE"], objective["titleEN"]),
            })
        rows.append({
            "id": event["id"],
            "startMonth": event["startMonth"],
            "startDay": event["startDay"],
            "endMonth": event["endMonth"],
            "endDay": event["endDay"],
            "title": loc(event["nameDE"], event["nameEN"]),
            "blurb": loc(event["summaryDE"], event["summaryEN"]),
            "tasks": tasks,
        })
        items.append({
            "id": f"fest-{event['id']}",
            "kind": "furniture",
            "slot": "seasonal",
            "style": 1,
            "price": 80,
            "rarity": "special",
            "color": event["accentHex"].replace("#", ""),
            "color2": "FFF8EF",
            "name": loc(event["nameDE"], event["nameEN"]),
            "blurb": loc(event["summaryDE"], event["summaryEN"]),
            "shop": "seasonal",
            "starter": False,
            "seasonalEvent": event["id"],
        })
    return rows, items


def prompts():
    rows = [
        ("care-gratitude-1", "gratitude", "Was war heute klein und gut?", "What was small and good today?"),
        ("care-gratitude-2", "gratitude", "Wer oder was hat mir geholfen?", "Who or what helped me?"),
        ("care-gratitude-3", "gratitude", "Was möchte ich davon behalten?", "What do I want to keep from it?"),
        ("care-worth-1", "worth", "Was habe ich getan, das gezählt hat, auch wenn es klein war?", "What did I do that mattered, even a little?"),
        ("care-worth-2", "worth", "Was würde ich einer befreundeten Person an meiner Stelle sagen?", "What would I say to a friend in my place?"),
        ("care-worth-3", "worth", "Welche Stärke war heute da?", "Which strength showed up today?"),
        ("care-stress-1", "stress", "Was liegt gerade auf mir?", "What is weighing on me?"),
        ("care-stress-2", "stress", "Was liegt heute in meiner Hand?", "What is in my hands today?"),
        ("care-stress-3", "stress", "Was ist ein kleiner nächster Schritt?", "What is one small next step?"),
        ("care-day-1", "day", "Was ist heute passiert?", "What happened today?"),
        ("care-day-2", "day", "Was war in Ordnung?", "What felt okay?"),
        ("care-day-3", "day", "Was kann bis morgen warten?", "What can wait until tomorrow?"),
        ("care-mind-1", "mind", "Was merke ich gerade im Körper?", "What do I notice in my body right now?"),
        ("care-mind-2", "mind", "Was sehe, höre oder fühle ich in diesem Raum?", "What can I see, hear, or feel in this room?"),
        ("care-mind-3", "mind", "Wie ist dieser Moment, ohne ihn reparieren zu müssen?", "How is this moment, without fixing it?"),
        ("care-motive-1", "motive", "Was ist mir diese Woche wichtig?", "What matters to me this week?"),
        ("care-motive-2", "motive", "Welchen winzigen Schritt kann ich tun?", "What tiny step can I take?"),
        ("care-motive-3", "motive", "Was würde morgen ein bisschen leichter machen?", "What would make tomorrow a little easier?"),
        ("care-feel-1", "feel", "Welches Gefühl ist gerade da?", "Which feeling is here?"),
        ("care-feel-2", "feel", "Woran merke ich es?", "Where do I notice it?"),
        ("care-feel-3", "feel", "Was braucht es von mir, ohne Bewertung?", "What does it need from me, without a verdict?"),
    ]
    return [
        {"id": pid, "theme": theme, "title": loc(de, en), "body": loc(de, en)}
        for pid, theme, de, en in rows
        if pid not in KNOWN_PROMPTS
    ]


def main():
    stories, places = stories_and_discoveries()
    clothing = parse_items(git_show("origin/gooby-shop-room", "Gooby/Resources/Shop/ShopClothingCatalog.swift"))
    furniture = parse_items(git_show("origin/gooby-shop-room", "Gooby/Resources/Shop/ShopFurnishingCatalog.swift"))
    festivals, fest_items = events()
    payload = {
        "places": places,
        "stories": stories,
        "items": clothing + furniture + fest_items,
        "friends": [],
        "quests": [],
        "events": festivals,
        "prompts": prompts(),
        "exercises": [],
    }
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(
        "stories", len(stories),
        "places", len(places),
        "items", len(payload["items"]),
        "events", len(festivals),
        "prompts", len(payload["prompts"]),
    )


if __name__ == "__main__":
    main()

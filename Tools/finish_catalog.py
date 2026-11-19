#!/usr/bin/env python3
import json
import math
import random
import struct
import sys
import wave
import zlib
from pathlib import Path

import build_content
from build_content import ICON, S, loc

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "Gooby" / "Resources" / "Shell"
AUDIO = RES / "Audio"


def disc(place, n, de, en, dde, een):
    return {"id": f"{place}-d{n}", "name": loc(de, en), "detail": loc(dde, een)}


PLACES = [
    ("meadow", "Blumenwiese", "Flower Meadow", "Weiches Gras, Glockenblumen und ein Pfad aus Tau.", "Soft grass, bellflowers, and a path of dew.", 25, 0, 0, "C6EFDC", "FFE7AD", "7DCAA8", [
        disc("meadow", 1, "Tauglocke", "Dew bell", "Eine kleine Glocke, die nur morgens klingt.", "A tiny bell that rings only in the morning."),
        disc("meadow", 2, "Bienenschal", "Bee scarf", "Ein Schal aus warmem Sommerwind.", "A scarf made of warm summer wind."),
        disc("meadow", 3, "Picknickdecke", "Picnic cloth", "Rotkariert und immer ein bisschen zu groß.", "Red checks, always a little too big."),
    ]),
    ("garden", "Märchengarten", "Story Garden", "Hecken mit Türen, die nur einen Spalt offen sind.", "Hedges with doors that stay a little ajar.", 30, 1, 80, "D3C2FF", "C6EFDC", "B79BE8", [
        disc("garden", 1, "Moosschlüssel", "Moss key", "Er passt zu keiner Tür und trotzdem zu allen.", "It fits no door and somehow every door."),
        disc("garden", 2, "Teetasse", "Tea cup", "Darin schwimmt ein Blatt wie ein Boot.", "A leaf floats in it like a boat."),
        disc("garden", 3, "Glühwürmchenkarte", "Firefly map", "Punkte, die nachts den Weg zeigen.", "Dots that show the way at night."),
    ]),
    ("cherry", "Kirschblütenpark", "Cherry Park", "Rosa Luft und Bänke unter alten Bäumen.", "Pink air and benches under old trees.", 30, 3, 110, "FFD6E7", "FFF8EF", "F3A6C4", [
        disc("cherry", 1, "Blütenband", "Petal ribbon", "Es bindet sich von selbst zu einer Schleife.", "It ties itself into a bow."),
        disc("cherry", 2, "Schaukelkarte", "Swing note", "Jemand hat einen freundlichen Satz hinterlassen.", "Someone left a kind sentence."),
        disc("cherry", 3, "Papiersonnenschirm", "Paper parasol", "Leicht genug für einen runden Hasen.", "Light enough for a round bunny."),
    ]),
    ("crystal", "Kristallsee", "Crystal Lake", "Klares Wasser, in dem der Himmel langsamer wird.", "Clear water where the sky slows down.", 35, 5, 140, "C8E9FF", "D3C2FF", "8EC7E6", [
        disc("crystal", 1, "Spiegelkiesel", "Mirror pebble", "Zeigt ein Lächeln, auch an grauen Tagen.", "Shows a smile even on grey days."),
        disc("crystal", 2, "Glassteg", "Glass step", "Ein Tritt, der über das Wasser führt.", "A step that leads across the water."),
        disc("crystal", 3, "Echomuschel", "Echo shell", "Sie wiederholt nur die freundlichen Worte.", "It repeats only the kind words."),
    ]),
    ("beach", "Sonnenstrand", "Sun Beach", "Warmer Sand und ein Wind, der nach Salz duftet.", "Warm sand and a wind that smells of salt.", 30, 8, 160, "FFE7AD", "FFD6B3", "F0C36A", [
        disc("beach", 1, "Sonnenmuschel", "Sun shell", "Innen leuchtet sie wie ein kleiner Nachmittag.", "Inside it glows like a small afternoon."),
        disc("beach", 2, "Drachenband", "Kite string", "Hält einen Papierdrachen, der nie reißt.", "Holds a paper kite that never tears."),
        disc("beach", 3, "Flaschenpost", "Bottle note", "Die Nachricht sagt nur: du bist rechtzeitig.", "The note only says: you are right on time."),
    ]),
    ("sugar", "Zuckerinsel", "Sugar Isle", "Bonbonbrücken und ein Bach aus Limonade.", "Candy bridges and a brook of lemonade.", 40, 11, 190, "FFD6E7", "FFE7AD", "F2A0C0", [
        disc("sugar", 1, "Zuckersteg", "Sugar step", "Knirscht leise und trägt trotzdem.", "It crunches softly and still holds."),
        disc("sugar", 2, "Streuselschauer", "Sprinkle shower", "Bunter Regen, der nicht klebt.", "Colorful rain that does not stick."),
        disc("sugar", 3, "Karussellticket", "Carousel ticket", "Eine Runde reicht für ein Lächeln.", "One turn is enough for a smile."),
    ]),
    ("clouds", "Wolkenland", "Cloud Country", "Treppen aus Dunst und Briefkästen im Wind.", "Stairs of mist and mailboxes in the wind.", 35, 14, 210, "C8E9FF", "FFF8EF", "A9D4F2", [
        disc("clouds", 1, "Regenbogenfaden", "Rainbow thread", "Zum Nähen von kleinen Mut-Flicken.", "For sewing small patches of courage."),
        disc("clouds", 2, "Wolkenkissen", "Cloud cushion", "Es merkt sich die Form von Umarmungen.", "It remembers the shape of hugs."),
        disc("clouds", 3, "Windpost", "Wind mail", "Briefe, die ankommen, wenn man bereit ist.", "Letters that arrive when you are ready."),
    ]),
    ("starwood", "Sternenwald", "Star Forest", "Dunkles Lavendel und Laternen zwischen Moos.", "Dark lavender and lanterns between moss.", 45, 18, 240, "D3C2FF", "3D3656", "C7B4F5", [
        disc("starwood", 1, "Laternenkern", "Lantern seed", "Ein Funke, der den Pfad warm hält.", "A spark that keeps the path warm."),
        disc("starwood", 2, "Sternkeks", "Star biscuit", "Schmeckt nach Abend und nach Zuhause.", "Tastes like evening and like home."),
        disc("starwood", 3, "Mooskompass", "Moss compass", "Zeigt nicht nach Norden, sondern nach Ruhe.", "It points not north, but toward rest."),
    ]),
    ("moon", "Mondtal", "Moon Valley", "Silberne Stufen und ein Picknick bei Nacht.", "Silver steps and a picnic at night.", 40, 22, 260, "C8E9FF", "D3C2FF", "B7C6F0", [
        disc("moon", 1, "Schlafliedstein", "Lullaby stone", "Warm in der Pfote, leise im Ohr.", "Warm in the paw, quiet in the ear."),
        disc("moon", 2, "Kratergarten", "Crater garden", "Kleine Kräuter, die im Mondlicht wachsen.", "Tiny herbs that grow in moonlight."),
        disc("moon", 3, "Nachtpicknick", "Night picnic", "Eine Decke, die Sterne nicht verdeckt.", "A blanket that does not hide the stars."),
    ]),
    ("snow", "Schneedorf", "Snow Village", "Laternenfenster und Kakao, der nicht ausgeht.", "Lantern windows and cocoa that does not run out.", 35, 26, 280, "FFF8EF", "C8E9FF", "E7F4FF", [
        disc("snow", 1, "Fäustlinge", "Mittens", "Zwei linke, und trotzdem ein Paar.", "Two left ones, and still a pair."),
        disc("snow", 2, "Schlittenband", "Sled ribbon", "Für eine langsame, sichere Fahrt.", "For a slow, safe ride."),
        disc("snow", 3, "Fensterlicht", "Window light", "Jemand lässt es für Heimkehrer an.", "Someone leaves it on for travelers coming home."),
    ]),
]


def place_obj(row):
    pid, de, en, bde, ben, minutes, unlock, price, top, bottom, accent, discoveries = row
    return {
        "id": pid,
        "name": loc(de, en),
        "blurb": loc(bde, ben),
        "durationMinutes": minutes,
        "unlockAfterAdventures": unlock,
        "ticketPrice": price,
        "skyTop": top,
        "skyBottom": bottom,
        "accent": accent,
        "discoveries": discoveries,
    }


def choice(cid, tde, ten, ode, oen, stat, sparks, discovery):
    return {
        "id": cid,
        "text": loc(tde, ten),
        "outcome": loc(ode, oen),
        "deltas": {stat: 0.03},
        "sparks": sparks,
        "discoveryID": discovery,
    }


# Six original tales per place. discovery on the first choice of the first three tales.
TALES = {
    "meadow": [
        ("Die Tauglocke", "The dew bell", "Gooby findet eine Glocke im Gras. Sie klingt nur, wenn jemand freundlich an den Morgen denkt.", "Gooby finds a bell in the grass. It rings only when someone thinks kindly of the morning.",
         ("An die Wiese denken", "Think of the meadow", "Die Glocke wird warm.", "The bell grows warm.", "kindness", 8, "meadow-d1"),
         ("Den Tau probieren", "Taste the dew", "Er schmeckt nach Minze.", "It tastes like mint.", "curiosity", 6, "")),
        ("Das Bienenschal", "The bee scarf", "Eine Biene legt einen unsichtbaren Schal um Goobys Hals. Er kitzelt wie Sommer.", "A bee lays an invisible scarf around Gooby's neck. It tickles like summer.",
         ("Still danke sagen", "Say a quiet thank you", "Die Biene summt zufrieden.", "The bee hums, content.", "empathy", 7, "meadow-d2"),
         ("Mitwackeln", "Wiggle along", "Gooby macht einen kleinen Tanz.", "Gooby does a tiny dance.", "playfulness", 7, "")),
        ("Zu große Decke", "A blanket too big", "Eine Picknickdecke will gefaltet werden und ist dabei sehr dramatisch.", "A picnic blanket wants folding and is very dramatic about it.",
         ("Sie glatt streichen", "Smooth it out", "Die Decke seufzt erleichtert.", "The blanket sighs with relief.", "calm", 6, "meadow-d3"),
         ("Darunter krabbeln", "Crawl underneath", "Es wird ein Zelt.", "It becomes a tent.", "playfulness", 8, "")),
        ("Der Gänseblümchenkreis", "The daisy circle", "Blumen haben einen Kreis gelegt. In der Mitte ist Platz für genau einen runden Hasen.", "Flowers have made a circle. The middle fits exactly one round bunny.",
         ("Sich hineinsetzen", "Sit inside", "Die Blumen nicken.", "The flowers nod.", "confidence", 7, ""),
         ("Eine Blume gießen", "Water one flower", "Ein neuer Kreis entsteht daneben.", "A new circle appears beside it.", "kindness", 7, "")),
        ("Wind mit Namen", "A wind with a name", "Der Wind stellt sich vor, vergisst den Namen aber sofort wieder.", "The wind introduces itself, then forgets the name at once.",
         ("Einen neuen Namen schenken", "Offer a new name", "Der Wind heißt jetzt Saus.", "The wind is called Whoosh now.", "kindness", 6, ""),
         ("Einfach zuhören", "Just listen", "Namen sind heute nicht wichtig.", "Names do not matter today.", "calm", 6, "")),
        ("Der mutige Grashalm", "The brave blade of grass", "Ein Halm will höher sein als Goobys Ohr und bittet um Anfeuern.", "A blade of grass wants to grow taller than Gooby's ear and asks for cheering.",
         ("Leise anfeuern", "Cheer softly", "Der Halm wächst einen Millimeter.", "The blade grows one millimeter.", "courage", 8, ""),
         ("Schatten spenden", "Offer shade", "Wachsen darf auch langsam sein.", "Growing may be slow.", "empathy", 7, "")),
    ],
    "garden": [
        ("Die Moostür", "The moss door", "Eine Hecke hat eine Tür, die nur quietscht, wenn man höflich klopft.", "A hedge has a door that squeaks only if you knock politely.",
         ("Dreimal klopfen", "Knock three times", "Die Tür erzählt einen kurzen Witz.", "The door tells a short joke.", "kindness", 8, "garden-d1"),
         ("Durch den Spalt linsen", "Peek through the gap", "Dahinter steht eine Teekanne.", "A teapot stands behind it.", "curiosity", 7, "")),
        ("Blattboot", "Leaf boat", "In einer Tasse schwimmt ein Blatt und will einen Kapitän.", "A leaf floats in a cup and wants a captain.",
         ("Vorsichtig schieben", "Push it gently", "Das Blatt erreicht den Tassenrand.", "The leaf reaches the rim.", "calm", 7, "garden-d2"),
         ("Eine Geschichte erzählen", "Tell it a story", "Das Blatt rudert vor Freude.", "The leaf rows with joy.", "playfulness", 8, "")),
        ("Karte aus Punkten", "A map of dots", "Glühwürmchen setzen sich zu einer Karte. Ein Punkt fehlt.", "Fireflies settle into a map. One dot is missing.",
         ("Den Punkt ergänzen", "Add the missing dot", "Der Weg nach Hause leuchtet.", "The way home lights up.", "curiosity", 9, "garden-d3"),
         ("Im Dunkeln warten", "Wait in the dark", "Die Karte findet sich selbst.", "The map finds itself.", "calm", 6, "")),
        ("Heckentheater", "Hedge theater", "Zwei Blätter spielen ein Stück über einen Hasen, der sehr rund und sehr mutig ist.", "Two leaves perform a play about a bunny who is very round and very brave.",
         ("Applaus geben", "Applaud", "Die Blätter verbeugen sich.", "The leaves bow.", "empathy", 7, ""),
         ("Mitspielen", "Join in", "Gooby bekommt die Hauptrolle.", "Gooby gets the lead.", "confidence", 8, "")),
        ("Vergessene Gießkanne", "A forgotten watering can", "Sie ist leer und ein bisschen traurig.", "It is empty and a little sad.",
         ("Sie füllen", "Fill it", "Die Kanne gluckert dankbar.", "The can gurgles gratefully.", "kindness", 6, ""),
         ("Daneben sitzen", "Sit beside it", "Leer sein darf heute okay sein.", "Being empty may be okay today.", "empathy", 7, "")),
        ("Der Schlüssel ohne Schloss", "The key without a lock", "Er glänzt und weiß nicht, wohin.", "It shines and does not know where to go.",
         ("Ihn einstecken", "Pocket it", "Vielleicht passt er später.", "Maybe it will fit later.", "curiosity", 6, ""),
         ("Ihn der Hecke zurückgeben", "Give it back to the hedge", "Die Hecke verwahrt ihn gut.", "The hedge keeps it safe.", "kindness", 7, "")),
    ],
    "cherry": [
        ("Rosa Luft", "Pink air", "Blüten fallen so langsam, dass Gooby jede einzelne grüßen könnte.", "Petals fall so slowly that Gooby could greet each one.",
         ("Eine Blüte fangen", "Catch a petal", "Sie wird zu einem Band.", "It becomes a ribbon.", "playfulness", 8, "cherry-d1"),
         ("Einfach schauen", "Simply watch", "Der Park wird still und weich.", "The park grows quiet and soft.", "calm", 7, "")),
        ("Die Schaukel", "The swing", "Eine Schaukel bewegt sich, obwohl kein Wind da ist. Auf dem Sitz liegt ein Zettel.", "A swing moves although there is no wind. A note lies on the seat.",
         ("Den Zettel lesen", "Read the note", "Darauf steht: du darfst langsam sein.", "It says: you may be slow.", "empathy", 8, "cherry-d2"),
         ("Einmal schaukeln", "Swing once", "Die Füße kommen kaum vom Boden, und das reicht.", "The feet barely leave the ground, and that is enough.", "courage", 7, "")),
        ("Schirm aus Papier", "A paper parasol", "Er will auf Goobys Kopf, ist aber schüchtern.", "It wants to sit on Gooby's head, but it is shy.",
         ("Ihn einladen", "Invite it", "Der Schirm passt perfekt.", "The parasol fits perfectly.", "kindness", 7, "cherry-d3"),
         ("Ihn neben sich stellen", "Set it beside you", "Gemeinsam ist der Schatten groß genug.", "Together the shade is big enough.", "calm", 6, "")),
        ("Baum mit Ohren", "A tree with ears", "Der Kirschbaum behauptet, er höre Geschichten besonders gern von Hasen.", "The cherry tree claims it especially likes stories from bunnies.",
         ("Eine kleine Geschichte erzählen", "Tell a small story", "Blüten fallen wie Applaus.", "Petals fall like applause.", "confidence", 8, ""),
         ("Eine Frage stellen", "Ask a question", "Der Baum antwortet mit Rauschen.", "The tree answers with rustling.", "curiosity", 7, "")),
        ("Bank für zwei", "A bench for two", "Die Bank ist lang. Gooby nimmt nur ein Eckchen.", "The bench is long. Gooby takes only a corner.",
         ("Platz frei lassen", "Leave room", "Ein Spatz setzt sich dazu.", "A sparrow sits down too.", "empathy", 6, ""),
         ("Sich ausstrecken", "Stretch out", "Rund sein braucht Raum.", "Being round needs room.", "confidence", 7, "")),
        ("Pfad aus Blüten", "A path of petals", "Jemand hat einen Weg gelegt, der im Kreis führt.", "Someone laid a path that leads in a circle.",
         ("Dem Kreis folgen", "Follow the circle", "Am Ende ist der Anfang freundlicher.", "At the end, the beginning is kinder.", "calm", 7, ""),
         ("Einen neuen Weg legen", "Lay a new path", "Er führt zu einer Pfütze mit Himmel drin.", "It leads to a puddle full of sky.", "curiosity", 8, "")),
    ],
    "crystal": [
        ("See, der zuhört", "A lake that listens", "Wirft Gooby einen Kiesel, antwortet das Wasser mit einem leisen Hallo.", "When Gooby tosses a pebble, the water answers with a soft hello.",
         ("Zurückgrüßen", "Greet it back", "Ein Spiegelkiesel springt an Land.", "A mirror pebble hops ashore.", "kindness", 8, "crystal-d1"),
         ("Noch einen Kiesel suchen", "Look for another pebble", "Alle sind verschieden und alle glänzen.", "Each one is different and all of them shine.", "curiosity", 7, "")),
        ("Tritte aus Glas", "Steps of glass", "Über dem Wasser liegen durchsichtige Tritte. Sie tragen nur, wer nicht hetzt.", "Clear steps lie on the water. They hold only those who do not rush.",
         ("Langsam gehen", "Walk slowly", "Gooby kommt trocken an.", "Gooby arrives dry.", "calm", 9, "crystal-d2"),
         ("Am Ufer bleiben", "Stay on the shore", "Schauen ist auch eine Reise.", "Looking is a journey too.", "confidence", 6, "")),
        ("Muschel mit Manieren", "A shell with manners", "Sie wiederholt nur, was freundlich gesagt wurde.", "It repeats only what was said kindly.",
         ("Etwas Nettes sagen", "Say something kind", "Die Muschel bewahrt den Satz.", "The shell keeps the sentence.", "empathy", 8, "crystal-d3"),
         ("Schweigen", "Stay quiet", "Auch Stille wird behutsam zurückgegeben.", "Silence is returned gently too.", "calm", 6, "")),
        ("Boot aus einem Blatt", "A boat from one leaf", "Es will zur Insel in der Mitte, die nur aus Licht besteht.", "It wants the island in the middle, which is made only of light.",
         ("Es loslassen", "Let it go", "Das Blatt findet die Mitte.", "The leaf finds the middle.", "courage", 7, ""),
         ("Mit dem Finger nachfahren", "Trace it with a finger", "Kleine Wellen werden zu einem Lächeln.", "Small waves become a smile.", "playfulness", 7, "")),
        ("Wolke im Wasser", "A cloud in the water", "Der See hat eine Wolke ausgeliehen und weiß nicht, wie man sie zurückgibt.", "The lake borrowed a cloud and does not know how to return it.",
         ("Die Wolke anstupsen", "Nudge the cloud", "Sie steigt freiwillig auf.", "It rises on its own.", "kindness", 7, ""),
         ("Sie noch lassen", "Let it stay", "Der See sieht aus wie ein Kissen.", "The lake looks like a cushion.", "empathy", 6, "")),
        ("Abendliche Ringe", "Evening rings", "Jeder Tropfen macht einen Ring, und einer davon passt um Goobys Pfote.", "Every drop makes a ring, and one of them fits Gooby's paw.",
         ("Den Ring ansehen", "Look at the ring", "Er zergeht, und das ist in Ordnung.", "It melts, and that is all right.", "calm", 6, ""),
         ("Einen neuen Tropfen setzen", "Add a new drop", "Zwei Ringe tanzen.", "Two rings dance.", "playfulness", 8, "")),
    ],
    "beach": [
        ("Muschel mit Nachmittag", "A shell with an afternoon inside", "Innen ist es warm, als hätte jemand die Sonne gefaltet.", "Inside it is warm, as if someone folded the sun.",
         ("Sie ans Ohr halten", "Hold it to an ear", "Man hört ein leises Lachen.", "You hear a quiet laugh.", "curiosity", 8, "beach-d1"),
         ("Sie in den Sand legen", "Lay it in the sand", "Eine Krabbe nickt anerkennend.", "A crab nods with respect.", "kindness", 6, "")),
        ("Drachen ohne Eile", "A kite without hurry", "Der Drache will hoch, aber nur wenn die Schnur freundlich ist.", "The kite wants to rise, but only if the string is kind.",
         ("Die Schnur locker lassen", "Keep the string loose", "Er steigt in seinem Tempo.", "It climbs at its own pace.", "calm", 8, "beach-d2"),
         ("Mitrennen", "Run along", "Gooby hopst, der Drache jubelt.", "Gooby hops, the kite cheers.", "playfulness", 8, "")),
        ("Flasche im Tang", "A bottle in the seaweed", "Darin steckt ein Zettel, der nicht drängelt.", "Inside is a note that does not rush anyone.",
         ("Den Zettel lesen", "Read the note", "Du bist rechtzeitig, steht da.", "You are right on time, it says.", "empathy", 9, "beach-d3"),
         ("Die Flasche weitergeben", "Pass the bottle on", "Die nächste Welle nimmt sie sanft mit.", "The next wave takes it gently.", "kindness", 7, "")),
        ("Sandburg mit Tür", "A sandcastle with a door", "Die Tür ist hasengroß. Drinnen liegt ein glatter Stein.", "The door is bunny-sized. Inside lies a smooth stone.",
         ("Den Stein mitnehmen", "Take the stone", "Er ist noch warm von der Sonne.", "It is still warm from the sun.", "courage", 7, ""),
         ("Die Tür offen lassen", "Leave the door open", "Eine Brise zieht ein.", "A breeze moves in.", "kindness", 6, "")),
        ("Fußspur nebenan", "A footprint beside yours", "Sie ist kleiner als Goobys und führt zum Wasser.", "It is smaller than Gooby's and leads to the water.",
         ("Daneben gehen", "Walk beside it", "Am Ufer wartet nur Licht.", "Only light waits at the shore.", "curiosity", 7, ""),
         ("Die eigene Spur betrachten", "Look at your own print", "Rund, deutlich, da.", "Round, clear, here.", "confidence", 8, "")),
        ("Salziger Wind", "Salty wind", "Er zerzaust ein Ohr und entschuldigt sich sofort.", "It ruffles one ear and apologizes at once.",
         ("Vergeben", "Forgive it", "Der Wind bringt dafür eine Feder.", "The wind brings a feather in return.", "empathy", 6, ""),
         ("Zurückpusten", "Puff back", "Beide müssen lachen.", "Both of them laugh.", "playfulness", 7, "")),
    ],
    "sugar": [
        ("Brücke aus Bonbons", "A bridge of sweets", "Sie knirscht und trägt Gooby trotzdem, weil er nicht trampelt.", "It crunches and still carries Gooby, because he does not stomp.",
         ("Auf Zehenspitzen", "On tiptoe", "Ein Zuckersteg bleibt als Andenken.", "A sugar step stays as a keepsake.", "courage", 8, "sugar-d1"),
         ("Im Bogen drumherum", "Around in an arc", "Der Bach aus Limonade gluckst Beifall.", "The lemonade brook chuckles applause.", "playfulness", 7, "")),
        ("Regen aus Streuseln", "A shower of sprinkles", "Bunte Punkte fallen und kleben nicht. Sie wollen gezählt werden.", "Colorful dots fall and do not stick. They want to be counted.",
         ("Bis zehn zählen", "Count to ten", "Der Regen klatscht.", "The rain claps.", "curiosity", 7, "sugar-d2"),
         ("Die Zunge rausstrecken", "Stick out a tongue", "Ein Punkt schmeckt nach Himbeere.", "One dot tastes like raspberry.", "playfulness", 8, "")),
        ("Kleines Karussell", "A small carousel", "Es dreht sich nur, wenn jemand lächelt, nicht wenn jemand hetzt.", "It turns only when someone smiles, not when someone hurries.",
         ("Lächeln und einsteigen", "Smile and step on", "Eine Runde, ein Ticket, ein Seufzer.", "One turn, one ticket, one sigh.", "confidence", 9, "sugar-d3"),
         ("Vom Rand winken", "Wave from the edge", "Das Karussell winkt zurück.", "The carousel waves back.", "kindness", 6, "")),
        ("Bäckerei ohne Tür", "A bakery without a door", "Der Duft lädt ein. Drinnen backt niemand, nur ein Ofen summt.", "The scent invites you in. Nobody is baking, only an oven humming.",
         ("Dem Ofen Gesellschaft leisten", "Keep the oven company", "Er wird ruhiger.", "It grows calmer.", "empathy", 7, ""),
         ("Ein Rezept murmeln", "Murmur a recipe", "Es duftet plötzlich nach Zimt.", "Suddenly it smells like cinnamon.", "curiosity", 7, "")),
        ("Hügel aus Gummidrops", "A hill of gumdrops", "Er ist weich. Oben liegt eine Aussicht auf die ganze Insel.", "It is soft. The top holds a view of the whole isle.",
         ("Hinaufhopsen", "Hop up", "Die Aussicht ist rosa und freundlich.", "The view is pink and friendly.", "courage", 8, ""),
         ("Am Fuß rasten", "Rest at the foot", "Auch der Anfang ist ein guter Platz.", "The beginning is a good place too.", "calm", 6, "")),
        ("Limo mit Strohhalm", "Lemonade with a straw", "Der Becher ist riesig. Gooby teilt ihn mit einer Ameise.", "The cup is huge. Gooby shares it with an ant.",
         ("Halb und halb", "Half and half", "Die Ameise verbeugt sich.", "The ant bows.", "kindness", 7, ""),
         ("Nur nippen", "Only sip", "Süß genug für einen Moment.", "Sweet enough for one moment.", "calm", 6, "")),
    ],
    "clouds": [
        ("Treppe aus Dunst", "Stairs of mist", "Jede Stufe trägt, solange Gooby nicht nach unten schaut.", "Each step holds as long as Gooby does not look down.",
         ("Nach vorn sehen", "Look ahead", "Oben weht ein bunter Faden.", "A colorful thread blows at the top.", "courage", 9, "clouds-d1"),
         ("Eine Stufe nach der anderen", "One step at a time", "Das reicht bis zur nächsten Wolke.", "That is enough to reach the next cloud.", "calm", 7, "")),
        ("Kissen mit Gedächtnis", "A cushion with a memory", "Es formt sich nach der letzten Umarmung und wartet auf eine neue.", "It shapes itself after the last hug and waits for a new one.",
         ("Sich anlehnen", "Lean in", "Das Kissen seufzt zufrieden.", "The cushion sighs, content.", "empathy", 8, "clouds-d2"),
         ("Es aufschütteln", "Fluff it", "Alte Falten dürfen gehen.", "Old creases may leave.", "kindness", 6, "")),
        ("Briefkasten im Wind", "A mailbox in the wind", "Die Klappe klappert. Drinnen liegt ein Brief ohne Absender.", "The flap rattles. Inside is a letter with no sender.",
         ("Ihn öffnen", "Open it", "Darin steht: komm an, wenn du kannst.", "It says: arrive when you can.", "curiosity", 8, "clouds-d3"),
         ("Ihn liegen lassen", "Leave it", "Manche Post reift noch.", "Some mail is still ripening.", "calm", 6, "")),
        ("Regenbogen zum Flicken", "A rainbow for mending", "Ein Faden hat sich gelöst. Er bittet um eine kleine Naht aus Mut.", "A thread has come loose. It asks for a small stitch of courage.",
         ("Einen Knoten machen", "Tie a knot", "Der Bogen hält wieder.", "The bow holds again.", "courage", 8, ""),
         ("Den Faden weitergeben", "Pass the thread on", "Eine andere Wolke näht mit.", "Another cloud sews along.", "kindness", 7, "")),
        ("Nickerchen über der Welt", "A nap above the world", "Die Wolke bietet ein kurzes Schlafen an, ohne Wecker.", "The cloud offers a short sleep, with no alarm.",
         ("Die Augen zumachen", "Close the eyes", "Gooby träumt von weichem Gras.", "Gooby dreams of soft grass.", "calm", 7, ""),
         ("Wach bleiben und schauen", "Stay awake and look", "Unten sind Dächer wie Knöpfe.", "Below, roofs look like buttons.", "curiosity", 7, "")),
        ("Windspiel", "A wind chime", "Es spielt nur drei Töne, alle freundlich.", "It plays only three notes, all of them kind.",
         ("Mitsummen", "Hum along", "Ein vierter Ton entsteht.", "A fourth note appears.", "playfulness", 7, ""),
         ("Nur zuhören", "Only listen", "Drei Töne sind ein ganzes Lied.", "Three notes are a whole song.", "empathy", 6, "")),
    ],
    "starwood": [
        ("Pfad aus Laternen", "A path of lanterns", "Zwischen Moos stehen Laternen, eine davon ist ausgegangen.", "Lanterns stand in the moss, and one has gone out.",
         ("Den Docht anstupsen", "Nudge the wick", "Ein warmer Kern bleibt in der Pfote.", "A warm seed stays in the paw.", "courage", 9, "starwood-d1"),
         ("Im Licht der anderen gehen", "Walk by the other lights", "Ausgegangen sein ist kein Fehler.", "Being out is not a mistake.", "empathy", 7, "")),
        ("Keks in Sternform", "A biscuit shaped like a star", "Er duftet nach Abend. Eine Krümelspur führt tiefer in den Wald.", "It smells like evening. A crumb trail leads deeper into the wood.",
         ("Einen Bissen teilen", "Share a bite", "Ein Käfer bedankt sich winzig.", "A beetle gives a tiny thanks.", "kindness", 8, "starwood-d2"),
         ("Der Spur folgen", "Follow the trail", "Sie endet an einem ruhigen Stein.", "It ends at a quiet stone.", "curiosity", 8, "")),
        ("Kompass aus Moos", "A compass of moss", "Die Nadel zeigt nicht nach Norden. Sie zeigt dorthin, wo Gooby durchatmen kann.", "The needle does not point north. It points where Gooby can breathe out.",
         ("Ihr folgen", "Follow it", "Eine Lichtung macht Platz.", "A clearing makes room.", "calm", 9, "starwood-d3"),
         ("Selbst die Richtung wählen", "Choose the direction", "Der Kompass nickt, als wäre das auch richtig.", "The compass nods, as if that is right too.", "confidence", 8, "")),
        ("Bibliothek aus Blättern", "A library of leaves", "Jedes Blatt hat einen Satz. Manche Sätze sind noch leer.", "Each leaf has a sentence. Some sentences are still empty.",
         ("Einen freundlichen Satz schreiben", "Write a kind sentence", "Das Blatt raschelt stolz.", "The leaf rustles proudly.", "kindness", 8, ""),
         ("Ein leeres Blatt lassen", "Leave a blank leaf", "Leere ist auch eine Einladung.", "Emptiness is an invitation too.", "empathy", 6, "")),
        ("Leiser Komet", "A quiet comet", "Er zieht vorbei und bittet, nicht laut zu staunen.", "It passes and asks that the wonder stay soft.",
         ("Flüstern", "Whisper", "Der Schweif wird länger.", "The tail grows longer.", "curiosity", 8, ""),
         ("Die Pfoten falten", "Fold the paws", "Staunen geht auch still.", "Wonder can be quiet.", "calm", 7, "")),
        ("Wurzel als Bank", "A root as a bench", "Sie ist knubbelig und genau richtig für einen runden Gast.", "It is knobbly and exactly right for a round guest.",
         ("Sich setzen", "Sit down", "Der Wald rückt ein Stück näher.", "The forest moves a little closer.", "confidence", 7, ""),
         ("Eine Eichel ablegen", "Leave an acorn", "Für jemand anderen, später.", "For someone else, later.", "kindness", 6, "")),
    ],
    "moon": [
        ("Silberne Stufen", "Silver steps", "Sie sind kühl und führen zu einem Stein, der ein Schlaflied summt.", "They are cool and lead to a stone that hums a lullaby.",
         ("Das Lied mitnehmen", "Take the song along", "Der Stein bleibt warm in der Erinnerung.", "The stone stays warm in memory.", "calm", 9, "moon-d1"),
         ("Auf der Stufe bleiben", "Stay on the step", "Der Mond ist auch von hier groß.", "The moon is large from here too.", "confidence", 6, "")),
        ("Garten im Krater", "A garden in a crater", "Kleine Kräuter wachsen nur, wenn man sie nicht zupft.", "Tiny herbs grow only if you do not pluck them.",
         ("Nur riechen", "Only smell", "Es duftet nach Ruhe.", "It smells like rest.", "empathy", 8, "moon-d2"),
         ("Einen Namen für ein Kraut finden", "Find a name for one herb", "Es heißt jetzt Mondminze.", "It is called moon mint now.", "playfulness", 7, "")),
        ("Picknick ohne Eile", "A picnic without hurry", "Die Decke zeigt Sterne, statt sie zu verdecken. Ein Becher Kakao wartet.", "The blanket shows the stars instead of hiding them. A cup of cocoa waits.",
         ("Sich dazu legen", "Lie down with it", "Der Nachthimmel rückt näher.", "The night sky moves closer.", "calm", 8, "moon-d3"),
         ("Den Kakao teilen", "Share the cocoa", "Ein Nachtfalter wärmt sich am Rand.", "A moth warms itself at the rim.", "kindness", 8, "")),
        ("Mondkiesel", "A moon pebble", "Er ist rund wie Gooby und ein bisschen leuchtend.", "It is round like Gooby and a little bit glowing.",
         ("Ihn polieren", "Polish it", "Das Leuchten wird weicher.", "The glow grows softer.", "kindness", 6, ""),
         ("Ihn rollen lassen", "Let it roll", "Er findet eine Mulde und bleibt.", "It finds a hollow and stays.", "playfulness", 7, "")),
        ("Frage an die Nacht", "A question for the night", "Gooby fragt leise, ob langsam sein mutig ist.", "Gooby asks softly whether being slow is brave.",
         ("Auf die Antwort warten", "Wait for the answer", "Ein Stern blinkt ja.", "A star blinks yes.", "courage", 9, ""),
         ("Die Frage so lassen", "Leave the question", "Nicht alles braucht sofort ein Ende.", "Not everything needs an ending at once.", "calm", 7, "")),
        ("Schatten mit Ohren", "A shadow with ears", "Goobys Schatten macht die Ohren noch länger und lacht.", "Gooby's shadow makes the ears even longer and laughs.",
         ("Mitlachen", "Laugh along", "Der Schatten verbeugt sich.", "The shadow bows.", "playfulness", 7, ""),
         ("Die echte Form ansehen", "Look at the real shape", "Rund ist genau richtig.", "Round is exactly right.", "confidence", 8, "")),
    ],
    "snow": [
        ("Zwei linke Fäustlinge", "Two left mittens", "Sie passen trotzdem, weil Schnee sich nicht um Regeln schert.", "They fit anyway, because snow does not care about rules.",
         ("Sie anziehen", "Put them on", "Die Pfoten bleiben warm.", "The paws stay warm.", "confidence", 8, "snow-d1"),
         ("Eine für später legen", "Set one aside for later", "Jemand anders kommt noch.", "Someone else is still coming.", "kindness", 8, "")),
        ("Schlitten am Hügel", "A sled on the hill", "Er ist langsam und stolz darauf.", "It is slow and proud of it.",
         ("Eine ruhige Fahrt", "A quiet ride", "Unten wartet ein Band als Andenken.", "A ribbon waits at the bottom as a keepsake.", "courage", 9, "snow-d2"),
         ("Den Schlitten schieben", "Push the sled", "Helfen ist auch ein Abenteuer.", "Helping is an adventure too.", "empathy", 7, "")),
        ("Licht im Fenster", "Light in a window", "Jemand lässt es an, damit Heimkehrer den Weg sehen.", "Someone leaves it on so travelers can see the way home.",
         ("Zurückwinken", "Wave back", "Das Licht wird einen Tick wärmer.", "The light grows a touch warmer.", "empathy", 8, "snow-d3"),
         ("Den eigenen Weg merken", "Notice your own path", "Spuren führen klar nach vorn.", "Tracks lead clearly ahead.", "confidence", 7, "")),
        ("Kakao, der bleibt", "Cocoa that stays", "Die Kanne wird nicht leer, solange jemand sich Zeit nimmt.", "The pot does not empty as long as someone takes their time.",
         ("Langsam trinken", "Drink slowly", "Wärme bis in die Ohren.", "Warmth all the way to the ears.", "calm", 7, ""),
         ("Eine zweite Tasse hinstellen", "Set out a second cup", "Für den Nächsten.", "For the next one.", "kindness", 7, "")),
        ("Spur eines anderen Hasen", "Another bunny's tracks", "Sie sind rund und führen um den Brunnen.", "They are round and circle the well.",
         ("Folgen", "Follow", "Am Brunnen liegt ein Lächeln aus Eis.", "At the well lies a smile made of ice.", "curiosity", 8, ""),
         ("Eigene Spur daneben", "Make a track beside them", "Zwei Wege, beide richtig.", "Two paths, both right.", "confidence", 7, "")),
        ("Schneestern", "A snow star", "Er fällt auf Goobys Nase und schmilzt nicht sofort.", "It lands on Gooby's nose and does not melt at once.",
         ("Ihn anschauen, bis er geht", "Watch until it leaves", "Abschied kann weich sein.", "A goodbye can be soft.", "calm", 6, ""),
         ("Ihn weiterpusten", "Puff it onward", "Er landet auf einem Fensterbrett.", "It lands on a windowsill.", "playfulness", 7, "")),
    ],
}


def stories():
    rows = []
    for place, tales in TALES.items():
        for index, tale in enumerate(tales, start=1):
            title_de, title_en, body_de, body_en, a, b = tale
            rows.append({
                "id": f"{place}-{index:02d}",
                "placeID": place,
                "title": loc(title_de, title_en),
                "body": loc(body_de, body_en),
                "choices": [
                    choice("a", *a),
                    choice("b", *b),
                ],
            })
    return rows


def item(iid, kind, slot, style, price, rarity, color, color2, de, en, bde, ben, shop, starter=False, event=""):
    return {
        "id": iid, "kind": kind, "slot": slot, "style": style, "price": price, "rarity": rarity,
        "color": color, "color2": color2, "name": loc(de, en), "blurb": loc(bde, ben),
        "shop": shop, "starter": starter, "seasonalEvent": event,
    }


def items():
    rows = [
        item("fur-cream", "color", "fur", 0, 0, "common", "FFF6EA", "FFC2D6", "Cremefell", "Cream fur", "Goobys erstes weiches Fell.", "Gooby's first soft coat.", "colors", True),
        item("fur-peach", "color", "fur", 1, 80, "common", "FFE1C8", "FFB3C7", "Pfirsichfell", "Peach fur", "Warm wie Gebäck.", "Warm as baking.", "colors"),
        item("fur-lilac", "color", "fur", 2, 80, "common", "F4ECFF", "F3B6D4", "Fliederfell", "Lilac fur", "Ein Hauch Abend.", "A hint of evening.", "colors"),
        item("fur-mint", "color", "fur", 3, 90, "uncommon", "F3FFF6", "FFC0D4", "Minzfell", "Mint fur", "Frisch wie Tau.", "Fresh as dew.", "colors"),
        item("fur-honey", "color", "fur", 4, 90, "uncommon", "FFF3D8", "FFB7C6", "Honigfell", "Honey fur", "Sonnig und rund.", "Sunny and round.", "colors"),
        item("fur-sky", "color", "fur", 5, 120, "rare", "F4FBFF", "FFC2D6", "Himmelsfell", "Sky fur", "Hell wie ein klarer Morgen.", "Bright as a clear morning.", "colors"),
        item("wall-cream", "furniture", "wall", 0, 0, "common", "FFF1E4", "FFF8EF", "Cremige Wand", "Cream wall", "Der erste Hintergrund.", "The first background.", "furniture", True),
        item("wall-blush", "furniture", "wall", 1, 70, "common", "FFE4EF", "FFD6E7", "Rosa Wand", "Blush wall", "Wie ein leiser Sonnenuntergang.", "Like a quiet sunset.", "furniture"),
        item("wall-lilac", "furniture", "wall", 2, 70, "common", "E7DEFF", "D3C2FF", "Lilane Wand", "Lilac wall", "Abendlicht ohne Eile.", "Evening light without hurry.", "furniture"),
        item("floor-blush", "furniture", "floor", 0, 0, "common", "FFD6B3", "FFE7AD", "Pfirsichboden", "Peach floor", "Weich unter den Füßen.", "Soft underfoot.", "furniture", True),
        item("floor-mint", "furniture", "floor", 1, 60, "common", "C6EFDC", "FFF8EF", "Minzboden", "Mint floor", "Wie eine Wiese im Zimmer.", "Like a meadow indoors.", "furniture"),
        item("floor-sky", "furniture", "floor", 2, 60, "common", "C8E9FF", "FFF8EF", "Himmelsboden", "Sky floor", "Ein bisschen Wolke.", "A bit of cloud.", "furniture"),
        item("bed-cream", "furniture", "bed", 0, 0, "common", "FFF6EA", "FFD6E7", "Cremebett", "Cream bed", "Klein, rund, einladend.", "Small, round, inviting.", "furniture", True),
        item("bed-cloud", "furniture", "bed", 1, 140, "uncommon", "F4FBFF", "D3C2FF", "Wolkenbett", "Cloud bed", "Wirkt wie ein Nickerchen.", "Looks like a nap.", "furniture"),
        item("bed-blossom", "furniture", "bed", 2, 180, "rare", "FFD6E7", "FFE7AD", "Blütenbett", "Blossom bed", "Für rosa Träume.", "For pink dreams.", "furniture"),
        item("rug-cloud", "furniture", "rug", 0, 0, "common", "FFF8EF", "C8E9FF", "Wolkenteppich", "Cloud rug", "Liegt schon bereit.", "Already waiting.", "furniture", True),
        item("rug-mint", "furniture", "rug", 1, 50, "common", "C6EFDC", "FFF8EF", "Minzteppich", "Mint rug", "Ein ovales Stück Wiese.", "An oval piece of meadow.", "furniture"),
        item("rug-star", "furniture", "rug", 2, 90, "uncommon", "D3C2FF", "FFE7AD", "Sternenteppich", "Star rug", "Kleine Punkte, große Ruhe.", "Small dots, great calm.", "furniture"),
        item("lamp-blossom", "furniture", "lamp", 0, 0, "common", "FFE7AD", "FFD6E7", "Blütenlampe", "Blossom lamp", "Wärmt den Abend.", "Warms the evening.", "furniture", True),
        item("lamp-moon", "furniture", "lamp", 1, 80, "uncommon", "C8E9FF", "FFF3C9", "Mondlampe", "Moon lamp", "Für die blaue Stunde.", "For the blue hour.", "furniture"),
        item("lamp-honey", "furniture", "lamp", 2, 70, "common", "FFD6B3", "FFF8EF", "Honiglampe", "Honey lamp", "Goldenes Licht.", "Golden light.", "furniture"),
        item("window-round", "furniture", "window", 0, 0, "common", "C8E9FF", "FFF8EF", "Rundes Fenster", "Round window", "Der Himmel schaut herein.", "The sky looks in.", "furniture", True),
        item("window-arch", "furniture", "window", 1, 100, "uncommon", "D3C2FF", "C8E9FF", "Bogenfenster", "Arch window", "Etwas höher, immer noch weich.", "A little taller, still soft.", "furniture"),
        item("window-heart", "furniture", "window", 2, 120, "rare", "FFD6E7", "C8E9FF", "Herzfenster", "Heart window", "Die Aussicht ist freundlich.", "The view is kind.", "furniture"),
        item("plant-sprout", "furniture", "plant", 0, 0, "common", "C6EFDC", "7DCAA8", "Kleiner Spross", "Little sprout", "Wächst ohne Druck.", "Grows without pressure.", "furniture", True),
        item("plant-fern", "furniture", "plant", 1, 60, "common", "9ED9B8", "C6EFDC", "Farn", "Fern", "Ein grüner Fächer.", "A green fan.", "furniture"),
        item("plant-blossom", "furniture", "plant", 2, 80, "uncommon", "FFD6E7", "C6EFDC", "Blumentopf", "Flower pot", "Eine Blüte, kein Muss.", "One bloom, no demand.", "furniture"),
        item("shelf-books", "furniture", "shelf", 0, 90, "common", "FFD6B3", "FFF8EF", "Bücherbrett", "Book ledge", "Für kleine Geschichten.", "For small stories.", "furniture"),
        item("shelf-stars", "furniture", "shelf", 1, 110, "uncommon", "D3C2FF", "FFE7AD", "Sternenbrett", "Star ledge", "Ein Platz für Fundstücke.", "A place for finds.", "furniture"),
        item("picture-meadow", "furniture", "picture", 0, 70, "common", "C6EFDC", "FFE7AD", "Wiesenbild", "Meadow picture", "Grün in einem Rahmen.", "Green in a frame.", "furniture"),
        item("picture-moon", "furniture", "picture", 1, 70, "common", "C8E9FF", "D3C2FF", "Mondbild", "Moon picture", "Eine runde Nacht.", "A round night.", "furniture"),
        item("picture-sea", "furniture", "picture", 2, 90, "uncommon", "C8E9FF", "FFE7AD", "Meeresbild", "Sea picture", "Wellen, nur angedeutet.", "Waves, only suggested.", "furniture"),
        item("sofa-peach", "furniture", "sofa", 0, 160, "uncommon", "FFD6B3", "FFF8EF", "Pfirsichsofa", "Peach sofa", "Für zwei, oder für einen runden Hasen.", "For two, or one round bunny.", "furniture"),
        item("sofa-mint", "furniture", "sofa", 1, 160, "uncommon", "C6EFDC", "FFF8EF", "Minzsofa", "Mint sofa", "Sieht aus wie eine Pause.", "Looks like a pause.", "furniture"),
        item("table-round", "furniture", "table", 0, 80, "common", "FFE7AD", "FFD6B3", "Runder Tisch", "Round table", "Für eine Tasse.", "For one cup.", "furniture"),
        item("table-low", "furniture", "table", 1, 80, "common", "FFD6E7", "FFF8EF", "Niedriger Tisch", "Low table", "Auf Hasenhöhe.", "At bunny height.", "furniture"),
        item("cushion-peach", "furniture", "cushion", 0, 0, "common", "FFD6B3", "FFD6E7", "Pfirsichkissen", "Peach cushion", "Schon im Zimmer.", "Already in the room.", "furniture", True),
        item("cushion-sky", "furniture", "cushion", 1, 40, "common", "C8E9FF", "FFF8EF", "Himmelskissen", "Sky cushion", "Leicht wie ein Seufzer.", "Light as a sigh.", "furniture"),
        item("cushion-star", "furniture", "cushion", 2, 50, "uncommon", "D3C2FF", "FFE7AD", "Sternkissen", "Star cushion", "Ein Punkt in der Mitte.", "A dot in the middle.", "furniture"),
    ]
    clothes = [
        ("hat-sun", "hat", 1, 70, "common", "FFE7AD", "FFF8EF", "Sonnenkringel", "Sun brim", "Ein weiter Strohrand."),
        ("hat-cloud", "hat", 2, 80, "common", "F4FBFF", "C8E9FF", "Wolkenmütze", "Cloud cap", "Sitzt weich zwischen den Ohren."),
        ("hat-berry", "hat", 0, 90, "uncommon", "E989B0", "FFD6E7", "Beerenbarett", "Berry beret", "Ein bisschen schief, sehr charmant."),
        ("hat-star", "hat", 2, 120, "rare", "D3C2FF", "FFE7AD", "Sternchenmütze", "Star cap", "Mit einem kleinen Punkt oben."),
        ("hat-blossom", "hat", 3, 100, "uncommon", "FFD6E7", "C6EFDC", "Blütenkranz", "Blossom crown", "Blumen, die nicht welken."),
        ("hat-night", "hat", 0, 60, "common", "3D3656", "D3C2FF", "Nachtkäppchen", "Night cap", "Für das Zubettgehen."),
        ("bow-rose", "bow", 0, 40, "common", "FF8FB3", "FFF8EF", "Rosaschleife", "Rose bow", "Klassisch und rund."),
        ("bow-mint", "bow", 0, 40, "common", "7DCAA8", "FFF8EF", "Minzschleife", "Mint bow", "Frisch unter dem Kinn."),
        ("bow-lilac", "bow", 0, 50, "uncommon", "B79BE8", "FFF8EF", "Lavendelschleife", "Lavender bow", "Abendfarben."),
        ("bow-honey", "bow", 0, 70, "rare", "F0C36A", "FFF8EF", "Honigschleife", "Honey bow", "Ein goldener Knoten."),
        ("glass-honey", "glasses", 0, 70, "common", "C9A184", "FFF8EF", "Honigbrille", "Honey glasses", "Runde Gläser."),
        ("glass-star", "glasses", 1, 90, "uncommon", "3D3656", "FFE7AD", "Sternenbrille", "Star glasses", "Winzige Ecken an den Rändern."),
        ("glass-heart", "glasses", 2, 90, "uncommon", "E989B0", "FFF8EF", "Herzbrille", "Heart glasses", "Sieht die Welt weicher."),
        ("glass-moon", "glasses", 0, 80, "common", "8E93B8", "C8E9FF", "Mondbrille", "Moon glasses", "Für späte Seiten."),
        ("shirt-sky", "shirt", 0, 60, "common", "C8E9FF", "FFF8EF", "Himmelsshirt", "Sky shirt", "Locker über dem Bauch."),
        ("shirt-peach", "shirt", 1, 60, "common", "FFD6B3", "FFF8EF", "Pfirsichshirt", "Peach shirt", "Weich und kurzärmlig."),
        ("shirt-mint", "shirt", 2, 70, "uncommon", "C6EFDC", "3D3656", "Minzshirt", "Mint shirt", "Mit einem kleinen Knopf."),
        ("shirt-star", "shirt", 2, 100, "rare", "D3C2FF", "FFE7AD", "Sternenshirt", "Star shirt", "Ein Punkt auf der Brust."),
        ("shirt-cream", "shirt", 0, 50, "common", "FFF6EA", "FFD6E7", "Cremeshirt", "Cream shirt", "Fast wie Fell, nur Stoff."),
        ("sweater-rose", "sweater", 0, 110, "uncommon", "FFB7CC", "FFF8EF", "Rosapullover", "Rose sweater", "Kuschelig und weit."),
        ("sweater-sky", "sweater", 1, 110, "uncommon", "A9D4F2", "FFF8EF", "Wolkenpullover", "Cloud sweater", "Wirkt wie ein Umhang."),
        ("sweater-honey", "sweater", 0, 120, "rare", "F0C36A", "FFF8EF", "Honigpullover", "Honey sweater", "Warm ohne zu kratzen."),
        ("sweater-lilac", "sweater", 1, 120, "rare", "C7B4F5", "FFF8EF", "Fliederpullover", "Lilac sweater", "Abendtauglich."),
        ("jacket-mint", "jacket", 0, 150, "rare", "9ED9B8", "FFF8EF", "Minzjacke", "Mint jacket", "Für Ausflüge."),
        ("jacket-night", "jacket", 1, 170, "rare", "3D3656", "D3C2FF", "Nachtjacke", "Night jacket", "Dunkel, aber freundlich."),
        ("jacket-sun", "jacket", 0, 150, "uncommon", "FFE7AD", "FFD6B3", "Sonnenjacke", "Sun jacket", "Leicht und hell."),
        ("dress-blossom", "dress", 0, 160, "rare", "FFD6E7", "FFF8EF", "Blütenkleid", "Blossom dress", "Fällt weich über den Bauch."),
        ("dress-sky", "dress", 1, 150, "uncommon", "C8E9FF", "FFF8EF", "Himmelskleid", "Sky dress", "Wie ein klarer Tag."),
        ("dress-honey", "dress", 0, 170, "rare", "FFE7AD", "FFD6B3", "Honigkleid", "Honey dress", "Goldener Saum."),
        ("dress-mint", "dress", 1, 140, "uncommon", "C6EFDC", "FFF8EF", "Minzkleid", "Mint dress", "Für die Wiese."),
        ("pants-cloud", "pants", 0, 70, "common", "F4FBFF", "C8E9FF", "Wolkenhose", "Cloud pants", "Bequem und kurz."),
        ("pants-berry", "pants", 1, 80, "uncommon", "E989B0", "FFD6E7", "Beerenhose", "Berry pants", "Ein fröhlicher Farbtupfer."),
        ("pants-ink", "pants", 0, 80, "common", "3D3656", "D3C2FF", "Tintenhose", "Ink pants", "Schlicht und weich."),
        ("pants-leaf", "pants", 1, 70, "common", "9ED9B8", "FFF8EF", "Blatthose", "Leaf pants", "Grün wie der Farn."),
        ("shoes-button", "shoes", 1, 60, "common", "FFD6B3", "FFF8EF", "Knopfschuhe", "Button shoes", "Zwei kleine Knöpfe."),
        ("shoes-cloud", "shoes", 0, 70, "common", "F4FBFF", "C8E9FF", "Wolkenschuhe", "Cloud shoes", "Fast geräuschlos."),
        ("shoes-berry", "shoes", 1, 80, "uncommon", "E989B0", "FFF8EF", "Beerenschuhe", "Berry shoes", "Für feste Wege."),
        ("shoes-star", "shoes", 0, 100, "rare", "D3C2FF", "FFE7AD", "Sternschuhe", "Star shoes", "Ein Punkt auf jeder Spitze."),
        ("pack-mint", "backpack", 0, 90, "uncommon", "9ED9B8", "FFF8EF", "Minzrucksack", "Mint pack", "Für einen Kiesel und ein Tuch."),
        ("pack-rose", "backpack", 1, 90, "uncommon", "FFB7CC", "FFF8EF", "Rosarucksack", "Rose pack", "Rund wie sein Träger."),
        ("pack-night", "backpack", 0, 120, "rare", "3D3656", "FFE7AD", "Nachtrucksack", "Night pack", "Mit einer kleinen Schnalle."),
        ("scarf-sky", "scarf", 0, 50, "common", "A9D4F2", "FFF8EF", "Himmelschal", "Sky scarf", "Einmal um den Hals."),
        ("scarf-rose", "scarf", 1, 50, "common", "FF8FB3", "FFF8EF", "Rosaschal", "Rose scarf", "Weich geknotet."),
        ("scarf-honey", "scarf", 0, 70, "uncommon", "F0C36A", "FFF8EF", "Honigschal", "Honey scarf", "Wärmt die Wangen nicht, nur das Herz."),
        ("scarf-star", "scarf", 1, 80, "rare", "D3C2FF", "FFE7AD", "Sternschal", "Star scarf", "Ein Punkt am Ende."),
        ("pin-star", "accessory", 1, 40, "common", "FFE7AD", "FFF8EF", "Sternennadel", "Star pin", "Sitzt an der Brust."),
        ("pin-bell", "accessory", 2, 40, "common", "F0C36A", "FFF8EF", "Kleines Glöckchen", "Little bell", "Klingt nur beim Hüpfen."),
        ("pin-blossom", "accessory", 0, 50, "uncommon", "FF8FB3", "FFF8EF", "Wangenblüte", "Cheek blossom", "Eine Blume zum Anstecken."),
        ("pin-moon", "accessory", 1, 60, "rare", "FFF3C9", "C8E9FF", "Mondstecker", "Moon pin", "Ein runder Schimmer."),
        ("pin-heart", "accessory", 0, 40, "common", "FF8FB3", "FFF8EF", "Herzstecker", "Heart pin", "Ganz klein."),
    ]
    for row in clothes:
        iid, slot, style, price, rarity, color, color2, de, en, blurb = row
        rows.append(item(iid, "clothing", slot, style, price, rarity, color, color2, de, en, blurb, blurb, "wardrobe"))
    # English blurbs for clothes were copied German in the tuple's last field only once.
    # Replace blurb en with a short English line derived below if identical.
    english = {
        "Ein weiter Strohrand.": "A wide straw brim.",
        "Sitzt weich zwischen den Ohren.": "Sits softly between the ears.",
        "Ein bisschen schief, sehr charmant.": "A little tilted, very charming.",
        "Mit einem kleinen Punkt oben.": "With a small dot on top.",
        "Blumen, die nicht welken.": "Flowers that do not wilt.",
        "Für das Zubettgehen.": "For bedtime.",
        "Klassisch und rund.": "Classic and round.",
        "Frisch unter dem Kinn.": "Fresh under the chin.",
        "Abendfarben.": "Evening colors.",
        "Ein goldener Knoten.": "A golden knot.",
        "Runde Gläser.": "Round lenses.",
        "Winzige Ecken an den Rändern.": "Tiny corners at the rims.",
        "Sieht die Welt weicher.": "Sees the world more softly.",
        "Für späte Seiten.": "For late pages.",
        "Locker über dem Bauch.": "Loose over the belly.",
        "Weich und kurzärmlig.": "Soft and short-sleeved.",
        "Mit einem kleinen Knopf.": "With one small button.",
        "Ein Punkt auf der Brust.": "A dot on the chest.",
        "Fast wie Fell, nur Stoff.": "Almost like fur, only cloth.",
        "Kuschelig und weit.": "Cosy and roomy.",
        "Wirkt wie ein Umhang.": "Feels like a wrap.",
        "Warm ohne zu kratzen.": "Warm without itching.",
        "Abendtauglich.": "Fit for evening.",
        "Für Ausflüge.": "For outings.",
        "Dunkel, aber freundlich.": "Dark, but friendly.",
        "Leicht und hell.": "Light and bright.",
        "Fällt weich über den Bauch.": "Falls softly over the belly.",
        "Wie ein klarer Tag.": "Like a clear day.",
        "Goldener Saum.": "A golden hem.",
        "Für die Wiese.": "For the meadow.",
        "Bequem und kurz.": "Easy and short.",
        "Ein fröhlicher Farbtupfer.": "A cheerful dab of color.",
        "Schlicht und weich.": "Plain and soft.",
        "Grün wie der Farn.": "Green as the fern.",
        "Zwei kleine Knöpfe.": "Two small buttons.",
        "Fast geräuschlos.": "Almost silent.",
        "Für feste Wege.": "For steady paths.",
        "Ein Punkt auf jeder Spitze.": "A dot on each toe.",
        "Für einen Kiesel und ein Tuch.": "For a pebble and a cloth.",
        "Rund wie sein Träger.": "Round like its wearer.",
        "Mit einer kleinen Schnalle.": "With a small buckle.",
        "Einmal um den Hals.": "Once around the neck.",
        "Weich geknotet.": "Softly knotted.",
        "Wärmt die Wangen nicht, nur das Herz.": "It warms the heart, not the cheeks.",
        "Ein Punkt am Ende.": "A dot at the end.",
        "Sitzt an der Brust.": "Sits on the chest.",
        "Klingt nur beim Hüpfen.": "Rings only when hopping.",
        "Eine Blume zum Anstecken.": "A flower to pin on.",
        "Ein runder Schimmer.": "A round shimmer.",
        "Ganz klein.": "Very small.",
    }
    for row in rows:
        if row["kind"] == "clothing" and row["blurb"]["en"] in english:
            row["blurb"]["en"] = english[row["blurb"]["en"]]
        if row["kind"] == "clothing" and row["blurb"]["en"] == row["blurb"]["de"]:
            raise SystemExit("missing english blurb " + row["id"])
    seasonal = [
        ("decor-blossom", "seasonal", 0, 80, "FFD6E7", "Frühlingszweig", "Spring sprig", "spring", "Ein Zweig für die Ecke."),
        ("decor-lantern", "seasonal", 1, 90, "FFE7AD", "Laterne", "Lantern", "autumn", "Für den Laternenabend."),
        ("decor-snow", "seasonal", 2, 90, "E7F4FF", "Schneestern", "Snow star", "winter", "Hängt über dem Fenster."),
        ("decor-sun", "seasonal", 0, 80, "FFE7AD", "Sonnenfähnchen", "Sun flag", "summer", "Knattert nur leise."),
        ("hat-blossom-fest", "hat", 3, 100, "FFD6E7", "Festkranz", "Festival wreath", "spring", "Nur im Frühlingserwachen."),
        ("dress-summer", "dress", 0, 140, "FFE7AD", "Sommerkleid", "Summer dress", "summer", "Leicht wie Mittag."),
        ("scarf-leaf", "scarf", 0, 70, "FFD6B3", "Blätterschal", "Leaf scarf", "autumn", "In Herbstfarben."),
        ("hat-winter", "hat", 2, 90, "E7F4FF", "Schneemütze", "Snow cap", "winter", "Mit einem Bommel aus Wolke."),
        ("pin-spark", "accessory", 1, 60, "FFE7AD", "Neujahrsfunke", "New-year spark", "newyear", "Ein einzelner Glanz."),
        ("bow-honeyweek", "bow", 0, 50, "FFB7CC", "Honigschleife der Woche", "Honey-week bow", "honey", "Für die Honigmond-Woche."),
        ("decor-petal", "seasonal", 1, 70, "FFD6E7", "Blütenmobile", "Petal mobile", "cherry", "Dreht sich im Luftzug."),
        ("cushion-festival", "cushion", 2, 60, "D3C2FF", "Festkissen", "Festival cushion", "spring", "Lila und rund."),
    ]
    en_s = {
        "Ein Zweig für die Ecke.": "A sprig for the corner.",
        "Für den Laternenabend.": "For lantern evening.",
        "Hängt über dem Fenster.": "Hangs over the window.",
        "Knattert nur leise.": "It flutters quietly.",
        "Nur im Frühlingserwachen.": "Only during Spring Awakening.",
        "Leicht wie Mittag.": "Light as midday.",
        "In Herbstfarben.": "In autumn colors.",
        "Mit einem Bommel aus Wolke.": "With a pom of cloud.",
        "Ein einzelner Glanz.": "A single gleam.",
        "Für die Honigmond-Woche.": "For Honey Moon week.",
        "Dreht sich im Luftzug.": "It turns in a draft.",
        "Lila und rund.": "Lilac and round.",
    }
    for iid, slot, style, price, color, de, en, event, blurb in seasonal:
        kind = "furniture" if slot in {"seasonal", "cushion"} else "clothing"
        shop = "seasonal"
        rows.append(item(iid, kind, slot, style, price, "special", color, "FFF8EF", de, en, blurb, en_s[blurb], shop, event=event))
    for row in PLACES:
        pid, de, en, _bde, _ben, _minutes, unlock, price, *_rest = row
        if unlock == 0:
            continue
        rows.append(item(
            f"ticket-{pid}", "travel", "place", 0, price, "uncommon", "C8E9FF", "FFE7AD",
            f"Ticket: {de}", f"Ticket: {en}",
            "Öffnet den Ort sofort.", "Opens the place at once.",
            "travel",
        ))
    return rows


def friends():
    data = [
        ("chick", "Küken", "Chicklet", "common", 8, "Ein rundes Gelb mit winzigem Schnabel.", "A round yellow with a tiny beak."),
        ("cloud", "Wölkchen", "Little Cloud", "common", 8, "Drei Kreise und ein leises Lächeln.", "Three circles and a quiet smile."),
        ("dragon", "Babydrache", "Baby dragon", "uncommon", 5, "Minzgrün, mit zwei kleinen Hörnern.", "Mint green, with two small horns."),
        ("fox", "Fuchs", "Fox", "uncommon", 5, "Pfirsichfarben und neugierig.", "Peach colored and curious."),
        ("starling", "Sternenwesen", "Star being", "rare", 3, "Ein Stern mit Augen.", "A star with eyes."),
        ("penguin", "Baby-Pinguin", "Baby penguin", "uncommon", 5, "Bauch weiß, Rest Tinte.", "White belly, the rest ink."),
        ("bear", "Bär", "Bear", "common", 7, "Ohren wie Kekse.", "Ears like biscuits."),
        ("cat", "Mini-Katze", "Mini cat", "common", 7, "Sehr kleine Schnurrhaare.", "Very small whiskers."),
        ("ghost", "Geist", "Ghost", "rare", 3, "Freundlich durchscheinend.", "Kindly see-through."),
        ("unicorn", "Mini-Einhorn", "Mini unicorn", "special", 2, "Ein Horn aus Lavendel.", "A horn of lavender."),
        ("moon", "Mondwesen", "Moon being", "rare", 3, "Fast ein Kreis, absichtlich.", "Almost a circle, on purpose."),
        ("mushroom", "Pilzfreund", "Mushroom friend", "uncommon", 5, "Rosa Hut, weißes Gesicht.", "Pink cap, white face."),
    ]
    return [{
        "id": i, "name": loc(de, en), "rarity": rarity, "weight": weight, "blurb": loc(bde, ben)
    } for i, de, en, rarity, weight, bde, ben in data]


def quests():
    daily = [
        ("d-habits", "habits", 3, 12, "Drei Gewohnheiten", "Three habits", "Schließe heute drei Aufgaben ab.", "Finish three tasks today."),
        ("d-mood", "mood", 1, 8, "Stimmung notieren", "Note a mood", "Ein Eintrag reicht.", "One entry is enough."),
        ("d-journal", "journal", 1, 10, "Ein Satz im Tagebuch", "A sentence in the journal", "Schreiben, nicht perfekt sein.", "Write, do not be perfect."),
        ("d-breath", "breath", 1, 8, "Einmal atmen", "Breathe once", "Eine kleine Runde.", "One small round."),
        ("d-focus", "focus", 10, 14, "Zehn Minuten Fokus", "Ten minutes of focus", "Der Timer zählt mit.", "The timer keeps count."),
        ("d-move", "movement", 1, 10, "Bewegungspause", "Movement break", "Eine Übung genügt.", "One exercise is enough."),
        ("d-adventure", "adventure", 1, 16, "Ein Abenteuer", "One adventure", "Gooby darf heute los.", "Gooby may head out today."),
        ("d-pet", "pet", 1, 6, "Gooby beachten", "Notice Gooby", "Streicheln, lachen oder Herzchen.", "Pet, laugh, or hearts."),
    ]
    miles = [
        ("m-habits-10", "habits", 10, 20, "", "Zehn Abschlüsse", "Ten completions"),
        ("m-streak-3", "streak", 3, 25, "", "Serie von drei Tagen", "A three-day streak"),
        ("m-streak-7", "streak", 7, 40, "scarf-sky", "Serie von sieben Tagen", "A seven-day streak"),
        ("m-adv-1", "adventure", 1, 15, "", "Erstes Abenteuer", "First adventure"),
        ("m-adv-10", "adventure", 10, 40, "pin-star", "Zehn Abenteuer", "Ten adventures"),
        ("m-adv-25", "adventure", 25, 80, "", "Fünfundzwanzig Reisen", "Twenty-five trips"),
        ("m-cloth", "clothing", 3, 20, "", "Drei Kleidungsstücke", "Three pieces of clothing"),
        ("m-friend", "friend", 1, 20, "", "Erster Mini-Freund", "First mini-friend"),
        ("m-friends-3", "friend", 3, 35, "", "Drei Mini-Freunde", "Three mini-friends"),
        ("m-places-3", "place", 3, 30, "", "Drei Orte", "Three places"),
        ("m-places-10", "place", 10, 100, "hat-star", "Alle zehn Orte", "All ten places"),
        ("m-journal-7", "journal", 7, 30, "", "Sieben Tagebucheinträge", "Seven journal entries"),
    ]
    rows = []
    for qid, metric, goal, sparks, title_de, title_en, detail_de, detail_en in daily:
        rows.append({
            "id": qid, "kind": "daily", "metric": metric, "goal": goal, "rewardSparks": sparks, "rewardItemID": "",
            "title": loc(title_de, title_en), "detail": loc(detail_de, detail_en),
        })
    details = {
        "m-habits-10": ("Zehn gültige Abschlüsse insgesamt.", "Ten valid completions in total."),
        "m-streak-3": ("Drei Tage in Folge etwas geschafft.", "Something finished three days in a row."),
        "m-streak-7": ("Eine Woche am Stück.", "A week in a row."),
        "m-adv-1": ("Eine Geschichte zu Ende gehört.", "One story heard through."),
        "m-adv-10": ("Zehn Rückkehren.", "Ten returns."),
        "m-adv-25": ("Der Weg wird vertraut.", "The road grows familiar."),
        "m-cloth": ("Drei Teile im Schrank, Starter zählen nicht allein.", "Three pieces in the wardrobe."),
        "m-friend": ("Ein Ei ist aufgegangen.", "An egg has opened."),
        "m-friends-3": ("Drei Begleiter, Dopplungen zählen.", "Three companions, duplicates count."),
        "m-places-3": ("Drei Orte sind offen.", "Three places are open."),
        "m-places-10": ("Die Karte ist vollständig.", "The map is complete."),
        "m-journal-7": ("Sieben Einträge, nicht sieben Meisterwerke.", "Seven entries, not seven masterpieces."),
    }
    for qid, metric, goal, sparks, reward, title_de, title_en in miles:
        dde, den = details[qid]
        rows.append({
            "id": qid, "kind": "milestone", "metric": metric, "goal": goal, "rewardSparks": sparks, "rewardItemID": reward,
            "title": loc(title_de, title_en), "detail": loc(dde, den),
        })
    return rows


def events():
    spec = [
        ("spring", 3, 20, 4, 12, "Frühlingserwachen", "Spring Awakening", "Knospen, weiches Licht, erste Wege nach draußen.", "Buds, soft light, first paths outside.", "habits", 5, "adventure", 2, "decor-blossom"),
        ("cherry", 4, 13, 4, 27, "Blütenwoche", "Petal Week", "Rosa Luft im Kirschblütenpark.", "Pink air in Cherry Park.", "adventure", 2, "mood", 3, "decor-petal"),
        ("honey", 2, 10, 2, 16, "Honigmond", "Honey Moon", "Eine kurze Woche für kleine Freundlichkeiten.", "A short week for small kindnesses.", "journal", 2, "habits", 4, "bow-honeyweek"),
        ("summer", 6, 21, 7, 12, "Sommerlicht", "Summer Light", "Lange Tage und warme Wege.", "Long days and warm paths.", "adventure", 3, "movement", 2, "decor-sun"),
        ("autumn", 10, 1, 10, 20, "Laternenabend", "Lantern Evening", "Fenster bleiben ein bisschen länger hell.", "Windows stay bright a little longer.", "journal", 3, "breath", 2, "decor-lantern"),
        ("harvest", 9, 15, 9, 30, "Herbstmarkt", "Harvest Market", "Sammeln, ohne zu hetzen.", "Gathering, without rushing.", "habits", 6, "adventure", 2, "scarf-leaf"),
        ("winter", 12, 1, 12, 31, "Winterstern", "Winter Star", "Kakao, Schnee und langsame Abende.", "Cocoa, snow, and slow evenings.", "mood", 4, "adventure", 3, "decor-snow"),
        ("newyear", 1, 1, 1, 7, "Neujahrsfunken", "New Year Sparks", "Ein leiser Anfang, kein Vorsatzdruck.", "A quiet beginning, no pressure to resolve.", "journal", 1, "habits", 3, "pin-spark"),
    ]
    rows = []
    for eid, sm, sd, em, ed, de, en, bde, ben, m1, g1, m2, g2, reward in spec:
        rows.append({
            "id": eid,
            "startMonth": sm, "startDay": sd, "endMonth": em, "endDay": ed,
            "title": loc(de, en),
            "blurb": loc(bde, ben),
            "tasks": [
                {"id": f"{eid}-a", "metric": m1, "goal": g1, "rewardSparks": 30, "rewardItemID": reward, "title": loc(f"{de}: erster Schritt", f"{en}: first step")},
                {"id": f"{eid}-b", "metric": m2, "goal": g2, "rewardSparks": 40, "rewardItemID": "", "title": loc(f"{de}: zweiter Schritt", f"{en}: second step")},
                {"id": f"{eid}-c", "metric": "adventure", "goal": 1, "rewardSparks": 20, "rewardItemID": "", "title": loc("Ein Fest-Abenteuer", "One festival adventure")},
            ],
        })
    return rows


def prompts():
    themes = [
        ("gratitude", "Dankbarkeit", "Gratitude", [
            ("Ein kleiner Dank", "A small thanks", "Wofür bist du heute leise dankbar?", "What are you quietly thankful for today?"),
            ("Jemand", "Someone", "Wer hat dir etwas Leichtes gegeben?", "Who gave you something light?"),
            ("Ein Gegenstand", "An object", "Welcher Gegenstand hat dir geholfen?", "Which object helped you?"),
        ]),
        ("worth", "Selbstwert", "Self-worth", [
            ("Ein Satz über dich", "A sentence about you", "Was darfst du dir heute zugestehen?", "What may you allow yourself today?"),
            ("Langsam ist gültig", "Slow still counts", "Wo war langsam sein genug?", "Where was going slowly enough?"),
            ("Rund und richtig", "Round and right", "Was an dir muss nicht kleiner werden?", "What about you does not need to shrink?"),
        ]),
        ("stress", "Stressbewältigung", "Stress care", [
            ("Was drückt", "What presses", "Was liegt gerade schwer, in einem Satz?", "What feels heavy right now, in one sentence?"),
            ("Was kann warten", "What can wait", "Was muss heute nicht fertig werden?", "What does not have to be finished today?"),
            ("Eine Erleichterung", "One relief", "Was würde den nächsten Schritt kleiner machen?", "What would make the next step smaller?"),
        ]),
        ("day", "Tagesrückblick", "Day review", [
            ("Ein Moment", "One moment", "Welcher Moment darf bleiben?", "Which moment may stay?"),
            ("Ein Abschied", "One goodbye", "Was darf der Tag mitnehmen?", "What may the day take with it?"),
            ("Morgen", "Tomorrow", "Was wäre ein winziger Anfang?", "What would be a tiny beginning?"),
        ]),
        ("mind", "Achtsamkeit", "Mindfulness", [
            ("Im Raum", "In the room", "Was siehst du, ohne es zu bewerten?", "What do you see, without judging it?"),
            ("Im Körper", "In the body", "Wo ist es gerade warm oder ruhig?", "Where is it warm or quiet right now?"),
            ("Ein Atemzug", "One breath", "Wie fühlt sich der letzte Ausatem an?", "How does the last exhale feel?"),
        ]),
        ("motive", "Motivation", "Motivation", [
            ("Ein Grund", "One reason", "Wofür lohnt sich ein kleiner Schritt?", "What makes a small step worth it?"),
            ("Schon geschafft", "Already done", "Was hast du heute schon getan?", "What have you already done today?"),
            ("Hilfe", "Help", "Welche Hilfe wäre freundlich, nicht groß?", "What help would be kind, not grand?"),
        ]),
        ("feel", "Gefühle", "Feelings", [
            ("Benennen", "Naming", "Welches Gefühl ist am lautesten?", "Which feeling is the loudest?"),
            ("Daneben", "Beside it", "Welches Gefühl sitzt leise daneben?", "Which feeling sits quietly beside it?"),
            ("Ort", "Place", "Wo im Körper merkst du es?", "Where in the body do you notice it?"),
        ]),
    ]
    rows = []
    for tid, de_theme, en_theme, items_ in themes:
        for index, (tde, ten, bde, ben) in enumerate(items_, start=1):
            rows.append({"id": f"{tid}-{index}", "theme": tid, "title": loc(tde, ten), "body": loc(bde, ben)})
    return rows


def exercises():
    data = [
        ("stretch", 4, "Sanftes Strecken", "Gentle stretch", [
            ("Steh oder sitz bequem. Die Füße spürst du auf dem Boden.", "Stand or sit comfortably. Feel your feet on the floor."),
            ("Heb die Arme nur so hoch, wie es angenehm ist.", "Lift your arms only as high as feels all right."),
            ("Lass sie langsam wieder sinken.", "Let them sink slowly again."),
            ("Schüttle die Hände einmal aus.", "Shake your hands out once."),
        ]),
        ("shoulders", 3, "Schultern", "Shoulders", [
            ("Zieh die Schultern zu den Ohren.", "Draw the shoulders toward the ears."),
            ("Halt kurz, ohne die Luft anzuhalten.", "Hold briefly, without holding your breath."),
            ("Lass sie fallen und spür das Gewicht.", "Let them drop and feel the weight."),
        ]),
        ("break", 3, "Bewegungspause", "Movement break", [
            ("Steh auf, wenn das geht.", "Stand up, if that is possible."),
            ("Geh drei Schritte, oder tritt auf der Stelle.", "Take three steps, or march in place."),
            ("Dreh dich einmal langsam um.", "Turn around once, slowly."),
        ]),
        ("neck", 3, "Nacken", "Neck", [
            ("Blick geradeaus.", "Look straight ahead."),
            ("Neig den Kopf nur ein kleines Stück zur Seite.", "Tilt the head only a little to one side."),
            ("Wechsel die Seite und komm zurück zur Mitte.", "Change sides and return to the middle."),
        ]),
        ("hands", 2, "Hände", "Hands", [
            ("Öffne die Hände weit.", "Open the hands wide."),
            ("Schließ sie zur lockeren Faust und öffne wieder.", "Close them into a loose fist and open again."),
        ]),
        ("rest", 4, "Ausruhen", "Resting", [
            ("Setz oder leg dich so, wie es trägt.", "Sit or lie in a way that supports you."),
            ("Lass den Kiefer locker.", "Let the jaw soften."),
            ("Ein Ausatem länger als der Einatem.", "One exhale longer than the inhale."),
            ("Öffne die Augen, wenn du magst.", "Open your eyes when you like."),
        ]),
    ]
    rows = []
    for eid, minutes, de, en, steps in data:
        rows.append({
            "id": eid,
            "minutes": minutes,
            "title": loc(de, en),
            "steps": [loc(a, b) for a, b in steps],
        })
    return rows


def write_json():
    RES.mkdir(parents=True, exist_ok=True)
    content = {
        "places": [place_obj(row) for row in PLACES],
        "stories": stories(),
        "items": items(),
        "friends": friends(),
        "quests": quests(),
        "events": events(),
        "prompts": prompts(),
        "exercises": exercises(),
    }
    (RES / "content-shell.json").write_text(json.dumps(content, ensure_ascii=False, indent=2), encoding="utf-8")
    (RES / "l10n-shell.json").write_text(json.dumps(S, ensure_ascii=False, indent=2), encoding="utf-8")
    catalog = {"sourceLanguage": "de", "version": "1.0", "strings": {}}
    for key, row in sorted(S.items()):
        catalog["strings"][key] = {
            "extractionState": "manual",
            "localizations": {
                "de": {"stringUnit": {"state": "translated", "value": row["de"]}},
                "en": {"stringUnit": {"state": "translated", "value": row["en"]}},
            },
        }
    (ROOT / "Gooby" / "Localizable.xcstrings").write_text(json.dumps(catalog, ensure_ascii=False, indent=2), encoding="utf-8")
    print("stories", len(content["stories"]), "places", len(content["places"]), "items", len(content["items"]), "strings", len(S))


def write_wav(path, samples, rate=16000):
    path.parent.mkdir(parents=True, exist_ok=True)
    fade = 400
    for i in range(fade):
        k = i / fade
        samples[i] *= k
        samples[-1 - i] *= k
    with wave.open(str(path), "w") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(rate)
        frames = bytearray()
        for sample in samples:
            value = max(-32767, min(32767, int(sample * 12000)))
            frames += struct.pack("<h", value)
        handle.writeframes(frames)


def lowpass(src, keep):
    out = []
    acc = 0.0
    for sample in src:
        acc = acc * (1 - keep) + sample * keep
        out.append(acc)
    return out


def sounds():
    rate = 16000
    seconds = 5
    count = rate * seconds
    rng = random.Random(7)
    noise = [rng.uniform(-1, 1) for _ in range(count)]
    soft = lowpass(noise, 0.08)
    rain = lowpass(noise, 0.35)
    wind_base = lowpass(noise, 0.12)
    fire_base = lowpass(noise, 0.4)
    ocean = []
    wind = []
    fire = []
    forest = soft[:]
    nature = []
    for i in range(count):
        t = i / rate
        ocean.append(math.sin(2 * math.pi * 0.18 * t) * 0.4 + soft[i] * 0.35)
        wind.append(wind_base[i] * (0.55 + 0.45 * math.sin(2 * math.pi * 0.08 * t)))
        crackle = rng.uniform(0.3, 1.0) if rng.random() < 0.012 else 0.0
        fire.append(fire_base[i] * 0.2 + crackle * 0.7)
        note = [262, 294, 330, 392, 440][int(t / 0.7) % 5]
        nature.append(math.sin(2 * math.pi * note * t) * 0.06 * (0.5 + 0.5 * math.sin(2 * math.pi * 0.2 * t)) + soft[i] * 0.04)
    chirps = random.Random(11)
    placed = 0
    while placed < 8:
        start = chirps.randrange(0, count - rate)
        freq = chirps.choice([523, 587, 659, 784])
        length = int(rate * 0.16)
        for j in range(length):
            forest[start + j] += math.sin(2 * math.pi * freq * j / rate) * 0.09 * (1 - j / length)
        placed += 1
    write_wav(AUDIO / "sound-rain.wav", rain)
    write_wav(AUDIO / "sound-ocean.wav", ocean)
    write_wav(AUDIO / "sound-forest.wav", forest)
    write_wav(AUDIO / "sound-wind.wav", wind)
    write_wav(AUDIO / "sound-fire.wav", fire)
    write_wav(AUDIO / "sound-nature.wav", nature)
    sys_path = str(Path(__file__).resolve().parent)
    if sys_path not in sys.path:
        sys.path.insert(0, sys_path)
    try:
        from make_soundscape_loops import write_all
        write_all(AUDIO)
    except ImportError as exc:
        print("soundscape loops left as-is:", exc)


def icon():
    size = 1024

    def pix(x, y):
        # pink rounded card
        nx = (x - 512) / 512
        ny = (y - 512) / 512
        if max(abs(nx), abs(ny)) > 0.92 and (abs(nx) ** 8 + abs(ny) ** 8) > 1:
            return (255, 214, 231)
        # ears
        for side in (-0.28, 0.28):
            ex = (nx - side) / 0.16
            ey = (ny + 0.55) / 0.38
            if ex * ex + ey * ey < 1:
                inner = ((nx - side) / 0.08) ** 2 + ((ny + 0.5) / 0.22) ** 2
                if inner < 1:
                    return (255, 194, 214)
                return (255, 246, 234)
        # head
        hx = nx / 0.46
        hy = (ny + 0.08) / 0.42
        if hx * hx + hy * hy < 1:
            # cheeks
            for side in (-0.22, 0.22):
                if ((nx - side) / 0.1) ** 2 + ((ny - 0.02) / 0.07) ** 2 < 1:
                    return (255, 183, 204)
            # eyes
            for side in (-0.14, 0.14):
                ex = (nx - side) / 0.09
                ey = (ny + 0.08) / 0.1
                if ex * ex + ey * ey < 1:
                    if ((nx - side + 0.03) / 0.03) ** 2 + ((ny + 0.12) / 0.03) ** 2 < 1:
                        return (255, 255, 255)
                    return (42, 36, 56)
            # nose
            if (nx / 0.035) ** 2 + ((ny - 0.08) / 0.025) ** 2 < 1:
                return (255, 142, 171)
            # mouth
            if abs(nx) < 0.08 and 0.1 < ny < 0.16:
                return (255, 142, 171)
            shade = 0
            if nx > 0.1:
                shade = 12
            return (255 - shade, 246 - shade, 234 - shade)
        # body
        bx = nx / 0.5
        by = (ny - 0.38) / 0.34
        if bx * bx + by * by < 1:
            return (255, 236, 214)
        return (255, 214, 231)

    raw = bytearray()
    for y in range(size):
        raw.append(0)
        for x in range(size):
            raw.extend(pix(x, y))

    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    ICON.write_bytes(png)


def check_keys():
    import re
    needed = set()
    pat = re.compile(r'\b(?:t|tf)\("([A-Za-z0-9_.]+)"')
    for path in (ROOT / "Gooby").rglob("*.swift"):
        needed.update(pat.findall(path.read_text()))
    dynamic = []
    for prefix in ["onb.goal.", "onb.habit.", "cat.", "recur.", "slot.", "shop.", "rarity.", "pet.stage.", "stat.", "mood.level.", "mood.tag.", "anim.", "breath.", "sound.", "ground.sense.", "ground.sense.help.", "ground.card.", "priority."]:
        dynamic.append(prefix)
    missing = [key for key in sorted(needed) if key not in S and "." in key]
    # interpolated calls are not in needed if they contain backslash; static ones must exist
    missing = [key for key in missing if key in S or True]
    missing = [key for key in sorted(needed) if key not in S and not key.endswith(".")]
    if missing:
        raise SystemExit("missing strings: " + ", ".join(missing))
    story_rows = stories()
    if len(story_rows) < 50:
        raise SystemExit(f"only {len(story_rows)} stories")
    if len(PLACES) < 10:
        raise SystemExit("places")
    known = {disc["id"] for row in PLACES for disc in row[-1]}
    for story in story_rows:
        for option in story["choices"]:
            found = option["discoveryID"]
            if found and found not in known:
                raise SystemExit("unknown discovery " + found)
    event_ids = {row["id"] for row in events()}
    catalog_items = items()
    ids = [row["id"] for row in catalog_items]
    if len(ids) != len(set(ids)):
        raise SystemExit("duplicate item id")
    for row in catalog_items:
        if row["seasonalEvent"] and row["seasonalEvent"] not in event_ids:
            raise SystemExit("unknown event " + row["seasonalEvent"])
    for row in S.values():
        if not row["de"] or not row["en"]:
            raise SystemExit("empty translation")


if __name__ == "__main__":
    check_keys()
    write_json()
    sounds()
    icon()
    print("content ready")

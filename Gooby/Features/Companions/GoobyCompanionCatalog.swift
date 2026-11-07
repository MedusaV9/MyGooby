import Foundation

enum GoobyCompanionCatalog {
    static let species: [GoobyCompanionSpeciesDefinition] = [
        make("chick", "Küken", "Chick", "Ein rundes Küken, das bei jedem kleinen Schritt mitwippt.", "A round chick that bobs along with every small step.", "common", "hop", nil, "#FFE08A", "#FFB25B"),
        make("mini-cloud", "Mini-Wolke", "Mini Cloud", "Eine kleine Wolke mit einem sehr ruhigen Lächeln.", "A little cloud with a very calm smile.", "common", "drift", nil, "#FFFFFF", "#C8E9FF"),
        make("baby-dragon", "Babydrache", "Baby Dragon", "Winzige Flügel, große Augen und überhaupt kein Feuer.", "Tiny wings, huge eyes, and no fire at all.", "rare", "flutter", nil, "#B7E8C8", "#7DDE9A"),
        make("fox", "Fuchs", "Fox", "Ein plüschiger Fuchs, der gern neben Gewohnheiten sitzt.", "A plush fox who likes to sit beside habits.", "uncommon", "hop", nil, "#FF9B6A", "#FFF1E6"),
        make("star-being", "Sternenwesen", "Star Being", "Ein weiches Sternchen, das leise vor sich hin funkelt.", "A soft little star that glitters quietly.", "rare", "twinkle", nil, "#FFE7AD", "#D3C2FF"),
        make("baby-penguin", "Baby-Pinguin", "Baby Penguin", "Watschelt ernst und ist dabei sehr stolz auf dich.", "Waddles seriously and is very proud of you.", "uncommon", "waddle", nil, "#3D3656", "#FFF8EF"),
        make("bear", "Bär", "Bear", "Ein runder Bär, der Umarmungen sammelt.", "A round bear who collects hugs.", "common", "bob", nil, "#E0B090", "#FFD6E7"),
        make("mini-cat", "Mini-Katze", "Mini Cat", "Eine kleine Katze mit großen Wangen und ruhigem Blick.", "A tiny cat with big cheeks and a quiet gaze.", "common", "hop", nil, "#FFD6B3", "#FFD6E7"),
        make("ghost", "Geist", "Ghost", "Ein freundlicher Geist, der nur ein bisschen durchsichtig ist.", "A friendly ghost who is only a little see-through.", "rare", "drift", nil, "#E4DCFF", "#D3C2FF"),
        make("mini-unicorn", "Mini-Einhorn", "Mini Unicorn", "Horn, Mähne und ganz viel Geduld für deinen Alltag.", "A horn, a mane, and plenty of patience for your day.", "epic", "twinkle", nil, "#FFF8EF", "#FF8FB8"),
        make("moon-being", "Mondwesen", "Moon Being", "Ein Mondgesicht, das abends besonders wach ist.", "A moon face that is especially awake in the evening.", "epic", "drift", nil, "#C8E9FF", "#FFE7AD"),
        make("mushroom-friend", "Pilzfreund", "Mushroom Friend", "Roter Hut, weiche Punkte, keine Eile.", "A red cap, soft spots, and no hurry.", "uncommon", "bob", nil, "#FF8AA0", "#FFF8EF"),
        make("blossom-beetle", "Blütenkäfer", "Blossom Beetle", "Trägt ein Blütenblatt wie einen Rucksack.", "Wears a petal like a little backpack.", "rare", "flutter", "spring-meadow", "#FFD6E7", "#3D3656"),
        make("rainbow-wisp", "Regenbogenwisp", "Rainbow Wisp", "Ein farbiger Hauch, der nach dem Regen bleibt.", "A colorful wisp that stays after the rain.", "epic", "drift", "rainbow-week", "#D3C2FF", "#FFE7AD"),
        make("picnic-bee", "Picknickbiene", "Picnic Bee", "Summt leise und teilt den Sonnenschein.", "Hums softly and shares the sunshine.", "uncommon", "flutter", "summer-picnic", "#FFE7AD", "#3D3656"),
        make("lantern-sprite", "Laternengeistchen", "Lantern Sprite", "Ein kleines Licht mit einem sehr höflichen Gesicht.", "A little light with a very polite face.", "rare", "twinkle", "lantern-eve", "#FFB25B", "#FFF8EF"),
        make("snow-puff", "Schneepuff", "Snow Puff", "Ein runder Schneeball, der nicht schmilzt, solange du da bist.", "A round snow puff that does not melt while you are here.", "uncommon", "bob", "winter-warmth", "#F4FBFF", "#C8E9FF")
    ]

    static var eggPool: [GoobyCompanionSpeciesDefinition] {
        species.filter { $0.seasonalEventID == nil }
    }

    private static func make(
        _ id: String,
        _ nameDE: String,
        _ nameEN: String,
        _ storyDE: String,
        _ storyEN: String,
        _ rarity: String,
        _ animation: String,
        _ eventID: String?,
        _ primary: String,
        _ secondary: String
    ) -> GoobyCompanionSpeciesDefinition {
        GoobyCompanionSpeciesDefinition(
            id: id,
            nameDE: nameDE,
            nameEN: nameEN,
            storyDE: storyDE,
            storyEN: storyEN,
            rarity: rarity,
            animation: animation,
            seasonalEventID: eventID,
            primaryHex: primary,
            secondaryHex: secondary
        )
    }
}

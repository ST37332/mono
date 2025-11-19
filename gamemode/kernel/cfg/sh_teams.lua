mono.Faction:Add{
    name = "Citizens",
    color = Color(0, 107, 0, 255),
    sortOrder = 100,
}

mono.Faction:Add{
    name = "Civil Protection",
    color = Co  lor(25, 25, 112, 255),
    sortOrder = 10,
}

mono.Faction:Add{
    name = "Gangsters",
    color = Color(139, 0, 0, 255),
    sortOrder = 50,
}

mono.Faction:Add{
    name = "Medics",
    color = Color(255, 255, 255, 255),
    sortOrder = 20,
}

TEAM_CITIZEN = mono.Jobs:Add("Citizen", {
    color = Color(20, 150, 20, 255),
    model = {
        "models/player/Group01/Female_01.mdl",
        "models/player/Group01/Female_02.mdl",
        "models/player/Group01/Female_03.mdl",
        "models/player/Group01/Female_04.mdl",
        "models/player/Group01/Female_06.mdl",
        "models/player/group01/male_01.mdl",
        "models/player/Group01/Male_02.mdl",
        "models/player/Group01/male_03.mdl",
        "models/player/Group01/Male_04.mdl",
        "models/player/Group01/Male_05.mdl",
        "models/player/Group01/Male_06.mdl",
        "models/player/Group01/Male_07.mdl",
        "models/player/Group01/Male_08.mdl",
        "models/player/Group01/Male_09.mdl"
    },
    description = [[Обычный гражданин города. Вы можете работать, строить и торговать с другими игроками.]],
    weapons = {},
    command = "citizen",
    max = 0,
    salary = 45,
    haveWeapon = false,
    demote = false,
    faction = "Citizens",
})

TEAM_POLICE = mono.Jobs:Add("Police Officer", {
    color = Color(25, 25, 170, 255),
    model = {
        "models/player/police.mdl",
        "models/player/police_fem.mdl"
    },
    description = [[Сотрудник правоохранительных органов. Ваша задача - поддерживать порядок и соблюдение законов.]],
    weapons = {"arrest_stick", "unarrest_stick", "stunstick", "weapon_checker"},
    command = "police",
    max = 4,
    salary = 75,
    haveWeapon = true,
    demote = true,
    faction = "Civil Protection",
})

TEAM_GANGSTER = mono.Jobs:Add("Gangster", {
    color = Color(150, 0, 0, 255),
    model = {
        "models/player/Group03/Female_01.mdl",
        "models/player/Group03/Male_01.mdl"
    },
    description = [[Член преступной группировки. Занимайтесь нелегальной деятельностью, но будьте осторожны с полицией.]],
    weapons = {"weapon_pistol"},
    command = "gangster",
    max = 3,
    salary = 60,
    haveWeapon = true,
    demote = true,
    faction = "Gangsters",
})

TEAM_MEDIC = mono.Jobs:Add("Medic", {
    color = Color(255, 255, 255, 255),
    model = {
        "models/player/kleiner.mdl",
        "models/player/mossman.mdl"
    },
    description = [[Медицинский работник. Лечите и воскрешайте других игроков за деньги.]],
    weapons = {"med_kit"},
    command = "medic",
    max = 2,
    salary = 65,
    haveWeapon = false,
    demote = true,
    faction = "Medics",
})

return function(ctx)
    local Workspace = ctx.Workspace
    local ReplicatedStorage = ctx.ReplicatedStorage

    local Database = {}

    local function normalizeKey(text)
        return string.lower(tostring(text or "")):gsub("[^%w]", "")
    end

    local function normalizeWeaponName(name)
        return normalizeKey(name)
    end

    Database.normalizeKey = normalizeKey
    Database.normalizeWeaponName = normalizeWeaponName

    local MAP_DATABASE = {
        PrivateCottage = {
            CanonicalName = "Private Cottage",
            Mode = "Juggernaut",
            Aliases = {
                "Private Cottage", "PrivateCottage", "1999Private Cottage", "1999PrivateCottage",
                "Veronika Cottage", "Eagle's Nest", "Eagles Nest",
            },
            Roles = {
                Juggernaut = "Juggernaut: Former Paratrooper",
                Wave1 = "Robber",
                Wave2 = "Politsiya",
            },
            AllowedRoles = {
                ["Juggernaut: Former Paratrooper"] = true,
                ["Robber"] = true,
                ["Politsiya"] = true,
            },
        },

        ForlornCottage = {
            CanonicalName = "Forlorn Cottage",
            Mode = "Juggernaut",
            Aliases = {
                "Forlorn Cottage", "ForlornCottage",
            },
            Roles = {
                Juggernaut = "Juggernaut: Former Paratrooper",
                Wave1 = "Robber",
                Wave2 = "Politsiya",
            },
            AllowedRoles = {
                ["Juggernaut: Former Paratrooper"] = true,
                ["Robber"] = true,
                ["Politsiya"] = true,
            },
        },

        RaggedWoodsCampgrounds = {
            CanonicalName = "Ragged Woods Campgrounds",
            Mode = "Juggernaut",
            Aliases = {
                "Ragged Woods Campgrounds", "Ragged Wood Campgrounds", "RaggedWoodsCampgrounds",
                "RaggedWoodCampgrounds", "Campgrounds", "Campsite",
            },
            Roles = {
                Juggernaut = "Juggernaut: The Bear",
                Wave1 = "Bystander",
                Wave2 = "Foresters",
            },
            AllowedRoles = {
                ["Juggernaut: The Bear"] = true,
                ["Bystander"] = true,
                ["Foresters"] = true,
            },
        },

        WinterOffensive = {
            CanonicalName = "Winter Offensive",
            Mode = "Juggernaut",
            Aliases = {
                "Winter Offensive", "WinterOffensive", "NUWinterOffensive", "NUwinterOffensive",
                "NUWINTEROFFENCE", "Noobic Union Winter Offensive", "Virisovka", "Battle of Virisovka",
            },
            Roles = {
                Juggernaut = "Juggernaut: Sharpshooter",
                Wave1 = "NETO Soldier",
                Wave2 = "NETO Reinforcements",
                SniperReinforcement = "Sharpshooter",
            },
            AllowedRoles = {
                ["Juggernaut: Sharpshooter"] = true,
                ["Sharpshooter"] = true,
                ["NETO Soldier"] = true,
                ["NETO Reinforcements"] = true,
            },
        },

        KualtonAirport = {
            CanonicalName = "Kualton Airport",
            Mode = "Juggernaut",
            Aliases = {
                "Kualton Airport", "KualtonAirport", "Hong Huan Kualton Airport", "Kualton Evacuation Zone",
            },
            Roles = {
                Juggernaut = "Juggernaut: APC Driver",
                Wave1 = "Survivor",
                Wave2 = "SEATO Reinforcements",
            },
            AllowedRoles = {
                ["Juggernaut: APC Driver"] = true,
                ["Survivor"] = true,
                ["SEATO Reinforcements"] = true,
            },
        },

        CrownPMCWarehouse = {
            CanonicalName = "Crown PMC Warehouse",
            Mode = "Juggernaut",
            Aliases = {
                "Crown PMC Warehouse", "CrownPMCWarehouse", "CPMC Warehouse", "CPMCWarehouse",
                "CPMPC Warehouse", "NoobicUnionOffices", "1999 Noobic Union Offices", "Noobic Union Offices",
                "Abandoned Office",
            },
            Roles = {
                Juggernaut = "Juggernaut: Stanislav / Mstislav",
                Wave1 = "Politsiya",
                Wave2 = "Politsiya",
            },
            AllowedRoles = {
                ["Juggernaut: Stanislav / Mstislav"] = true,
                ["Politsiya"] = true,
            },
        },

        Monobank = {
            CanonicalName = "Monobank",
            Mode = "Juggernaut",
            Aliases = {
                "Monobank", "MonoBank", "Downtown Nubizkyl", "DowntownNubizkyl", "Downtown Bank",
            },
            Roles = {
                Juggernaut = "Juggernaut: Alexei Tarasov",
                Wave1 = "Survivor",
                Wave2 = "Politsiya",
            },
            AllowedRoles = {
                ["Juggernaut: Alexei Tarasov"] = true,
                ["Survivor"] = true,
                ["Politsiya"] = true,
            },
        },

        HighRise = {
            CanonicalName = "High Rise",
            Mode = "Juggernaut",
            Aliases = {
                "High Rise", "Highrise", "Highrise Party", "Serebryakov Highrise",
            },
            Roles = {
                Juggernaut = "Juggernaut: Viadimir Koltsov",
                Wave1 = "Survivor",
                Wave2 = "Politsiya",
            },
            AllowedRoles = {
                ["Juggernaut: Viadimir Koltsov"] = true,
                ["Juggernaut: Alexei Tarasov"] = true,
                ["Juggernaut: Ryman Yegorova"] = true,
                ["Survivor"] = true,
                ["Politsiya"] = true,
            },
        },

        Office = {
            CanonicalName = "Office",
            Mode = "Juggernaut",
            Aliases = {
                "Office", "The Office", "Office Revamp", "Highrise Communications Office",
                "HighRise Communications Nubizkyl", "Palantir Headquarters",
            },
            Roles = {
                Juggernaut = "Juggernaut: Ryman Yegorova",
                Wave1 = "Survivor",
                Wave2 = "Politsiya",
            },
            AllowedRoles = {
                ["Juggernaut: Ryman Yegorova"] = true,
                ["Juggernaut: Alexei Tarasov"] = true,
                ["Juggernaut: Viadimir Koltsov"] = true,
                ["Juggernaut: Stanislav / Mstislav"] = true,
                ["Survivor"] = true,
                ["Politsiya"] = true,
            },
        },

        CampCrystalWaters = {
            CanonicalName = "Camp Crystal Waters",
            Mode = "Juggernaut",
            Aliases = {
                "Camp Crystal Waters", "CampCrystalWaters", "Abandoned Mansion Jugg", "AbandonedMansionJugg",
            },
            Roles = {
                Juggernaut = "Juggernaut: Mason Jr.",
                Wave1 = "Survivor",
                Wave2 = "Politsiya",
            },
            AllowedRoles = {
                ["Juggernaut: Mason Jr."] = true,
                ["Survivor"] = true,
                ["Politsiya"] = true,
            },
        },

        NoskowAlleywayHell = {
            CanonicalName = "NoskowAlleyway HELL",
            Mode = "Juggernaut",
            Aliases = {
                "NoskowAlleyway HELL", "NoskowAlleywayHELL", "Alleyway Hell",
            },
            Roles = {
                Juggernaut = "Juggernaut: Glaz",
                Wave1 = "Survivor",
                Wave2 = "Politsiya",
            },
            AllowedRoles = {
                ["Juggernaut: Glaz"] = true,
                ["Survivor"] = true,
            },
        },

        AbandonedFactory = {
            CanonicalName = "Abandoned Factory",
            Mode = "Scav War",
            Aliases = {
                "Abandoned Factory", "AbandonedFactory",
            },
            Roles = {
                Default = "Scavenger",
            },
            AllowedRoles = {
                ["Scavenger"] = true,
            },
        },

        KuaiPanStreets = {
            CanonicalName = "Kuai Pan Streets",
            Mode = "Scav War",
            Aliases = {
                "Kuai Pan Streets", "KuaiPanStreets", "Kuai Pan", "KuaiPan", "Kuaipan", "KuanTai Streets",
            },
            Roles = {
                Default = "Scavenger",
            },
            AllowedRoles = {
                ["Scavenger"] = true,
            },
        },

        AbandonedWarehouse = {
            CanonicalName = "Abandoned Warehouse",
            Mode = "Team War",
            Aliases = {
                "Abandoned Warehouse", "AbandonedWarehouse", "Warehouse", "Abandoned Building",
                "AbandonedBuilding", "Abandoned Building Revamp",
            },
            Factions = {
                "Street Gang", "Heist Crew", "Bratva",
            },
            AllowedRoles = {
                ["Sharpshooter"] = true,
                ["Team War"] = true,
            },
        },

        NubizkylCity = {
            CanonicalName = "Nubizkyl City",
            Mode = "Team War",
            Aliases = {
                "Nubizkyl City", "NubizkylCity", "NubzikylCity", "Nubizkyl",
            },
            Factions = {
                "Bratva", "Nubagami",
            },
            AllowedRoles = {
                ["Sharpshooter"] = true,
                ["Team War"] = true,
            },
        },

        RodinskayaStreet = {
            CanonicalName = "Rodinskaya Street",
            Mode = "Team War",
            Aliases = {
                "Rodinskaya Street", "RodinskayaStreet", "Rodinskya Street", "News Making", "NewsMaking",
            },
            Factions = {
                "Heist Crew", "STRELA",
            },
            AllowedRoles = {
                ["Sharpshooter"] = true,
                ["Team War"] = true,
            },
        },

        ForgottenGarages = {
            CanonicalName = "Forgotten Garages",
            Mode = "Team War",
            Aliases = {
                "Forgotten Garages", "ForgottenGarages",
            },
            Factions = {
                "The Trinity", "The Zoo",
            },
            AllowedRoles = {
                ["Sharpshooter"] = true,
                ["Team War"] = true,
            },
        },

        NoskowAlleyway = {
            CanonicalName = "Noskow Alleyway",
            Mode = "Team War",
            Aliases = {
                "Noskow Alleyway", "NoskowAlleyway", "Nuskow Alleyways", "Alleaywasy2",
            },
            Factions = {
                "Hooligans", "Hobos / Homeless",
            },
            AllowedRoles = {
                ["Sharpshooter"] = true,
                ["Team War"] = true,
            },
        },

        SvetonskiyOverpass = {
            CanonicalName = "Svetonskiy Overpass",
            Mode = "Team War",
            Aliases = {
                "Svetonskiy Overpass", "SvetonskiyOverpass", "Artemovsky Overpass", "ArtemovskyOverpass",
            },
            Factions = {
                "Noobic Union Armed Forces", "Royal Kingsland Army",
            },
            AllowedRoles = {
                ["Sharpshooter"] = true,
                ["Team War"] = true,
            },
        },

        ForgottenGasStation = {
            CanonicalName = "Forgotten Gas Station",
            Mode = "Team War",
            Aliases = {
                "Forgotten Gas Station", "ForgottenGasStation", "AbandonedGasStation",
            },
            Factions = {
                "The Politsiya", "The Trinity", "The Zoo",
            },
            AllowedRoles = {
                ["Sharpshooter"] = true,
                ["Team War"] = true,
            },
        },

        NoskowExchange = {
            CanonicalName = "Noskow Exchange",
            Mode = "Team War",
            Aliases = {
                "Noskow Exchange", "NoskowExchange", "NOEX Noskow Exchange", "Noskow Stock Exchange",
                "Noex Stock Exchange", "NOEX",
            },
            Factions = {
                "MNB", "Vanguardists", "STRELA",
            },
            AllowedRoles = {
                ["Sharpshooter"] = true,
                ["Team War"] = true,
            },
        },

        Sretenskaya = {
            CanonicalName = "Sretenskaya",
            Mode = "Team War",
            Aliases = {
                "Sretenskaya", "Sretenskayá", "Stretenskaya",
            },
            Factions = {
                "Worker's Army", "White Imperialist Movement",
            },
            AllowedRoles = {
                ["Sharpshooter"] = true,
                ["Team War"] = true,
            },
        },

        ChernayaZone = {
            CanonicalName = "Chernaya Zone",
            Mode = "Team War",
            Aliases = {
                "Chernaya Zone", "ChernayaZone",
            },
            Factions = {
                "Noobic Union Armed Forces", "Free Kaukasus Army",
            },
            AllowedRoles = {
                ["Sharpshooter"] = true,
                ["Team War"] = true,
            },
        },

        OperationRodinskaya = {
            CanonicalName = "Operation Rodinskaya",
            Mode = "Team War",
            Aliases = {
                "Operation Rodinskaya", "OperationRodinskaya",
            },
            Factions = {
                "ZONTIK Operators", "Amtavirus Mutants",
            },
            AllowedRoles = {
                ["Sharpshooter"] = true,
                ["Team War"] = true,
            },
        },

        DeadMenOverpass = {
            CanonicalName = "Dead Men Overpass",
            Mode = "Team War",
            Aliases = {
                "Dead Men Overpass", "DeadMenOverpass",
            },
            Factions = {
                "Noobic Union Armed Forces", "Royal Kingsland Army",
            },
            AllowedRoles = {
                ["Sharpshooter"] = true,
                ["Team War"] = true,
            },
        },

        PirozhokApartments = {
            CanonicalName = "Pirozhok Apartments",
            Mode = "Debt",
            Aliases = {
                "Pirozhok Apartments", "PirozhokApartments", "Apartments V2", "Apartments new",
                "NoobicUnion1999Apartments", "Noobic Union Apartments", "Apartments",
            },
            AllowedRoles = {
                ["Killer"] = true,
                ["Vigilante"] = true,
                ["Detective"] = true,
                ["Hero"] = true,
                ["Bystander"] = true,
            },
        },

        HouseParty = {
            CanonicalName = "House Party",
            Mode = "Debt",
            Aliases = {
                "House Party", "HouseParty", "House Party V4", "Haunted House", "HauntedHouse",
            },
            AllowedRoles = {
                ["Killer"] = true,
                ["Vigilante"] = true,
                ["Detective"] = true,
                ["Hero"] = true,
                ["Bystander"] = true,
            },
        },

        NubizkylMetroline = {
            CanonicalName = "Nubizkyl Metroline",
            Mode = "Debt",
            Aliases = {
                "Nubizkyl Metroline", "NubizkylMetroline", "Metro V3", "Metro v2", "Metro Station",
                "Metro Line Homicide", "Metro",
            },
            AllowedRoles = {
                ["Killer"] = true,
                ["Vigilante"] = true,
                ["Detective"] = true,
                ["Hero"] = true,
                ["Bystander"] = true,
            },
        },

        SmallFarmhouse = {
            CanonicalName = "Small Farmhouse",
            Mode = "Debt",
            Aliases = {
                "Small Farmhouse", "SmallFarmhouse", "NUSmallHouseFarm", "Small House Farm",
                "Farm v3", "Farm", "Farmhouse", "Farm House",
            },
            AllowedRoles = {
                ["Killer"] = true,
                ["Vigilante"] = true,
                ["Detective"] = true,
                ["Hero"] = true,
                ["Bystander"] = true,
            },
        },

        Penthouse = {
            CanonicalName = "Penthouse",
            Mode = "Debt",
            Aliases = {
                "Penthouse", "Rooftop Penthouse", "Penthouse new",
            },
            AllowedRoles = {
                ["Killer"] = true,
                ["Vigilante"] = true,
                ["Detective"] = true,
                ["Hero"] = true,
                ["Bystander"] = true,
            },
        },

        KovalevskyDiner = {
            CanonicalName = "Kovalevsky's Diner",
            Mode = "Debt",
            Aliases = {
                "Kovalevsky's Diner", "KovalevskyDiner", "Kovalevsky Dinner", "Yesyes", "Diner",
            },
            AllowedRoles = {
                ["Killer"] = true,
                ["Vigilante"] = true,
                ["Detective"] = true,
                ["Hero"] = true,
                ["Bystander"] = true,
            },
        },

        ResteyerokApartment = {
            CanonicalName = "Resteyerok Apartment",
            Mode = "Debt",
            Aliases = {
                "Resteyerok Apartment", "ResteyerokApartment", "Resteyerok Apartment Scamps",
                "ResteyerokApartmentScamps", "Resteryok Apartments", "Scamps",
            },
            AllowedRoles = {
                ["Killer"] = true,
                ["Vigilante"] = true,
                ["Detective"] = true,
                ["Hero"] = true,
                ["Bystander"] = true,
            },
        },

        TNUMinistryBuilding = {
            CanonicalName = "TNU Ministry Building",
            Mode = "Debt",
            Aliases = {
                "TNU Ministry Building", "TNUMinistryBuilding", "The Noobic Union Ministry",
                "TNU Ministry", "Ministry Building", "Ministry",
            },
            AllowedRoles = {
                ["Killer"] = true,
                ["Vigilante"] = true,
                ["Detective"] = true,
                ["Hero"] = true,
                ["Bystander"] = true,
            },
        },

        ThePagesCafe = {
            CanonicalName = "The Pages Café",
            Mode = "Debt",
            Aliases = {
                "The Pages Café", "The Pages Cafe", "PagesCafe", "PAGESCAFE",
            },
            AllowedRoles = {
                ["Killer"] = true,
                ["Vigilante"] = true,
                ["Detective"] = true,
                ["Hero"] = true,
                ["Bystander"] = true,
            },
        },

        FireStation14 = {
            CanonicalName = "Fire Station 14",
            Mode = "Debt",
            Aliases = {
                "Fire Station 14", "FireStation14",
            },
            AllowedRoles = {
                ["Killer"] = true,
                ["Vigilante"] = true,
                ["Detective"] = true,
                ["Hero"] = true,
                ["Bystander"] = true,
            },
        },

        TheseusFishingVessel = {
            CanonicalName = "Theseus Fishing Vessel",
            Mode = "Debt",
            Aliases = {
                "Theseus Fishing Vessel", "TheseusFishingVessel", "Fishing Vessel", "Theseus",
            },
            AllowedRoles = {
                ["Killer"] = true,
                ["Vigilante"] = true,
                ["Detective"] = true,
                ["Hero"] = true,
                ["Bystander"] = true,
            },
        },

        SanguanConstruction = {
            CanonicalName = "Sanguan Construction",
            Mode = "Debt",
            Aliases = {
                "Sanguan Construction", "SanguanConstruction",
            },
            AllowedRoles = {
                ["Killer"] = true,
                ["Vigilante"] = true,
                ["Detective"] = true,
                ["Hero"] = true,
                ["Bystander"] = true,
            },
        },

        TrinityDen = {
            CanonicalName = "Trinity Den",
            Mode = "Debt",
            Aliases = {
                "Trinity Den", "TrinityDen", "Nubagami Den", "NubagamiDen",
            },
            AllowedRoles = {
                ["Killer"] = true,
                ["Vigilante"] = true,
                ["Detective"] = true,
                ["Hero"] = true,
                ["Bystander"] = true,
            },
        },

        SuburbanNopan = {
            CanonicalName = "Suburban Nopan",
            Mode = "Debt",
            Aliases = {
                "Suburban Nopan", "SuburbanNopan",
            },
            AllowedRoles = {
                ["Killer"] = true,
                ["Vigilante"] = true,
                ["Detective"] = true,
                ["Hero"] = true,
                ["Bystander"] = true,
            },
        },

        RestStop = {
            CanonicalName = "Rest Stop",
            Mode = "Debt",
            Aliases = {
                "Rest Stop", "RestStop",
            },
            AllowedRoles = {
                ["Killer"] = true,
                ["Vigilante"] = true,
                ["Detective"] = true,
                ["Hero"] = true,
                ["Bystander"] = true,
            },
        },

        KharitonovResearchStation = {
            CanonicalName = "Kharitonov Research Station",
            Mode = "Debt",
            Aliases = {
                "Kharitonov Research Station", "KharitonovResearchStation",
            },
            AllowedRoles = {
                ["Killer"] = true,
                ["Vigilante"] = true,
                ["Detective"] = true,
                ["Hero"] = true,
                ["Bystander"] = true,
            },
        },

        MudzbillaEnterprises = {
            CanonicalName = "Mudzbilla Enterprises",
            Mode = "Debt",
            Aliases = {
                "Mudzbilla Enterprises", "MudzbillaEnterprises", "Mudzbillas' Enterprise",
            },
            AllowedRoles = {
                ["Killer"] = true,
                ["Vigilante"] = true,
                ["Detective"] = true,
                ["Hero"] = true,
                ["Bystander"] = true,
            },
        },

        StrugatskyPark = {
            CanonicalName = "Strugatsky Park",
            Mode = "Debt",
            Aliases = {
                "Strugatsky Park", "StrugatskyPark", "Pobeda Park", "PobedaPark",
            },
            AllowedRoles = {
                ["Killer"] = true,
                ["Vigilante"] = true,
                ["Detective"] = true,
                ["Hero"] = true,
                ["Bystander"] = true,
            },
        },

        GruzbazaWarehouse = {
            CanonicalName = "Gruzbaza Warehouse",
            Mode = "Debt",
            Aliases = {
                "Gruzbaza Warehouse", "Gruzbaza Warehouse v2", "Gruzbaza",
            },
            AllowedRoles = {
                ["Killer"] = true,
                ["Vigilante"] = true,
                ["Detective"] = true,
                ["Hero"] = true,
                ["Bystander"] = true,
            },
        },

        SergeyevBrothersBarbery = {
            CanonicalName = "Sergeyev Brothers Barbery",
            Mode = "Debt",
            Aliases = {
                "Sergeyev Brothers Barbery", "Sergevey's Brothers Barbery", "Barbery",
            },
            AllowedRoles = {
                ["Killer"] = true,
                ["Vigilante"] = true,
                ["Detective"] = true,
                ["Hero"] = true,
                ["Bystander"] = true,
            },
        },
    }

    Database.MAP_DATABASE = MAP_DATABASE

    local MAP_ALIAS_LOOKUP = {}
    local MAP_ALIAS_LIST = {}

    for mapKey, mapData in pairs(MAP_DATABASE) do
        mapData.Key = mapKey

        for _, alias in ipairs(mapData.Aliases or { mapData.CanonicalName }) do
            local norm = normalizeWeaponName(alias)

            if norm ~= "" then
                MAP_ALIAS_LOOKUP[norm] = mapData
                table.insert(MAP_ALIAS_LIST, {
                    Norm = norm,
                    Data = mapData,
                })
            end
        end
    end

    table.sort(MAP_ALIAS_LIST, function(a, b)
        return #a.Norm > #b.Norm
    end)

    local function matchMapFromText(rawText)
        if type(rawText) ~= "string" or rawText == "" then
            return nil
        end

        local stripped = rawText:gsub("%b[]", ""):gsub("%b()", "")
        local normFull = normalizeWeaponName(rawText)
        local normStripped = normalizeWeaponName(stripped)

        if MAP_ALIAS_LOOKUP[normStripped] then
            return MAP_ALIAS_LOOKUP[normStripped]
        end

        if MAP_ALIAS_LOOKUP[normFull] then
            return MAP_ALIAS_LOOKUP[normFull]
        end

        for _, entry in ipairs(MAP_ALIAS_LIST) do
            if #entry.Norm >= 4
                and (
                    string.find(normStripped, entry.Norm, 1, true)
                    or string.find(normFull, entry.Norm, 1, true)
                ) then
                return entry.Data
            end
        end

        return nil
    end

    local MODIFIER_LOOKUP = {
        standarddebt = "Modifier: Standard Debt",
        detectives = "Modifier: Detectives",
        doubletrouble = "Modifier: Double Trouble",
        equipmentmayhem = "Modifier: Equipment Mayhem",
        swapped = "Modifier: Swapped",
    }

    local function detectModifierFromText(rawText)
        if type(rawText) ~= "string" or rawText == "" then
            return nil
        end

        local norm = normalizeWeaponName(rawText)

        for modKey, modLabel in pairs(MODIFIER_LOOKUP) do
            if string.find(norm, modKey, 1, true) then
                return modLabel
            end
        end

        return nil
    end

    local cachedMapData = nil
    local cachedModifierName = nil
    local cachedRawMapName = nil
    local lastMapScanClock = 0
    local MAP_SCAN_INTERVAL = 1.0

    local MAP_ATTRIBUTE_NAMES = {
        "Map", "MapName", "CurrentMap", "ActiveMap", "SelectedMap", "Gamemode", "GameMode", "Mode",
    }

    function Database.invalidateMapScanCache()
        lastMapScanClock = 0
    end

    local function getCurrentMapInfo()
        local now = os.clock()

        if now - lastMapScanClock < MAP_SCAN_INTERVAL then
            return cachedMapData, cachedModifierName, cachedRawMapName
        end

        lastMapScanClock = now

        local detectedMap = nil
        local detectedModifier = nil
        local rawMapName = nil

        local function inspectString(str)
            if type(str) ~= "string" or str == "" then
                return
            end

            if not detectedModifier then
                detectedModifier = detectModifierFromText(str)
            end

            if not detectedMap then
                local matched = matchMapFromText(str)

                if matched then
                    detectedMap = matched
                    rawMapName = str
                end
            end
        end

        local bloodFolder = Workspace:FindFirstChild("BloodFolder")

        if bloodFolder then
            for _, attr in ipairs(MAP_ATTRIBUTE_NAMES) do
                local ok, val = pcall(function()
                    return bloodFolder:GetAttribute(attr)
                end)

                if ok and type(val) == "string" then
                    inspectString(val)
                end
            end

            local okChildren, children = pcall(function()
                return bloodFolder:GetChildren()
            end)

            if okChildren and children then
                for _, child in ipairs(children) do
                    if not child:IsA("Tool")
                        and not child:IsA("Camera")
                        and not child:IsA("Terrain") then

                        inspectString(child.Name)

                        if child:IsA("StringValue") or child:IsA("ObjectValue") then
                            pcall(function()
                                if child:IsA("StringValue") then
                                    inspectString(child.Value)
                                elseif child:IsA("ObjectValue") and child.Value then
                                    inspectString(child.Value.Name)
                                end
                            end)
                        end

                        for _, attr in ipairs(MAP_ATTRIBUTE_NAMES) do
                            local okA, valA = pcall(function()
                                return child:GetAttribute(attr)
                            end)

                            if okA and type(valA) == "string" then
                                inspectString(valA)
                            end
                        end
                    end
                end

                if not detectedMap then
                    for _, child in ipairs(children) do
                        if child:IsA("Folder") or child:IsA("Model") then
                            local okSub, subChildren = pcall(function()
                                return child:GetChildren()
                            end)

                            if okSub and subChildren then
                                for _, sub in ipairs(subChildren) do
                                    if not sub:IsA("Tool") and not sub:IsA("BasePart") then
                                        inspectString(sub.Name)

                                        if sub:IsA("StringValue") then
                                            inspectString(sub.Value)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if not detectedMap then
                if bloodFolder:FindFirstChild("Military APC", true)
                    or bloodFolder:FindFirstChild("APC", true) then
                    detectedMap = MAP_DATABASE.KualtonAirport
                    rawMapName = "KualtonAirport"
                end
            end
        end

        if not detectedMap or not detectedModifier then
            for _, root in ipairs({ Workspace, ReplicatedStorage }) do
                if root then
                    for _, attr in ipairs(MAP_ATTRIBUTE_NAMES) do
                        local ok, val = pcall(function()
                            return root:GetAttribute(attr)
                        end)

                        if ok and type(val) == "string" then
                            inspectString(val)
                        end
                    end

                    local okChildren, children = pcall(function()
                        return root:GetChildren()
                    end)

                    if okChildren and children then
                        for _, child in ipairs(children) do
                            if child:IsA("StringValue") then
                                inspectString(child.Value)
                            end
                        end
                    end
                end
            end
        end

        cachedMapData = detectedMap
        cachedModifierName = detectedModifier
        cachedRawMapName = rawMapName

        return cachedMapData, cachedModifierName, cachedRawMapName
    end

    Database.getCurrentMapInfo = getCurrentMapInfo

    local WEAPON_ROLE_LOOKUP = {}
    local WEAPON_DICT = {}
    local VIGILANTE_GUN_DICT = {}
    local ROLE_CATEGORIES = {}

    local function registerRoleCategory(roleName, metadata, multilineWeapons)
        local category = ROLE_CATEGORIES[roleName]

        if not category then
            local mapLookup = nil

            if metadata and metadata.Maps then
                mapLookup = {}

                for _, mName in ipairs(metadata.Maps) do
                    mapLookup[normalizeWeaponName(mName)] = true

                    local matched = matchMapFromText(mName)

                    if matched then
                        mapLookup[normalizeWeaponName(matched.CanonicalName)] = true
                        mapLookup[normalizeWeaponName(matched.Key)] = true
                    end
                end
            end

            category = {
                RoleName = roleName,
                Mode = metadata and metadata.Mode or "Any",
                Maps = metadata and metadata.Maps or nil,
                MapLookup = mapLookup,
                Priority = metadata and metadata.Priority or 50,
                IsNonIdentifying = metadata and metadata.IsNonIdentifying or false,
                Weapons = {},
            }

            ROLE_CATEGORIES[roleName] = category
        end

        for name in string.gmatch(multilineWeapons or "", "[^\r\n]+") do
            name = name:gsub("%-%-.*", ""):gsub("^%s+", ""):gsub("%s+$", "")

            if name ~= "" then
                local key = normalizeWeaponName(name)

                if key ~= "" then
                    WEAPON_DICT[key] = true
                    category.Weapons[key] = name

                    if roleName == "Vigilante" or roleName == "Detective" then
                        VIGILANTE_GUN_DICT[key] = true
                    end

                    local roles = WEAPON_ROLE_LOOKUP[key]

                    if not roles then
                        roles = {}
                        WEAPON_ROLE_LOOKUP[key] = roles
                    end

                    roles[roleName] = true
                end
            end
        end
    end

    local DEBT_MAPS_LIST = {
        "Pirozhok Apartments", "House Party", "Nubizkyl Metroline", "Small Farmhouse",
        "Penthouse", "Kovalevsky's Diner", "Resteyerok Apartment", "TNU Ministry Building",
        "The Pages Café", "Fire Station 14", "Theseus Fishing Vessel", "Sanguan Construction",
        "Trinity Den", "Suburban Nopan", "Rest Stop", "Kharitonov Research Station",
        "Mudzbilla Enterprises", "Strugatsky Park", "Gruzbaza Warehouse", "Sergeyev Brothers Barbery",
    }

    registerRoleCategory("Killer", {
        Mode = "Debt",
        Maps = DEBT_MAPS_LIST,
        Priority = 90,
    }, [[
1895-Rosey
Steel 1895-Rosey
AGM-22
APZ
Bezzhummy
Bezzhumny
Bouquet
Daniqui-Obrez
Door'bler
DOOR'BLER
TigerStripe Door'bler
TigerStripe Doo'bler
TIGERSTRIPE DOOR'BLER
Fleet K51
FT100
FT-100
Gisil-Pistole
Gild Gisil-Pistole
Hammer 'n Bullet
Hammer N' Bullet
Bullet 'n Hammer
HEARDBALLER
HEARDBALLA
Hearballa
HW-K7
H&W K7
HWISHH-KP9
J21a Meretta
JAVELIN-OBREZS
Jolibri
JS
Gild JS
JS-2 Derringy
JS2-Derringy
JS-2Derringy
Cute JS2-Derringy
GILDED JS-2 Derringy
JS-2 Bonds Derringy
Js2 Bond Derringy
.410 Bonds Derringy
410BONDS-Derringy
' Memories '
'Memories'
Memories
Katya's Memories
Katya's Memories JS-2 Derringer
JS1-CYCLOPS
JS1-Cyclops
JS1 Competitor
JS1-Competitor
Js1 Competitor
JS-22
JS-22 Sealed
Plastic JS-22
Charcoal Steel JS-22
Corroded Metal JS-22
Gilded JS-22
GILDED JS-22
Anatoly's JS-22
' Desperation '
'Desperation'
JSK-44
JS-44
Js-44
Charcoal Steel JS-44
JTS-225 Obrez
JTS225-Obrez
Gild JTS225-Obrez
Party Cannon JTS225-Obrez
JTS-225 Monocrome
JTS-225 Poly
K1911
K1911 Threaded
Gild K1911
GILDED K1911
Silver Steel K1911
Dark Steel K1911
Dented K1911
' Memorial '
'Memorial'
Kamatov
Kensington
Tropical Sunshine Kensington
KR7S
Cr7s
KriegsHerr-9
Lenitrovyak-23
LUT-E KRUS
Lut-e Krus
LUT-E 'PIP'
MAK-10
Mak-10
MAK-11
Tropical Sunshine MAK-10
Mandols-5
MANDOLS-5
Wild MANDOLS-5
Wild Mandols-5
Mare's Leg
Mares Leg
Steel Mares Leg
Merretta 486 Palubu
Micro KZI
Micro Kzi
Mikro KZI
Dual Micro KZis
Mooser
Pol357
PPm-41
Unioned PPm-41
PTRB-41
Rosen-Obrez
Rosen Obrez
Skeleton Rosen-Obrez
Skeletonized Rosen-Obrez
Gild Rosen-Obrez
GILDED Rosen Obrez
Guilded Obrez
Steel Rosen-Obrez
Clothed Rosen Obrez
Clothed Obrez
RR-LightCombatPistol (S)
RR-LightCombatPistol
RR-LightCompactPistol
RR-LightCompactPistolS
RR-LCP
RR-LCP (Silenced)
RR-LCP 10M
RR-LCP 50Rd
Dual RR-LCPs
Pretty Pink (RR-LCP)
Chromeslide (RR-LCP)
ChromeSlide Turqoise RR-LCP
Camo RR-LCPS
Cute RR-LCPS
RR-MARK2
RR-MarkII
RR-Mark2
RUZKH-12
UZKH12
Sawn-Off
Sawn-off
Sawed-Off
Sawed-Off 10M
Sawn-Off 10M
Sawn-Off 10
Clothed Sawn-Off
Clothed Sawed Off
Gild Sawn-off
GILDED Sawn-Off
Blaze Sawn-off
SKORPION
Skorpion
PRIDE SKORPION
Charcoal Steel Skorpion
Skorpion 10M
Dual Skorps
Dual SKORPS
TEKE-9
Thumpa
Sawed-THUMPA
WHIZZ
Whizz
WISP
ZOZ-106
ZT-33
ZT-33 (Golden)
ZZ-71
ZZ-90
Cellphone
Burner Cellphone
Sound Maker
Sound Maker Slow
RDG-2B
RDG-2B smoke grenade
Testament
Z26M Stungun
Throwing Dagger
Throwing knife
Kunai
Kunais
Shuriken
Shurikens
Tomahawk
Tomahawks
Smoke Grenade
Smoke Grenades
NGO
NGO Grenade
NGO-5
Bandage
Bandages
]])

    registerRoleCategory("Vigilante", {
        Mode = "Debt",
        Maps = DEBT_MAPS_LIST,
        Priority = 90,
    }, [[
ANKO46
Beagle
Beagle-44
Beagle-50
'Paradise'
'Paradise
Paradise Beagle
TIGERSTRIPE Beagle
TigerStripe Beagle
BUXXBERG-COMPACT
Buxxberg-COMPACT
BUXXBERG COMPACT
Pretty Pink BUXXBERG COMPACT
Pretty Pink BuxxBurg590
DRICO
Case-Hardened DRICO
GG-17
GG-17 Tan
Pretty Pink GG-17
Gild GG-17
GILDED GG-17
GG-17 Tropical Sunshine
Factory New GG-17 Fade
Dual GG-17
Dual GG-17s
Dual ELITES
Dual Elites
GG-26
HW-226
HWISSH-226
HWISSH-226 SHIELD
PRIDE H-226 SHIELD
HW-MPi5k
H&W-MPi5K
HW-M5K
IZVEKH-412
Charcoal Steel IZVEKH-412
J9-Meretta
J9-M
J9a1 Meretta
Gild J9a1 M
Dual Merettas
JS-5A-OBREZ
JS-5A-Obrez
Js-5a-Obrez
R&E M10
R&E Snubby
RR-Snubby
RR-Snubby 10M
RR-Snubby 10
Silver Steel RR-Snubby
Steel R&E Snubby
GILDED RR-Snubby
Golden RR-Snubby
Shot-7
SHOT-7
SWAG-7
ZKZ-Obrez
ZKZ-OBREZ10
Gild ZKZ-Obrez
Unioned ZKZ-Obrez
SAKURA ZKZ-Obrez
ZKZ-Obrez Sakuya
THE SPOON
]])

    registerRoleCategory("Detective", {
        Mode = "Debt",
        Maps = DEBT_MAPS_LIST,
        Priority = 88,
    }, [[
ANKO46
Beagle
Beagle-44
Beagle-50
'Paradise'
Paradise Beagle
TIGERSTRIPE Beagle
BUXXBERG-COMPACT
Buxxberg-COMPACT
DRICO
GG-17
GG-26
HW-226
HWISSH-226 SHIELD
HW-MPi5k
H&W-MPi5K
IZVEKH-412
J9-Meretta
J9a1 Meretta
JS-5A-OBREZ
JS-5A-Obrez
R&E M10
R&E Snubby
RR-Snubby
Shot-7
SHOT-7
ZKZ-Obrez
ZKZ-OBREZ10
]])

    registerRoleCategory("Hero", {
        Mode = "Debt",
        Maps = DEBT_MAPS_LIST,
        Priority = 95,
    }, [[
ANKO46
Beagle
Beagle-44
Beagle-50
'Paradise'
Paradise Beagle
TIGERSTRIPE Beagle
BUXXBERG-COMPACT
Buxxberg-COMPACT
DRICO
GG-17
GG-26
HW-226
HWISSH-226 SHIELD
HW-MPi5k
H&W-MPi5K
IZVEKH-412
J9-Meretta
J9a1 Meretta
JS-5A-OBREZ
JS-5A-Obrez
R&E M10
R&E Snubby
RR-Snubby
Shot-7
SHOT-7
ZKZ-Obrez
ZKZ-OBREZ10
]])

    registerRoleCategory("Bystander", {
        Mode = "Debt / Juggernaut",
        Maps = {
            "Ragged Woods Campgrounds",
            "Pirozhok Apartments", "House Party", "Nubizkyl Metroline", "Small Farmhouse",
            "Penthouse", "Kovalevsky's Diner", "Resteyerok Apartment", "TNU Ministry Building",
            "The Pages Café", "Fire Station 14", "Theseus Fishing Vessel", "Sanguan Construction",
            "Trinity Den", "Suburban Nopan", "Rest Stop", "Kharitonov Research Station",
            "Mudzbilla Enterprises", "Strugatsky Park", "Gruzbaza Warehouse", "Sergeyev Brothers Barbery",
        },
        Priority = 45,
    }, [[
Book
Camera
Cassette Player
Clipboard
Corndog
Deluxe Camera
Glass
Lighter Lingo
Lighter Sippo
Nabanese Camera
Pastry Bun
TV Studio Camera
]])

    registerRoleCategory("Juggernaut: The Bear", {
        Mode = "Juggernaut",
        Maps = { "Ragged Woods Campgrounds" },
        Priority = 100,
    }, [[
THE BEAR'S plaything
THE BEAR's plaything
The Bear's Plaything
THE BEAR'S throwing tomahawks
THE BEAR'S throwing tomahawk
The Bear's Throwing Tomahawks
]])

    registerRoleCategory("Juggernaut: Sharpshooter", {
        Mode = "Juggernaut",
        Maps = { "Winter Offensive" },
        Priority = 100,
    }, [[
TG's ZVD
Zimniy Voron
Zimniy Voron ZVD
JTS-225
]])

    registerRoleCategory("Juggernaut: Former Paratrooper", {
        Mode = "Juggernaut",
        Maps = { "Private Cottage", "Forlorn Cottage" },
        Priority = 100,
    }, [[
RVK
VKAZ's RVK
Vkaz's RVK
Supressed Plum RVK
IZVEKH-412
NGO
Zarye-2
]])

    registerRoleCategory("Juggernaut: APC Driver", {
        Mode = "Juggernaut",
        Maps = { "Kualton Airport" },
        Priority = 100,
    }, [[
Military APC
APC
CIR95
]])

    registerRoleCategory("Juggernaut: Stanislav / Mstislav", {
        Mode = "Juggernaut",
        Maps = { "Crown PMC Warehouse", "Office" },
        Priority = 100,
    }, [[
GZHG-7.62
GZhG-7.62 HMG
GZhG-7.62
LORD 12.7
MERSA-12
Mersa-12
]])

    registerRoleCategory("Juggernaut: Alexei Tarasov", {
        Mode = "Juggernaut",
        Maps = { "Monobank", "High Rise", "Office" },
        Priority = 100,
    }, [[
AT's K16A1
AT's KAR16A1
AT's KAR-15
]])

    registerRoleCategory("Juggernaut: Ryman Yegorova", {
        Mode = "Juggernaut",
        Maps = { "Office", "High Rise" },
        Priority = 100,
    }, [[
RY's GG-17
Ry's GG-17
]])

    registerRoleCategory("Juggernaut: Viadimir Koltsov", {
        Mode = "Juggernaut",
        Maps = { "High Rise", "Office" },
        Priority = 100,
    }, [[
VK's ANKM
Vk's Ankm
]])

    registerRoleCategory("Juggernaut: Glaz", {
        Mode = "Juggernaut",
        Maps = { "NoskowAlleyway HELL" },
        Priority = 100,
    }, [[
Peacemaker
]])

    registerRoleCategory("Robber", {
        Mode = "Juggernaut",
        Maps = { "Private Cottage", "Forlorn Cottage" },
        Priority = 78,
    }, [[
JS-2 Derringy
JS-22
RR-LightCombatPistol
RR-LightCombatPistol (S)
IZVEKH-412
Kamatov
HWISHH-KP9
MAK-10
]])

    registerRoleCategory("Foresters", {
        Mode = "Juggernaut",
        Maps = { "Ragged Woods Campgrounds" },
        Priority = 86,
    }, [[
Rosen-Nagan
ZKZ
Coach Shotgun
]])

    registerRoleCategory("Politsiya", {
        Mode = "Juggernaut",
        Maps = {
            "Private Cottage", "Forlorn Cottage", "Crown PMC Warehouse",
            "Monobank", "High Rise", "Office",
        },
        Priority = 85,
    }, [[
AN-J91
ANKS-74U
ANK74SU
ANK74M
IZVEKH-412
IZVEKH-BISEN
Izvekh-Bisen
KOLT-PSRL
KOLT-PSRL RPG
ZJ-23M
Zj23m
ZKMP
ZKPM
ZOZ-194
RR-40
JTS-225
JTS-225-12
]])

    registerRoleCategory("Survivor", {
        Mode = "Juggernaut",
        Maps = {
            "Kualton Airport", "Monobank", "High Rise", "Office",
            "Camp Crystal Waters", "NoskowAlleyway HELL",
        },
        Priority = 75,
    }, [[
KAR-15
EXM-177
ANKS-74U
BF AAL
MERSA-12
Aluminium Bat
Boxcutter
JS-2 Derringy
Kitchen Knife
Lead Pipe
Pen
Pickaxe
IZVEKH-412
JS-22
RR-LightCombatPistol
RR-LightCombatPistol (S)
]])

    registerRoleCategory("SEATO Reinforcements", {
        Mode = "Juggernaut",
        Maps = { "Kualton Airport", "Crown PMC Warehouse" },
        Priority = 88,
    }, [[
PTRZ-41
GATR 05
GATR-05
KOLT-PSRL
KOLT-PSRL RPG
BGRT-7
ZKMP
GGtastic
CrownPMC GGtastic
]])

    registerRoleCategory("NETO Soldier", {
        Mode = "Juggernaut",
        Maps = { "Winter Offensive" },
        Priority = 76,
    }, [[
A85L1
KAR-15
EXM-177
RR-40
HW-SpM45
]])

    registerRoleCategory("NETO Reinforcements", {
        Mode = "Juggernaut",
        Maps = { "Winter Offensive" },
        Priority = 84,
    }, [[
BF F90
BF AAL
A86M2L-SW
HW-G3a3
COLT-733
H&W-G36CC
]])

    registerRoleCategory("Sharpshooter", {
        Mode = "Juggernaut / Team War",
        Maps = {
            "Winter Offensive", "Svetonskiy Overpass", "Nubizkyl City", "Abandoned Warehouse",
            "Rodinskaya Street", "Forgotten Garages", "Forgotten Gas Station", "Noskow Exchange",
            "Sretenskaya", "Chernaya Zone", "Dead Men Overpass",
        },
        Priority = 87,
    }, [[
Blemington-700 Scoped
Blemington 700 Scoped
JAVELIN-ZVD
Javilin-ZVD
JAVELIN-ZVU
RR-21-SWS
VZZ
ZPO-101
Casaro 91
Rosen-Nagan
]])

    registerRoleCategory("Scavenger", {
        Mode = "Scav War",
        Maps = { "Abandoned Factory", "Kuai Pan Streets" },
        Priority = 86,
    }, [[
AMAR-15
AMAR15
Mini Ranch Rifle
ZKZ
Rosen-Nagan
Coach Shotgun
MERSA-12
CIR95
ANKS-74U
JTS-225
H&W-MPi5K
HW-MPi5k
]])

    registerRoleCategory("Team War", {
        Mode = "Team War",
        Maps = {
            "Abandoned Warehouse", "Nubizkyl City", "Rodinskaya Street", "Forgotten Garages",
            "Noskow Alleyway", "Svetonskiy Overpass", "Forgotten Gas Station", "Noskow Exchange",
            "Sretenskaya", "Chernaya Zone", "Operation Rodinskaya", "Dead Men Overpass",
        },
        Priority = 60,
    }, [[
1895-Rosey
HW-SpM45
JS-2 Derringy
K1911
ZR-1
ANKS-74U
Auto 180
BF F90
HW-MPi5a4
HW3
HW 3
IZVEKH-BISEN
IZVEKH-VITEX
IZVEKH-ViteX (Silenced)
KEDIR
OTz-02
RR-40
Tarakev-43
ZR-2
A85L1
A86M2L-SW
AB-VIZG
AN-J91
ANKM
ANKM-10ROUND
AK74M
ANK74M
BF AAL
Blemington-700 Scoped
Casaro 91
CIR95
COLT-733
EXM-177
H&W-G36CC
HW-G3a3
JAVELIN-ZVD
JAVELIN-ZVU
KAR-15
Kolt AR-15
KR2
M14
Rosen-Nagan
RR-14
RR-21-SWS
SAG STORM
SAG-Storm
VZZ
ZKZ
ZPO-101
Buxxberg-590
BuxxBerg590
BUXXBERG-COMPACT
Coach Shotgun
HUSHASH-12
JS-5A
JTS-225
MERSA-12
Palico-37
ZJ-23M
ZOZ-194
Bandages
Kunais
NGO
Shurikens
Smoke Grenades
Throwing knife
Tomahawks
]])

    registerRoleCategory("Equipment Mayhem / Shared Equipment", {
        Mode = "Any",
        Priority = 10,
        IsNonIdentifying = true,
    }, [[
Bear Trap
Smoke Maker
Zarye-2
]])

    registerRoleCategory("Melee / Role Unknown", {
        Mode = "Any",
        Priority = 5,
        IsNonIdentifying = true,
    }, [[
Aluminium Bat
Axe
Baseball Bat
Boxcutter
Box Cutters
Cleaver
Cooking Pot
Crowbar
Drill
Extinguisher
Fire Axe
Frying Pan
Pan
Golf Club
Hatchet
Hunting Knife
Kitchen Knife
Lead Pipe
Machete
Pen
Pickaxe
Pipe Wrench
Pool Cue
Pot
Rapier
Hweizlander
Sword
Scythe
Shovel
Sledgehammer
Sledge Hammer
Spiked Club
Steel Bat
Tactical Machete
]])

    registerRoleCategory("Legacy / Admin", {
        Mode = "Any",
        Priority = 5,
        IsNonIdentifying = true,
    }, [[
Factory new 52363 USD Souvenir Dragon Lore (Kingsland Precision A96A1)
Awp Dragon Lore Skin
AK47 Case-Hardened 1000000
]])

    Database.ROLE_CATEGORIES = ROLE_CATEGORIES

    local TEAM_WAR_FACTIONS = {}

    for faction in string.gmatch([[
Bratva
Nubizkyl Bratva
The Noobian Mafia
Heist Crew
Hobos
Hoboes
Homeless
Hobos / Homeless
Hooligans
MNB
Noobic Union Armed Forces
NUAF
The Noobian Army
Nubagami
Noobenese Yakuza
Royal Kingsland Army
NETO
STRELA
Street Gang
The Politsiya
The Trinity
The Triad
The Zoo
Armed Debtors
Vanguardists
Worker's Army
White Imperialist Movement
Free Kaukasus Army
ZONTIK Operators
Amtavirus Mutants
]], "[^\r\n]+") do
        faction = faction:gsub("^%s+", ""):gsub("%s+$", "")

        if faction ~= "" then
            TEAM_WAR_FACTIONS[normalizeWeaponName(faction)] = faction
        end
    end

    local function isRecognizedWeapon(name)
        return WEAPON_DICT[normalizeWeaponName(name)] == true
    end

    local function isVigilanteWeapon(name)
        return VIGILANTE_GUN_DICT[normalizeWeaponName(name)] == true
    end

    Database.isRecognizedWeapon = isRecognizedWeapon
    Database.isVigilanteWeapon = isVigilanteWeapon

    local everDroppedVigilanteTools = setmetatable({}, { __mode = "k" })
    local initialVigilanteOwners = setmetatable({}, { __mode = "k" })
    local heroPlayers = setmetatable({}, { __mode = "k" })

    Database.everDroppedVigilanteTools = everDroppedVigilanteTools
    Database.initialVigilanteOwners = initialVigilanteOwners
    Database.heroPlayers = heroPlayers

    local function resetRoundHeroTracking()
        table.clear(everDroppedVigilanteTools)
        table.clear(initialVigilanteOwners)
        table.clear(heroPlayers)
    end

    Database.resetRoundHeroTracking = resetRoundHeroTracking

    local function getRosterRoleForWeapon(name, activeMap, activeModifier)
        local key = normalizeWeaponName(name)
        local roles = WEAPON_ROLE_LOOKUP[key]

        if not roles then
            return nil
        end

        local mapMode = activeMap and activeMap.Mode or nil
        local mapName = activeMap and activeMap.CanonicalName or nil
        local allowedOnMap = activeMap and activeMap.AllowedRoles or nil

        if roles["Juggernaut: The Bear"] then
            return "Juggernaut: The Bear"
        end

        if roles["Juggernaut: Alexei Tarasov"] then
            return "Juggernaut: Alexei Tarasov"
        end

        if roles["Juggernaut: Ryman Yegorova"] then
            return "Juggernaut: Ryman Yegorova"
        end

        if roles["Juggernaut: Viadimir Koltsov"] then
            return "Juggernaut: Viadimir Koltsov"
        end

        if roles["Juggernaut: Glaz"] then
            return "Juggernaut: Glaz"
        end

        if mapName == "Winter Offensive" then
            if key == normalizeWeaponName("TG's ZVD")
                or key == normalizeWeaponName("Zimniy Voron")
                or key == normalizeWeaponName("Zimniy Voron ZVD")
                or key == normalizeWeaponName("JTS-225") then
                return "Juggernaut: Sharpshooter"
            end

            if roles["Sharpshooter"] then
                return "Sharpshooter"
            end

            if roles["NETO Reinforcements"] then
                return "NETO Reinforcements"
            end

            if roles["NETO Soldier"] then
                return "NETO Soldier"
            end

        elseif mapName == "Ragged Woods Campgrounds" then
            if roles["Juggernaut: The Bear"] then
                return "Juggernaut: The Bear"
            end

            if roles["Foresters"] then
                return "Foresters"
            end

            if roles["Bystander"]
                or key == normalizeWeaponName("JS-2 Derringy")
                or key == normalizeWeaponName("Aluminium Bat")
                or key == normalizeWeaponName("Pickaxe") then
                return "Bystander"
            end

        elseif mapName == "Private Cottage" or mapName == "Forlorn Cottage" then
            if key == normalizeWeaponName("RVK")
                or key == normalizeWeaponName("VKAZ's RVK")
                or key == normalizeWeaponName("Vkaz's RVK")
                or key == normalizeWeaponName("Supressed Plum RVK") then
                return "Juggernaut: Former Paratrooper"
            end

            if roles["Politsiya"] and not roles["Robber"] then
                return "Politsiya"
            end

            if roles["Robber"] then
                return "Robber"
            end

        elseif mapName == "Kualton Airport" then
            if roles["Juggernaut: APC Driver"] then
                return "Juggernaut: APC Driver"
            end

            if roles["SEATO Reinforcements"] then
                return "SEATO Reinforcements"
            end

            if roles["Survivor"] then
                return "Survivor"
            end

        elseif mapName == "Crown PMC Warehouse" then
            if roles["Juggernaut: Stanislav / Mstislav"] then
                return "Juggernaut: Stanislav / Mstislav"
            end

            if roles["Politsiya"] or roles["SEATO Reinforcements"] then
                return "Politsiya"
            end

        elseif mapName == "Monobank"
            or mapName == "High Rise"
            or mapName == "Office"
            or mapName == "Camp Crystal Waters" then

            if roles["Politsiya"] and not roles["Survivor"] then
                return "Politsiya"
            end

            if roles["Survivor"] then
                return "Survivor"
            end

        elseif mapMode == "Scav War" then
            if roles["Scavenger"] or roles["Team War"] or roles["Killer"] or roles["Vigilante"] then
                return "Scavenger"
            end

        elseif mapMode == "Team War" then
            if roles["Sharpshooter"] then
                return "Sharpshooter"
            end

            if roles["Team War"] then
                return "Team War"
            end

        elseif mapMode == "Debt" then
            local isDetectivesMod = activeModifier == "Modifier: Detectives"
            local isSwappedMod = activeModifier == "Modifier: Swapped"

            if roles["Killer"] and not roles["Vigilante"] then
                if isSwappedMod then
                    return isDetectivesMod and "Detective" or "Vigilante"
                end

                return "Killer"
            end

            if roles["Vigilante"] and not roles["Killer"] then
                if isSwappedMod then
                    return "Killer"
                end

                return isDetectivesMod and "Detective" or "Vigilante"
            end

            if roles["Bystander"] then
                return "Bystander"
            end
        end

        if key == normalizeWeaponName("TG's ZVD")
            or key == normalizeWeaponName("Zimniy Voron")
            or key == normalizeWeaponName("Zimniy Voron ZVD") then
            return "Juggernaut: Sharpshooter"
        end

        if key == normalizeWeaponName("RVK")
            or key == normalizeWeaponName("VKAZ's RVK")
            or key == normalizeWeaponName("Supressed Plum RVK") then
            return "Juggernaut: Former Paratrooper"
        end

        if key == normalizeWeaponName("Military APC")
            or key == normalizeWeaponName("APC") then
            return "Juggernaut: APC Driver"
        end

        if key == normalizeWeaponName("GZHG-7.62")
            or key == normalizeWeaponName("GZhG-7.62 HMG")
            or key == normalizeWeaponName("LORD 12.7") then
            return "Juggernaut: Stanislav / Mstislav"
        end

        local bestCandidate = nil
        local bestPriority = -1

        for roleName in pairs(roles) do
            local cat = ROLE_CATEGORIES[roleName]

            if cat
                and not cat.IsNonIdentifying
                and roleName ~= "Team War"
                and roleName ~= "Detective"
                and roleName ~= "Hero" then

                local mapAllowed = (not allowedOnMap) or (allowedOnMap[roleName] == true)

                if mapAllowed and cat.Priority > bestPriority then
                    bestPriority = cat.Priority
                    bestCandidate = roleName
                end
            end
        end

        if bestCandidate then
            if bestCandidate == "Killer" and activeModifier == "Modifier: Swapped" then
                return "Vigilante"
            elseif bestCandidate == "Vigilante" then
                if activeModifier == "Modifier: Swapped" then
                    return "Killer"
                elseif activeModifier == "Modifier: Detectives" then
                    return "Detective"
                end
            end

            return bestCandidate
        end

        if roles["Sharpshooter"] then
            return "Sharpshooter"
        end

        if roles["Politsiya"] then
            return "Politsiya"
        end

        if roles["Foresters"] then
            return "Foresters"
        end

        if roles["Scavenger"] then
            return "Scavenger"
        end

        if roles["Bystander"] then
            return "Bystander"
        end

        if roles["Equipment Mayhem / Shared Equipment"] then
            return "Equipment Mayhem / Shared Equipment"
        end

        if roles["Team War"] then
            return "Team War"
        end

        if roles["Melee / Role Unknown"] then
            return "Melee / Role Unknown"
        end

        if roles["Legacy / Admin"] then
            return "Legacy / Admin"
        end

        return "Shared / Mode-Dependent"
    end

    local ROLE_ATTRIBUTE_NAMES = {
        "Role", "RoleName", "CurrentRole", "ModeRole", "Faction", "Class", "RoleType", "SubRole", "Job",
    }

    local KNOWN_ROLE_NAMES = {
        killer = "Killer",
        vigilante = "Vigilante",
        detective = "Detective",
        police = "Politsiya",
        politsiya = "Politsiya",
        thepolitsiya = "Politsiya",
        bystander = "Bystander",
        target = "Bystander",
        hero = "Hero",
        innocent = "Innocent",
        juggernaut = "Juggernaut",
        survivor = "Survivor",
        robber = "Robber",
        robbers = "Robber",
        scavenger = "Scavenger",
        scavengers = "Scavenger",
        forester = "Foresters",
        foresters = "Foresters",
        theforesters = "Foresters",
        reinforcement = "SEATO Reinforcements",
        reinforcements = "SEATO Reinforcements",
        seatoreinforcements = "SEATO Reinforcements",
        netoreinforcements = "NETO Reinforcements",
        netosoldier = "NETO Soldier",
        sharpshooter = "Sharpshooter",
        sniper = "Sharpshooter",
        marksman = "Sharpshooter",
        assault = "Assault",
        support = "Support",
        pointman = "Pointman",
        gunner = "Gunner",
        thebear = "Juggernaut: The Bear",
        lyudmilarozhechuk = "Juggernaut: The Bear",
        formerparatrooper = "Juggernaut: Former Paratrooper",
        veronikakazakova = "Juggernaut: Former Paratrooper",
        apcdriver = "Juggernaut: APC Driver",
        kaizhang = "Juggernaut: APC Driver",
        gennadiytraktirnikov = "Juggernaut: Sharpshooter",
        traktirnikovgennadiy = "Juggernaut: Sharpshooter",
        traktirnikovgennady = "Juggernaut: Sharpshooter",
        gennadytraktirnikov = "Juggernaut: Sharpshooter",
        tg = "Juggernaut: Sharpshooter",
        stanislavrybinsky = "Juggernaut: Stanislav / Mstislav",
        stanislav = "Juggernaut: Stanislav / Mstislav",
        mstislavrybinsky = "Juggernaut: Stanislav / Mstislav",
        alexeitarasov = "Juggernaut: Alexei Tarasov",
        rymanyegorova = "Juggernaut: Ryman Yegorova",
        rymanyegorov = "Juggernaut: Ryman Yegorova",
        viadimirkoltsov = "Juggernaut: Viadimir Koltsov",
        vladimirkoltsov = "Juggernaut: Viadimir Koltsov",
        masonjr = "Juggernaut: Mason Jr.",
        masonjunior = "Juggernaut: Mason Jr.",
        glaztheschizohobo = "Juggernaut: Glaz",
        glazthearmoredhobo = "Juggernaut: Glaz",
    }

    for normFaction, displayFaction in pairs(TEAM_WAR_FACTIONS) do
        KNOWN_ROLE_NAMES[normFaction] = "Team War: " .. displayFaction
    end

    local function resolveExplicitRoleText(value, activeMap, activeModifier)
        if type(value) ~= "string" or value == "" then
            return nil
        end

        local normalized = normalizeWeaponName(value)

        if normalized == "" or MODIFIER_LOOKUP[normalized] then
            return nil
        end

        if normalized == "target" then
            return "Bystander"
        end

        if KNOWN_ROLE_NAMES[normalized] then
            local mapped = KNOWN_ROLE_NAMES[normalized]

            if mapped == "Vigilante" and activeModifier == "Modifier: Detectives" then
                return "Detective"
            end

            if mapped == "Juggernaut"
                and activeMap
                and activeMap.Roles
                and activeMap.Roles.Juggernaut then
                return activeMap.Roles.Juggernaut
            end

            return mapped
        end

        if TEAM_WAR_FACTIONS[normalized] then
            return "Team War: " .. TEAM_WAR_FACTIONS[normalized]
        end

        return string.sub(value, 1, 42)
    end

    function Database.getRole(player)
        if not player then
            return "Innocent", nil
        end

        local activeMap, activeModifier = getCurrentMapInfo()
        local character = player.Character
        local backpack = player:FindFirstChild("Backpack")

        local equippedVigilanteGun = nil
        local hasBystanderProp = false

        local function checkToolsForHero(container)
            if not container then
                return
            end

            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    local wKey = normalizeWeaponName(tool.Name)

                    if ROLE_CATEGORIES["Bystander"].Weapons[wKey] then
                        hasBystanderProp = true
                    end

                    if isVigilanteWeapon(tool.Name) and (not activeMap or activeMap.Mode == "Debt") then
                        equippedVigilanteGun = tool.Name

                        if everDroppedVigilanteTools[tool] then
                            heroPlayers[player] = tool.Name
                        elseif not initialVigilanteOwners[tool] then
                            initialVigilanteOwners[tool] = player
                        elseif initialVigilanteOwners[tool] ~= player then
                            heroPlayers[player] = tool.Name
                        end
                    end
                end
            end
        end

        checkToolsForHero(character)
        checkToolsForHero(backpack)

        if equippedVigilanteGun and (heroPlayers[player] or hasBystanderProp) then
            return "Hero", equippedVigilanteGun
        end

        local bestRole = nil
        local bestWeapon = nil
        local bestPriority = -1
        local sharedMatch = false

        local function evaluateTool(tool, isEquipped)
            if not tool or not tool:IsA("Tool") then
                return
            end

            local roleName = getRosterRoleForWeapon(tool.Name, activeMap, activeModifier)

            if not roleName then
                return
            end

            if roleName == "Shared / Mode-Dependent" then
                sharedMatch = true
                return
            end

            if roleName == "Melee / Role Unknown"
                or roleName == "Equipment Mayhem / Shared Equipment"
                or roleName == "Legacy / Admin" then
                return
            end

            local cat = ROLE_CATEGORIES[roleName]
            local priority = (cat and cat.Priority or 65) + (isEquipped and 5 or 0)

            if string.find(roleName, "Juggernaut", 1, true) then
                priority = 100 + (isEquipped and 5 or 0)
            elseif roleName == "Sharpshooter" then
                priority = 89 + (isEquipped and 5 or 0)
            end

            if priority > bestPriority then
                bestPriority = priority
                bestRole = roleName
                bestWeapon = tool.Name
            end
        end

        if character then
            for _, tool in ipairs(character:GetChildren()) do
                evaluateTool(tool, true)
            end
        end

        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                evaluateTool(tool, false)
            end
        end

        local team = player.Team

        if team and team.Name ~= "" then
            local normTeam = normalizeWeaponName(team.Name)

            if TEAM_WAR_FACTIONS[normTeam] then
                local baseTeamRole = "Team War: " .. TEAM_WAR_FACTIONS[normTeam]

                if bestRole == "Sharpshooter" then
                    return baseTeamRole .. " (Sharpshooter)", bestWeapon
                end

                return baseTeamRole, bestWeapon
            end
        end

        if bestRole and bestRole ~= "Bystander" and bestRole ~= "Team War" then
            return bestRole, bestWeapon
        end

        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.MaxHealth > 125 then
                if activeMap and activeMap.Roles and activeMap.Roles.Juggernaut then
                    return activeMap.Roles.Juggernaut, bestWeapon
                elseif humanoid.MaxHealth >= 1500 then
                    return "Juggernaut: Stanislav / Mstislav", bestWeapon
                elseif humanoid.MaxHealth >= 500 then
                    return "Juggernaut: Former Paratrooper", bestWeapon
                elseif humanoid.MaxHealth == 250 then
                    return "Juggernaut: The Bear", bestWeapon
                end
            end

            local charMatch = KNOWN_ROLE_NAMES[normalizeWeaponName(character.Name)]

            if charMatch and string.find(charMatch, "Juggernaut", 1, true) then
                return charMatch, bestWeapon
            end
        end

        if team and team.Name ~= "" then
            local normTeam = normalizeWeaponName(team.Name)

            if KNOWN_ROLE_NAMES[normTeam] then
                return resolveExplicitRoleText(team.Name, activeMap, activeModifier), bestWeapon
            end
        end

        for _, attributeName in ipairs(ROLE_ATTRIBUTE_NAMES) do
            local okP, valP = pcall(function()
                return player:GetAttribute(attributeName)
            end)

            if okP and type(valP) == "string" then
                local resolved = resolveExplicitRoleText(valP, activeMap, activeModifier)

                if resolved then
                    return resolved, bestWeapon
                end
            end

            if character then
                local okC, valC = pcall(function()
                    return character:GetAttribute(attributeName)
                end)

                if okC and type(valC) == "string" then
                    local resolved = resolveExplicitRoleText(valC, activeMap, activeModifier)

                    if resolved then
                        return resolved, bestWeapon
                    end
                end
            end
        end

        for _, container in ipairs({ player, character }) do
            if container then
                for _, valueName in ipairs(ROLE_ATTRIBUTE_NAMES) do
                    local valueObject = container:FindFirstChild(valueName)

                    if valueObject and valueObject:IsA("StringValue") then
                        local resolved = resolveExplicitRoleText(valueObject.Value, activeMap, activeModifier)

                        if resolved then
                            return resolved, bestWeapon
                        end
                    end
                end
            end
        end

        if bestRole then
            return bestRole, bestWeapon
        end

        if activeMap then
            if activeMap.Mode == "Scav War" then
                return "Scavenger", nil
            elseif activeMap.Mode == "Juggernaut"
                and activeMap.Roles
                and activeMap.Roles.Wave1 then
                return activeMap.Roles.Wave1, nil
            elseif activeMap.Mode == "Debt" then
                return "Bystander", nil
            end
        end

        if sharedMatch then
            return "Shared / Mode-Dependent", nil
        end

        return "Innocent", nil
    end

    function Database.getRoleDisplay(role, weaponName)
        local color

        if role == "Killer" then
            color = Color3.fromRGB(255, 70, 70)
        elseif role == "Hero" then
            color = Color3.fromRGB(255, 215, 65)
        elseif role == "Vigilante" or role == "Detective" or role == "Politsiya" then
            color = Color3.fromRGB(85, 150, 255)
        elseif string.find(role, "Juggernaut: The Bear", 1, true) then
            color = Color3.fromRGB(215, 90, 45)
        elseif string.find(role, "Juggernaut: Sharpshooter", 1, true)
            or string.find(role, "Sharpshooter", 1, true) then
            color = Color3.fromRGB(0, 230, 180)
        elseif string.find(role, "Juggernaut", 1, true) then
            color = Color3.fromRGB(195, 105, 255)
        elseif role == "Foresters"
            or role == "SEATO Reinforcements"
            or role == "NETO Reinforcements" then
            color = Color3.fromRGB(75, 210, 165)
        elseif string.find(role, "Team War", 1, true) then
            color = Color3.fromRGB(90, 220, 220)
        elseif role == "Scavenger"
            or role == "Robber"
            or role == "NETO Soldier"
            or role == "Survivor" then
            color = Color3.fromRGB(245, 185, 85)
        elseif role == "Bystander" or role == "Innocent" then
            color = Color3.fromRGB(100, 220, 130)
        else
            color = Color3.fromRGB(190, 195, 205)
        end

        local label = role

        if weaponName and weaponName ~= "" then
            label = string.format("%s [%s]", role, weaponName)
        end

        return label, color
    end

    return Database
end

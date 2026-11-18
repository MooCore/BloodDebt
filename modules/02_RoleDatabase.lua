WEAPON_ROLE_LOOKUP = {}
WEAPON_DICT = {}
VIGILANTE_GUN_DICT = {}
ROLE_CATEGORIES = {}

function registerRoleCategory(roleName, metadata, multilineWeapons)
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
        name = name:gsub("%-%-.*", ""):gsub("^%s+", ""):gsub("%s+", "")
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

DEBT_MAPS_LIST = {
    "Pirozhok Apartments", "House Party", "Nubizkyl Metroline", "Small Farmhouse",
    "Penthouse", "Kovalevsky's Diner", "Resteyerok Apartment", "TNU Ministry Building",
    "The Pages Café", "Fire Station 14", "Theseus Fishing Vessel", "Sanguan Construction",
    "Trinity Den", "Suburban Nopan", "Rest Stop", "Kharitonov Research Station",
    "Mudzbilla Enterprises", "Strugatsky Park", "Gruzbaza Warehouse", "Sergeyev Brothers Barbery",
}

registerRoleCategory("Killer", { Mode = "Debt", Maps = DEBT_MAPS_LIST, Priority = 90 }, [[
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

registerRoleCategory("Vigilante", { Mode = "Debt", Maps = DEBT_MAPS_LIST, Priority = 90 }, [[
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

registerRoleCategory("Detective", { Mode = "Debt", Maps = DEBT_MAPS_LIST, Priority = 88 }, [[
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

registerRoleCategory("Hero", { Mode = "Debt", Maps = DEBT_MAPS_LIST, Priority = 95 }, [[
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
        "Ragged Woods Campgrounds", "Pirozhok Apartments", "House Party", "Nubizkyl Metroline",
        "Small Farmhouse", "Penthouse", "Kovalevsky's Diner", "Resteyerok Apartment",
        "TNU Ministry Building", "The Pages Café", "Fire Station 14", "Theseus Fishing Vessel",
        "Sanguan Construction", "Trinity Den", "Suburban Nopan", "Rest Stop",
        "Kharitonov Research Station", "Mudzbilla Enterprises", "Strugatsky Park",
        "Gruzbaza Warehouse", "Sergeyev Brothers Barbery",
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

registerRoleCategory("Juggernaut: The Bear", { Mode = "Juggernaut", Maps = { "Ragged Woods Campgrounds" }, Priority = 100 }, [[
THE BEAR'S plaything
THE BEAR's plaything
The Bear's Plaything
THE BEAR'S throwing tomahawks
THE BEAR'S throwing tomahawk
The Bear's Throwing Tomahawks
]])

registerRoleCategory("Juggernaut: Sharpshooter", { Mode = "Juggernaut", Maps = { "Winter Offensive" }, Priority = 100 }, [[
TG's ZVD
Zimniy Voron
Zimniy Voron ZVD
JTS-225
]])

registerRoleCategory("Juggernaut: Former Paratrooper", { Mode = "Juggernaut", Maps = { "Private Cottage", "Forlorn Cottage" }, Priority = 100 }, [[
RVK
VKAZ's RVK
Vkaz's RVK
Supressed Plum RVK
IZVEKH-412
NGO
Zarye-2
]])

registerRoleCategory("Juggernaut: APC Driver", { Mode = "Juggernaut", Maps = { "Kualton Airport" }, Priority = 100 }, [[
Military APC
APC
CIR95
]])

registerRoleCategory("Juggernaut: Stanislav / Mstislav", { Mode = "Juggernaut", Maps = { "Crown PMC Warehouse", "Office" }, Priority = 100 }, [[
GZHG-7.62
GZhG-7.62 HMG
GZhG-7.62
LORD 12.7
MERSA-12
Mersa-12
]])

registerRoleCategory("Juggernaut: Alexei Tarasov", { Mode = "Juggernaut", Maps = { "Monobank", "High Rise", "Office" }, Priority = 100 }, [[
AT's K16A1
AT's KAR16A1
AT's KAR-15
]])

registerRoleCategory("Juggernaut: Ryman Yegorova", { Mode = "Juggernaut", Maps = { "Office", "High Rise" }, Priority = 100 }, [[
RY's GG-17
Ry's GG-17
]])

registerRoleCategory("Juggernaut: Viadimir Koltsov", { Mode = "Juggernaut", Maps = { "High Rise", "Office" }, Priority = 100 }, [[
VK's ANKM
Vk's Ankm
]])

registerRoleCategory("Juggernaut: Glaz", { Mode = "Juggernaut", Maps = { "NoskowAlleyway HELL" }, Priority = 100 }, [[
Peacemaker
]])

registerRoleCategory("Robber", { Mode = "Juggernaut", Maps = { "Private Cottage", "Forlorn Cottage" }, Priority = 78 }, [[
JS-2 Derringy
JS-22
RR-LightCombatPistol
RR-LightCombatPistol (S)
IZVEKH-412
Kamatov
HWISHH-KP9
MAK-10
]])

registerRoleCategory("Foresters", { Mode = "Juggernaut", Maps = { "Ragged Woods Campgrounds" }, Priority = 86 }, [[
Rosen-Nagan
ZKZ
Coach Shotgun
]])

registerRoleCategory("Politsiya", { Mode = "Juggernaut", Maps = { "Private Cottage", "Forlorn Cottage", "Crown PMC Warehouse", "Monobank", "High Rise", "Office" }, Priority = 85 }, [[
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

registerRoleCategory("Survivor", { Mode = "Juggernaut", Maps = { "Kualton Airport", "Monobank", "High Rise", "Office", "Camp Crystal Waters", "NoskowAlleyway HELL" }, Priority = 75 }, [[
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

registerRoleCategory("SEATO Reinforcements", { Mode = "Juggernaut", Maps = { "Kualton Airport", "Crown PMC Warehouse" }, Priority = 88 }, [[
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

registerRoleCategory("NETO Soldier", { Mode = "Juggernaut", Maps = { "Winter Offensive" }, Priority = 76 }, [[
A85L1
KAR-15
EXM-177
RR-40
HW-SpM45
]])

registerRoleCategory("NETO Reinforcements", { Mode = "Juggernaut", Maps = { "Winter Offensive" }, Priority = 84 }, [[
BF F90
BF AAL
A86M2L-SW
HW-G3a3
COLT-733
H&W-G36CC
]])

registerRoleCategory("Sharpshooter", {
    Mode = "Juggernaut / Team War",
    Maps = { "Winter Offensive", "Svetonskiy Overpass", "Nubizkyl City", "Abandoned Warehouse", "Rodinskaya Street", "Forgotten Garages", "Forgotten Gas Station", "Noskow Exchange", "Sretenskaya", "Chernaya Zone", "Dead Men Overpass" },
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

registerRoleCategory("Scavenger", { Mode = "Scav War", Maps = { "Abandoned Factory", "Kuai Pan Streets" }, Priority = 86 }, [[
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
    Maps = { "Abandoned Warehouse", "Nubizkyl City", "Rodinskaya Street", "Forgotten Garages", "Noskow Alleyway", "Svetonskiy Overpass", "Forgotten Gas Station", "Noskow Exchange", "Sretenskaya", "Chernaya Zone", "Operation Rodinskaya", "Dead Men Overpass" },
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

registerRoleCategory("Equipment Mayhem / Shared Equipment", { Mode = "Any", Priority = 10, IsNonIdentifying = true }, [[
Bear Trap
Smoke Maker
Zarye-2
]])

registerRoleCategory("Melee / Role Unknown", { Mode = "Any", Priority = 5, IsNonIdentifying = true }, [[
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

registerRoleCategory("Legacy / Admin", { Mode = "Any", Priority = 5, IsNonIdentifying = true }, [[
Factory new 52363 USD Souvenir Dragon Lore (Kingsland Precision A96A1)
Awp Dragon Lore Skin
AK47 Case-Hardened 1000000
]])

TEAM_WAR_FACTIONS = {}
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

function isRecognizedWeapon(name)
    return WEAPON_DICT[normalizeWeaponName(name)] == true
end

function isVigilanteWeapon(name)
    return VIGILANTE_GUN_DICT[normalizeWeaponName(name)] == true
end

everDroppedVigilanteTools = setmetatable({}, { __mode = "k" })
initialVigilanteOwners = setmetatable({}, { __mode = "k" })
heroPlayers = setmetatable({}, { __mode = "k" })

function resetRoundHeroTracking()
    table.clear(everDroppedVigilanteTools)
    table.clear(initialVigilanteOwners)
    table.clear(heroPlayers)
end

function getRosterRoleForWeapon(name, activeMap, activeModifier)
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
        if key == normalizeWeaponName("TG's ZVD") or key == normalizeWeaponName("Zimniy Voron") or key == normalizeWeaponName("Zimniy Voron ZVD") or key == normalizeWeaponName("JTS-225") then
            return "Juggernaut: Sharpshooter"
        end
        if roles.Sharpshooter then
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
        if roles.Foresters then
            return "Foresters"
        end
        if roles.Bystander or key == normalizeWeaponName("JS-2 Derringy") or key == normalizeWeaponName("Aluminium Bat") or key == normalizeWeaponName("Pickaxe") then
            return "Bystander"
        end
    elseif mapName == "Private Cottage" or mapName == "Forlorn Cottage" then
        if key == normalizeWeaponName("RVK") or key == normalizeWeaponName("VKAZ's RVK") or key == normalizeWeaponName("Vkaz's RVK") or key == normalizeWeaponName("Supressed Plum RVK") then
            return "Juggernaut: Former Paratrooper"
        end
        if roles.Politsiya and not roles.Robber then
            return "Politsiya"
        end
        if roles.Robber then
            return "Robber"
        end
    elseif mapName == "Kualton Airport" then
        if roles["Juggernaut: APC Driver"] then
            return "Juggernaut: APC Driver"
        end
        if roles["SEATO Reinforcements"] then
            return "SEATO Reinforcements"
        end
        if roles.Survivor then
            return "Survivor"
        end
    elseif mapName == "Crown PMC Warehouse" then
        if roles["Juggernaut: Stanislav / Mstislav"] then
            return "Juggernaut: Stanislav / Mstislav"
        end
        if roles.Politsiya or roles["SEATO Reinforcements"] then
            return "Politsiya"
        end
    elseif mapName == "Monobank" or mapName == "High Rise" or mapName == "Office" or mapName == "Camp Crystal Waters" then
        if roles.Politsiya and not roles.Survivor then
            return "Politsiya"
        end
        if roles.Survivor then
            return "Survivor"
        end
    elseif mapMode == "Scav War" then
        if roles.Scavenger or roles["Team War"] or roles.Killer or roles.Vigilante then
            return "Scavenger"
        end
    elseif mapMode == "Team War" then
        if roles.Sharpshooter then
            return "Sharpshooter"
        end
        if roles["Team War"] then
            return "Team War"
        end
    elseif mapMode == "Debt" then
        local isDetectivesMod = activeModifier == "Modifier: Detectives"
        local isSwappedMod = activeModifier == "Modifier: Swapped"
        if roles.Killer and not roles.Vigilante then
            if isSwappedMod then
                return isDetectivesMod and "Detective" or "Vigilante"
            end
            return "Killer"
        end
        if roles.Vigilante and not roles.Killer then
            if isSwappedMod then
                return "Killer"
            end
            return isDetectivesMod and "Detective" or "Vigilante"
        end
        if roles.Bystander then
            return "Bystander"
        end
    end
    if key == normalizeWeaponName("TG's ZVD") or key == normalizeWeaponName("Zimniy Voron") or key == normalizeWeaponName("Zimniy Voron ZVD") then
        return "Juggernaut: Sharpshooter"
    end
    if key == normalizeWeaponName("RVK") or key == normalizeWeaponName("VKAZ's RVK") or key == normalizeWeaponName("Supressed Plum RVK") then
        return "Juggernaut: Former Paratrooper"
    end
    if key == normalizeWeaponName("Military APC") or key == normalizeWeaponName("APC") then
        return "Juggernaut: APC Driver"
    end
    if key == normalizeWeaponName("GZHG-7.62") or key == normalizeWeaponName("GZhG-7.62 HMG") or key == normalizeWeaponName("LORD 12.7") then
        return "Juggernaut: Stanislav / Mstislav"
    end
    local bestCandidate = nil
    local bestPriority = -1
    for roleName in pairs(roles) do
        local cat = ROLE_CATEGORIES[roleName]
        if cat and not cat.IsNonIdentifying and roleName ~= "Team War" and roleName ~= "Detective" and roleName ~= "Hero" then
            local mapAllowed = (not allowedOnMap) or allowedOnMap[roleName] == true
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
    if roles.Sharpshooter then
        return "Sharpshooter"
    end
    if roles.Politsiya then
        return "Politsiya"
    end
    if roles.Foresters then
        return "Foresters"
    end
    if roles.Scavenger then
        return "Scavenger"
    end
    if roles.Bystander then
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

ROLE_ATTRIBUTE_NAMES = { "Role", "RoleName", "CurrentRole", "ModeRole", "Faction", "Class", "RoleType", "SubRole", "Job" }
KNOWN_ROLE_NAMES = {
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

pcall(function()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    for _, parent in ipairs({ CoreGui, playerGui }) do
        if parent then
            for _, guiName in ipairs({ "BloodDebtCheat", "BloodDebtCrosshair", "BloodDebtLucideDemo" }) do
                local old = parent:FindFirstChild(guiName)
                if old then
                    old:Destroy()
                end
            end
        end
    end
end)


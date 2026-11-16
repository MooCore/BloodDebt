-- Blood Debt (by I Tried At Least): Dedicated Per-Role Weapon Categories + Map-Aware Role ESP
-- + Vigilante-Only Gun Drop & Hero Pickup Tracking + KillerEscape Detection & D-Pad Down Teleport
-- + Through-Walls No-Distance L2 Aimlock + Lucide Icons & Sound System + Post-Match Crash Prevention
-- Updated for Blood Debt Version 5.1.2 ("Homecoming 2/2" / International Affairs)
if not game:IsLoaded() then
game.Loaded:Wait()
end
-- Blood Debt's PlaceId (the number in its Roblox /games/ URL).
-- Do nothing at all outside this exact place.
local TARGET_PLACE_ID = 79187287306411
if game.PlaceId ~= TARGET_PLACE_ID then
warn(string.format(
"[BloodDebt] Inactive: this script is restricted to PlaceId %d (current PlaceId: %s).",
TARGET_PLACE_ID,
tostring(game.PlaceId)
))
return
end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
-- Public Roblox API for hiding the built-in virtual gamepad pointer.
-- Guarded with pcall because availability varies across client/executor runtimes.
local GamepadService = nil
pcall(function()
GamepadService = game:GetService("GamepadService")
end)
-- ================================= Clean Re-Execution & Crash Guard =================================
-- If the script is re-executed in the same session, cleanly disconnect all previous loops,
-- RenderStep bindings, and Instance connections so stacked threads cannot freeze or crash the client.
local GLOBAL_ENV = (type(getgenv) == "function" and getgenv()) or _G
if type(GLOBAL_ENV.__BloodDebtCleanup) == "function" then
pcall(GLOBAL_ENV.__BloodDebtCleanup)
end
local ActiveConnections = {}
local PlayerConnections = {} -- [Player] = { RBXScriptConnection, ... }
local ToolAncestryConnections = setmetatable({}, { __mode = "k" }) -- [Tool] = RBXScriptConnection
local ScriptAlive = true
local function trackConnection(conn)
if conn then
table.insert(ActiveConnections, conn)
end
return conn
end
local function trackPlayerConnection(player, conn)
if not player or not conn then
return conn
end
local list = PlayerConnections[player]
if not list then
list = {}
PlayerConnections[player] = list
end
table.insert(list, conn)
return conn
end
local function disconnectPlayerConnections(player)
local list = PlayerConnections[player]
if list then
for _, conn in ipairs(list) do
pcall(function()
conn:Disconnect()
end)
end
PlayerConnections[player] = nil
end
end
-- Roblox enforces a hard engine cap of 31 active Highlight instances in the client world.
-- Exceeding 31 simultaneous Highlights causes severe rendering lag, flickering, or post-match client crashes.
local MAX_TOTAL_HIGHLIGHTS = 26
local MAX_WEAPON_HIGHLIGHTS = 10
-- ================================= Lucide Icons & Sound Assets =================================
local Icons = {
Settings = "rbxassetid://10734950309",
Crosshair = "rbxassetid://10709818534",
Eye = "rbxassetid://10723346959",
Bell = "rbxassetid://10709775704",
BellRing = "rbxassetid://10709775560",
Info = "rbxassetid://10723415903",
Warning = "rbxassetid://10709752996",
Success = "rbxassetid://10709790387",
Error = "rbxassetid://10747383819",
}
local Sounds = {
GunDrop = "rbxassetid://9114700558",
Notification = "rbxassetid://199077102",
WindowsNotification = "rbxassetid://225320558",
Popup = "rbxassetid://8486683243",
}
-- Settings
local Config = {
-- These stay disabled while the startup loading screen is running.
ESPEnabled = false,
ESPMode = "Highlight",
WeaponHighlight = false,
AimlockEnabled = false,
NREnabled = true, -- NR starts enabled, matching the supplied isModified = true state.
ScriptReady = false,
}
local refreshUIButtons
-- No world-distance cap and works through walls; selects the closest Head/RootPart to the centre crosshair.
local AIMLOCK_RADIUS_PIXELS = math.huge
local AIMLOCK_SMOOTHING = 14
local AIMLOCK_RESCAN_INTERVAL = 0.035
local AIMLOCK_SWITCH_MARGIN = 10
local Q_INPUT_DEBOUNCE = 0.20
-- ================================= Normalization Helpers =================================
local function normalizeKey(text)
return string.lower(tostring(text or "")):gsub("[^%w]", "")
end
local function normalizeWeaponName(name)
return normalizeKey(name)
end
-- ================================= Map Database & Workspace.BloodFolder Map Detection =================================
-- In Blood Debt, the active map model/folder appears directly inside Workspace:FindFirstChild("BloodFolder").
local MAP_DATABASE = {
-- ============================= JUGGERNAUT MAPS =============================
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
Aliases = { "Forlorn Cottage", "ForlornCottage" },
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
Aliases = { "NoskowAlleyway HELL", "NoskowAlleywayHELL", "Alleyway Hell" },
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
-- ============================= SCAV WAR MAPS =============================
AbandonedFactory = {
CanonicalName = "Abandoned Factory",
Mode = "Scav War",
Aliases = { "Abandoned Factory", "AbandonedFactory" },
Roles = { Default = "Scavenger" },
AllowedRoles = { ["Scavenger"] = true },
},
KuaiPanStreets = {
CanonicalName = "Kuai Pan Streets",
Mode = "Scav War",
Aliases = {
"Kuai Pan Streets", "KuaiPanStreets", "Kuai Pan", "KuaiPan", "Kuaipan", "KuanTai Streets",
},
Roles = { Default = "Scavenger" },
AllowedRoles = { ["Scavenger"] = true },
},
-- ============================= TEAM WAR MAPS =============================
AbandonedWarehouse = {
CanonicalName = "Abandoned Warehouse",
Mode = "Team War",
Aliases = {
"Abandoned Warehouse", "AbandonedWarehouse", "Warehouse", "Abandoned Building",
"AbandonedBuilding", "Abandoned Building Revamp",
},
Factions = { "Street Gang", "Heist Crew", "Bratva" },
AllowedRoles = { ["Sharpshooter"] = true, ["Team War"] = true },
},
NubizkylCity = {
CanonicalName = "Nubizkyl City",
Mode = "Team War",
Aliases = { "Nubizkyl City", "NubizkylCity", "NubzikylCity", "Nubizkyl" },
Factions = { "Bratva", "Nubagami" },
AllowedRoles = { ["Sharpshooter"] = true, ["Team War"] = true },
},
RodinskayaStreet = {
CanonicalName = "Rodinskaya Street",
Mode = "Team War",
Aliases = { "Rodinskaya Street", "RodinskayaStreet", "Rodinskya Street", "News Making", "NewsMaking" },
Factions = { "Heist Crew", "STRELA" },
AllowedRoles = { ["Sharpshooter"] = true, ["Team War"] = true },
},
ForgottenGarages = {
CanonicalName = "Forgotten Garages",
Mode = "Team War",
Aliases = { "Forgotten Garages", "ForgottenGarages" },
Factions = { "The Trinity", "The Zoo" },
AllowedRoles = { ["Sharpshooter"] = true, ["Team War"] = true },
},
NoskowAlleyway = {
CanonicalName = "Noskow Alleyway",
Mode = "Team War",
Aliases = { "Noskow Alleyway", "NoskowAlleyway", "Nuskow Alleyways", "Alleaywasy2" },
Factions = { "Hooligans", "Hobos / Homeless" },
AllowedRoles = { ["Sharpshooter"] = true, ["Team War"] = true },
},
SvetonskiyOverpass = {
CanonicalName = "Svetonskiy Overpass",
Mode = "Team War",
Aliases = {
"Svetonskiy Overpass", "SvetonskiyOverpass", "Artemovsky Overpass", "ArtemovskyOverpass",
},
Factions = { "Noobic Union Armed Forces", "Royal Kingsland Army" },
AllowedRoles = { ["Sharpshooter"] = true, ["Team War"] = true },
},
ForgottenGasStation = {
CanonicalName = "Forgotten Gas Station",
Mode = "Team War",
Aliases = { "Forgotten Gas Station", "ForgottenGasStation", "AbandonedGasStation" },
Factions = { "The Politsiya", "The Trinity", "The Zoo" },
AllowedRoles = { ["Sharpshooter"] = true, ["Team War"] = true },
},
NoskowExchange = {
CanonicalName = "Noskow Exchange",
Mode = "Team War",
Aliases = {
"Noskow Exchange", "NoskowExchange", "NOEX Noskow Exchange", "Noskow Stock Exchange",
"Noex Stock Exchange", "NOEX",
},
Factions = { "MNB", "Vanguardists", "STRELA" },
AllowedRoles = { ["Sharpshooter"] = true, ["Team War"] = true },
},
Sretenskaya = {
CanonicalName = "Sretenskaya",
Mode = "Team War",
Aliases = { "Sretenskaya", "Sretenskayá", "Stretenskaya" },
Factions = { "Worker's Army", "White Imperialist Movement" },
AllowedRoles = { ["Sharpshooter"] = true, ["Team War"] = true },
},
ChernayaZone = {
CanonicalName = "Chernaya Zone",
Mode = "Team War",
Aliases = { "Chernaya Zone", "ChernayaZone" },
Factions = { "Noobic Union Armed Forces", "Free Kaukasus Army" },
AllowedRoles = { ["Sharpshooter"] = true, ["Team War"] = true },
},
OperationRodinskaya = {
CanonicalName = "Operation Rodinskaya",
Mode = "Team War",
Aliases = { "Operation Rodinskaya", "OperationRodinskaya" },
Factions = { "ZONTIK Operators", "Amtavirus Mutants" },
AllowedRoles = { ["Sharpshooter"] = true, ["Team War"] = true },
},
DeadMenOverpass = {
CanonicalName = "Dead Men Overpass",
Mode = "Team War",
Aliases = { "Dead Men Overpass", "DeadMenOverpass" },
Factions = { "Noobic Union Armed Forces", "Royal Kingsland Army" },
AllowedRoles = { ["Sharpshooter"] = true, ["Team War"] = true },
},
-- ============================= DEBT MODE MAPS =============================
PirozhokApartments = {
CanonicalName = "Pirozhok Apartments",
Mode = "Debt",
Aliases = {
"Pirozhok Apartments", "PirozhokApartments", "Apartments V2", "Apartments new",
"NoobicUnion1999Apartments", "Noobic Union Apartments", "Apartments",
},
AllowedRoles = { ["Killer"] = true, ["Vigilante"] = true, ["Detective"] = true, ["Hero"] = true, ["Bystander"] = true },
},
HouseParty = {
CanonicalName = "House Party",
Mode = "Debt",
Aliases = { "House Party", "HouseParty", "House Party V4", "Haunted House", "HauntedHouse" },
AllowedRoles = { ["Killer"] = true, ["Vigilante"] = true, ["Detective"] = true, ["Hero"] = true, ["Bystander"] = true },
},
NubizkylMetroline = {
CanonicalName = "Nubizkyl Metroline",
Mode = "Debt",
Aliases = {
"Nubizkyl Metroline", "NubizkylMetroline", "Metro V3", "Metro v2", "Metro Station",
"Metro Line Homicide", "Metro",
},
AllowedRoles = { ["Killer"] = true, ["Vigilante"] = true, ["Detective"] = true, ["Hero"] = true, ["Bystander"] = true },
},
SmallFarmhouse = {
CanonicalName = "Small Farmhouse",
Mode = "Debt",
Aliases = {
"Small Farmhouse", "SmallFarmhouse", "NUSmallHouseFarm", "Small House Farm",
"Farm v3", "Farm", "Farmhouse", "Farm House",
},
AllowedRoles = { ["Killer"] = true, ["Vigilante"] = true, ["Detective"] = true, ["Hero"] = true, ["Bystander"] = true },
},
Penthouse = {
CanonicalName = "Penthouse",
Mode = "Debt",
Aliases = { "Penthouse", "Rooftop Penthouse", "Penthouse new" },
AllowedRoles = { ["Killer"] = true, ["Vigilante"] = true, ["Detective"] = true, ["Hero"] = true, ["Bystander"] = true },
},
KovalevskyDiner = {
CanonicalName = "Kovalevsky's Diner",
Mode = "Debt",
Aliases = {
"Kovalevsky's Diner", "KovalevskyDiner", "Kovalevsky Dinner", "Yesyes", "Diner",
},
AllowedRoles = { ["Killer"] = true, ["Vigilante"] = true, ["Detective"] = true, ["Hero"] = true, ["Bystander"] = true },
},
ResteyerokApartment = {
CanonicalName = "Resteyerok Apartment",
Mode = "Debt",
Aliases = {
"Resteyerok Apartment", "ResteyerokApartment", "Resteyerok Apartment Scamps",
"ResteyerokApartmentScamps", "Resteryok Apartments", "Scamps",
},
AllowedRoles = { ["Killer"] = true, ["Vigilante"] = true, ["Detective"] = true, ["Hero"] = true, ["Bystander"] = true },
},
TNUMinistryBuilding = {
CanonicalName = "TNU Ministry Building",
Mode = "Debt",
Aliases = {
"TNU Ministry Building", "TNUMinistryBuilding", "The Noobic Union Ministry",
"TNU Ministry", "Ministry Building", "Ministry",
},
AllowedRoles = { ["Killer"] = true, ["Vigilante"] = true, ["Detective"] = true, ["Hero"] = true, ["Bystander"] = true },
},
ThePagesCafe = {
CanonicalName = "The Pages Café",
Mode = "Debt",
Aliases = { "The Pages Café", "The Pages Cafe", "PagesCafe", "PAGESCAFE" },
AllowedRoles = { ["Killer"] = true, ["Vigilante"] = true, ["Detective"] = true, ["Hero"] = true, ["Bystander"] = true },
},
FireStation14 = {
CanonicalName = "Fire Station 14",
Mode = "Debt",
Aliases = { "Fire Station 14", "FireStation14" },
AllowedRoles = { ["Killer"] = true, ["Vigilante"] = true, ["Detective"] = true, ["Hero"] = true, ["Bystander"] = true },
},
TheseusFishingVessel = {
CanonicalName = "Theseus Fishing Vessel",
Mode = "Debt",
Aliases = { "Theseus Fishing Vessel", "TheseusFishingVessel", "Fishing Vessel", "Theseus" },
AllowedRoles = { ["Killer"] = true, ["Vigilante"] = true, ["Detective"] = true, ["Hero"] = true, ["Bystander"] = true },
},
SanguanConstruction = {
CanonicalName = "Sanguan Construction",
Mode = "Debt",
Aliases = { "Sanguan Construction", "SanguanConstruction" },
AllowedRoles = { ["Killer"] = true, ["Vigilante"] = true, ["Detective"] = true, ["Hero"] = true, ["Bystander"] = true },
},
TrinityDen = {
CanonicalName = "Trinity Den",
Mode = "Debt",
Aliases = { "Trinity Den", "TrinityDen", "Nubagami Den", "NubagamiDen" },
AllowedRoles = { ["Killer"] = true, ["Vigilante"] = true, ["Detective"] = true, ["Hero"] = true, ["Bystander"] = true },
},
SuburbanNopan = {
CanonicalName = "Suburban Nopan",
Mode = "Debt",
Aliases = { "Suburban Nopan", "SuburbanNopan" },
AllowedRoles = { ["Killer"] = true, ["Vigilante"] = true, ["Detective"] = true, ["Hero"] = true, ["Bystander"] = true },
},
RestStop = {
CanonicalName = "Rest Stop",
Mode = "Debt",
Aliases = { "Rest Stop", "RestStop" },
AllowedRoles = { ["Killer"] = true, ["Vigilante"] = true, ["Detective"] = true, ["Hero"] = true, ["Bystander"] = true },
},
KharitonovResearchStation = {
CanonicalName = "Kharitonov Research Station",
Mode = "Debt",
Aliases = { "Kharitonov Research Station", "KharitonovResearchStation" },
AllowedRoles = { ["Killer"] = true, ["Vigilante"] = true, ["Detective"] = true, ["Hero"] = true, ["Bystander"] = true },
},
MudzbillaEnterprises = {
CanonicalName = "Mudzbilla Enterprises",
Mode = "Debt",
Aliases = { "Mudzbilla Enterprises", "MudzbillaEnterprises", "Mudzbillas' Enterprise" },
AllowedRoles = { ["Killer"] = true, ["Vigilante"] = true, ["Detective"] = true, ["Hero"] = true, ["Bystander"] = true },
},
StrugatskyPark = {
CanonicalName = "Strugatsky Park",
Mode = "Debt",
Aliases = { "Strugatsky Park", "StrugatskyPark", "Pobeda Park", "PobedaPark" },
AllowedRoles = { ["Killer"] = true, ["Vigilante"] = true, ["Detective"] = true, ["Hero"] = true, ["Bystander"] = true },
},
GruzbazaWarehouse = {
CanonicalName = "Gruzbaza Warehouse",
Mode = "Debt",
Aliases = { "Gruzbaza Warehouse", "Gruzbaza Warehouse v2", "Gruzbaza" },
AllowedRoles = { ["Killer"] = true, ["Vigilante"] = true, ["Detective"] = true, ["Hero"] = true, ["Bystander"] = true },
},
SergeyevBrothersBarbery = {
CanonicalName = "Sergeyev Brothers Barbery",
Mode = "Debt",
Aliases = { "Sergeyev Brothers Barbery", "Sergevey's Brothers Barbery", "Barbery" },
AllowedRoles = { ["Killer"] = true, ["Vigilante"] = true, ["Detective"] = true, ["Hero"] = true, ["Bystander"] = true },
},
}
local MAP_ALIAS_LOOKUP = {}
local MAP_ALIAS_LIST = {}
for mapKey, mapData in pairs(MAP_DATABASE) do
mapData.Key = mapKey
for _, alias in ipairs(mapData.Aliases or { mapData.CanonicalName }) do
local norm = normalizeWeaponName(alias)
if norm ~= "" then
MAP_ALIAS_LOOKUP[norm] = mapData
table.insert(MAP_ALIAS_LIST, { Norm = norm, Data = mapData })
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
if #entry.Norm >= 4 and (string.find(normStripped, entry.Norm, 1, true) or string.find(normFull, entry.Norm, 1, true)) then
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
-- Cached map state read primarily from Workspace.BloodFolder
local cachedMapData = nil
local cachedModifierName = nil
local cachedRawMapName = nil
local lastMapScanClock = 0
local MAP_SCAN_INTERVAL = 1.0
local MAP_ATTRIBUTE_NAMES = {
"Map", "MapName", "CurrentMap", "ActiveMap", "SelectedMap", "Gamemode", "GameMode", "Mode",
}
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
-- 1. Primary source: Workspace:FindFirstChild("BloodFolder") where the active map appears in Blood Debt
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
-- First pass: direct children of Workspace.BloodFolder (the map model/folder itself)
for _, child in ipairs(children) do
if not child:IsA("Tool") and not child:IsA("Camera") and not child:IsA("Terrain") then
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
-- Second pass: 1 level deeper inside BloodFolder containers (e.g., BloodFolder.Map:GetChildren())
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
-- Landmark fallback inside BloodFolder
if not detectedMap then
if bloodFolder:FindFirstChild("Military APC", true) or bloodFolder:FindFirstChild("APC", true) then
detectedMap = MAP_DATABASE.KualtonAirport
rawMapName = "KualtonAirport"
end
end
end
-- 2. Secondary fallback: Workspace & ReplicatedStorage attributes/StringValues
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
-- ================================= Dedicated Per-Role Weapon & Equipment Categories =================================
-- Every role in Blood Debt has its own dedicated category with its exact weapon & equipment names
-- and the exact map names where that role appears.
-- ("Target" is completely removed; "Hero" is dynamically assigned when a player picks up a dropped Vigilante gun.)
local WEAPON_ROLE_LOOKUP = {}
local WEAPON_DICT = {}        -- normalized weapon name -> true (all recognized weapons)
local VIGILANTE_GUN_DICT = {} -- normalized weapon name -> true (ONLY Vigilante guns for Gun Dropped & Hero pickup)
local ROLE_CATEGORIES = {}    -- roleName -> { Weapons = {...}, Maps = {...}, MapLookup = {...}, Mode = "..." }
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
local DEBT_MAPS_LIST = {
"Pirozhok Apartments", "House Party", "Nubizkyl Metroline", "Small Farmhouse",
"Penthouse", "Kovalevsky's Diner", "Resteyerok Apartment", "TNU Ministry Building",
"The Pages Café", "Fire Station 14", "Theseus Fishing Vessel", "Sanguan Construction",
"Trinity Den", "Suburban Nopan", "Rest Stop", "Kharitonov Research Station",
"Mudzbilla Enterprises", "Strugatsky Park", "Gruzbaza Warehouse", "Sergeyev Brothers Barbery",
}
-- 1. DEBT MODE: KILLER (Appears on all Debt Mode maps)
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
-- Killer Exclusive & Debt Equipment
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
-- 2. DEBT MODE: VIGILANTE (Appears on all Debt Mode maps; ONLY these guns trigger "GUN DROPPED" & "Hero" pickup)
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
-- 3. DEBT MODE: DETECTIVE (Detectives Modifier Role — shares Vigilante weapon pool when Detectives modifier is active)
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
-- 4. DEBT MODE: HERO (Assigned to any player who picks up a dropped Vigilante gun in Debt Mode)
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
-- 5. DEBT MODE & CAMPGROUNDS: BYSTANDER (Bystander Props in Debt Mode + Wave 1 on Ragged Woods Campgrounds)
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
-- 6. JUGGERNAUT: THE BEAR (Lyudmila Rozhechuk — Ragged Woods Campgrounds)
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
-- 7. JUGGERNAUT: SHARPSHOOTER (Gennadiy Traktirnikov — Winter Offensive / NUWinterOffensive)
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
-- 8. JUGGERNAUT: FORMER PARATROOPER (Veronika Kazakova — Private Cottage / Forlorn Cottage)
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
-- 9. JUGGERNAUT: APC DRIVER (Kǎi Zhāng — Kualton Airport)
registerRoleCategory("Juggernaut: APC Driver", {
Mode = "Juggernaut",
Maps = { "Kualton Airport" },
Priority = 100,
}, [[
Military APC
APC
CIR95
]])
-- 10. JUGGERNAUT: STANISLAV / MSTISLAV (Crown PMC Warehouse / Noobic Union Offices / Office)
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
-- 11. JUGGERNAUT: ALEXEI TARASOV (Monobank / High Rise / Office)
registerRoleCategory("Juggernaut: Alexei Tarasov", {
Mode = "Juggernaut",
Maps = { "Monobank", "High Rise", "Office" },
Priority = 100,
}, [[
AT's K16A1
AT's KAR16A1
AT's KAR-15
]])
-- 12. JUGGERNAUT: RYMAN YEGOROVA (Office / High Rise)
registerRoleCategory("Juggernaut: Ryman Yegorova", {
Mode = "Juggernaut",
Maps = { "Office", "High Rise" },
Priority = 100,
}, [[
RY's GG-17
Ry's GG-17
]])
-- 13. JUGGERNAUT: VIADIMIR KOLTSOV (High Rise / Office)
registerRoleCategory("Juggernaut: Viadimir Koltsov", {
Mode = "Juggernaut",
Maps = { "High Rise", "Office" },
Priority = 100,
}, [[
VK's ANKM
Vk's Ankm
]])
-- 14. JUGGERNAUT: GLAZ (NoskowAlleyway HELL)
registerRoleCategory("Juggernaut: Glaz", {
Mode = "Juggernaut",
Maps = { "NoskowAlleyway HELL" },
Priority = 100,
}, [[
Peacemaker
]])
-- 15. JUGGERNAUT WAVE 1: ROBBER (Private Cottage / Forlorn Cottage)
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
-- 16. JUGGERNAUT WAVE 2: FORESTERS (Ragged Woods Campgrounds)
registerRoleCategory("Foresters", {
Mode = "Juggernaut",
Maps = { "Ragged Woods Campgrounds" },
Priority = 86,
}, [[
Rosen-Nagan
ZKZ
Coach Shotgun
]])
-- 17. JUGGERNAUT WAVE 2: POLITSIYA (Private Cottage, Forlorn Cottage, Crown PMC Warehouse, Monobank, High Rise, Office)
registerRoleCategory("Politsiya", {
Mode = "Juggernaut",
Maps = { "Private Cottage", "Forlorn Cottage", "Crown PMC Warehouse", "Monobank", "High Rise", "Office" },
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
-- 18. JUGGERNAUT WAVE 1: SURVIVOR (Kualton Airport, Monobank, High Rise, Office, Camp Crystal Waters, NoskowAlleyway HELL)
registerRoleCategory("Survivor", {
Mode = "Juggernaut",
Maps = { "Kualton Airport", "Monobank", "High Rise", "Office", "Camp Crystal Waters", "NoskowAlleyway HELL" },
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
-- 19. JUGGERNAUT WAVE 2: SEATO REINFORCEMENTS (Kualton Airport / Crown PMC Warehouse)
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
-- 20. JUGGERNAUT WAVE 1 & 2: NETO SOLDIER & NETO REINFORCEMENTS (Winter Offensive)
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
-- 21. SHARPSHOOTER (Winter Offensive NETO Sniper Reinforcements & Team War Marksman/Sniper Class)
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
-- 22. SCAV WAR: SCAVENGER (Abandoned Factory & Kuai Pan Streets)
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
-- 23. TEAM WAR COMBAT POOL (All Team War Maps)
registerRoleCategory("Team War", {
Mode = "Team War",
Maps = {
"Abandoned Warehouse", "Nubizkyl City", "Rodinskaya Street", "Forgotten Garages",
"Noskow Alleyway", "Svetonskiy Overpass", "Forgotten Gas Station", "Noskow Exchange",
"Sretenskaya", "Chernaya Zone", "Operation Rodinskaya", "Dead Men Overpass",
},
Priority = 60,
}, [[
-- Pistols / Sidearms
1895-Rosey
HW-SpM45
JS-2 Derringy
K1911
ZR-1
-- Submachine Guns
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
-- Assault & Battle Rifles
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
-- Shotguns
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
-- Team War Equipment
Bandages
Kunais
NGO
Shurikens
Smoke Grenades
Throwing knife
Tomahawks
]])
-- 24. EQUIPMENT MAYHEM / SHARED EQUIPMENT
registerRoleCategory("Equipment Mayhem / Shared Equipment", {
Mode = "Any",
Priority = 10,
IsNonIdentifying = true,
}, [[
Bear Trap
Smoke Maker
Zarye-2
]])
-- 25. ALL MELEE WEAPONS (29 Melees)
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
-- 26. LEGACY / ADMIN WEAPONS
registerRoleCategory("Legacy / Admin", {
Mode = "Any",
Priority = 5,
IsNonIdentifying = true,
}, [[
Factory new 52363 USD Souvenir Dragon Lore (Kingsland Precision A96A1)
Awp Dragon Lore Skin
AK47 Case-Hardened 1000000
]])
-- Team War Faction Registry (16 Factions across all Team War & Special Maps)
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
-- ================================= Dropped Vigilante Gun & Hero Pickup Tracking =================================
local everDroppedVigilanteTools = setmetatable({}, { __mode = "k" }) -- [Tool] = true
local initialVigilanteOwners = setmetatable({}, { __mode = "k" })    -- [Tool] = Player
local heroPlayers = setmetatable({}, { __mode = "k" })               -- [Player] = ToolName
local function resetRoundHeroTracking()
table.clear(everDroppedVigilanteTools)
table.clear(initialVigilanteOwners)
table.clear(heroPlayers)
end
-- Map-aware weapon-to-role resolver:
-- Strictly uses BOTH the weapon's role category AND the active map from Workspace.BloodFolder
-- so shared weapons resolve to the exact role that appears on the current map.
local function getRosterRoleForWeapon(name, activeMap, activeModifier)
local key = normalizeWeaponName(name)
local roles = WEAPON_ROLE_LOOKUP[key]
if not roles then
return nil
end
local mapMode = activeMap and activeMap.Mode or nil
local mapName = activeMap and activeMap.CanonicalName or nil
local allowedOnMap = activeMap and activeMap.AllowedRoles or nil
-- 1. Signature Juggernaut Boss weapons (always unique to their boss)
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
-- 2. Strict Map-Contextual Role Assignment (based on active map in Workspace.BloodFolder)
if mapName == "Winter Offensive" then
if key == normalizeWeaponName("TG's ZVD") or key == normalizeWeaponName("Zimniy Voron")
or key == normalizeWeaponName("Zimniy Voron ZVD") or key == normalizeWeaponName("JTS-225") then
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
if roles["Bystander"] or key == normalizeWeaponName("JS-2 Derringy")
or key == normalizeWeaponName("Aluminium Bat") or key == normalizeWeaponName("Pickaxe") then
return "Bystander"
end
elseif mapName == "Private Cottage" or mapName == "Forlorn Cottage" then
if key == normalizeWeaponName("RVK") or key == normalizeWeaponName("VKAZ's RVK")
or key == normalizeWeaponName("Vkaz's RVK") or key == normalizeWeaponName("Supressed Plum RVK") then
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
elseif mapName == "Monobank" or mapName == "High Rise" or mapName == "Office" or mapName == "Camp Crystal Waters" then
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
-- 3. Fallback when BloodFolder map is not matched yet: check signature weapons & map-allowed candidates
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
-- Note: "target" is mapped to "Bystander" so the "Target" role never appears.
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
-- ================================= Clean Up Previous UI =================================
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
-- Main ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BloodDebtCrosshair"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local guiParent = CoreGui
local parentedToCoreGui = pcall(function()
ScreenGui.Parent = CoreGui
end)
if not parentedToCoreGui then
guiParent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.Parent = guiParent
end
local function createCorner(parent, radius)
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, radius)
corner.Parent = parent
return corner
end
local function createStroke(parent, color, thickness)
local stroke = Instance.new("UIStroke")
stroke.Color = color or Color3.fromRGB(255, 45, 65)
stroke.Thickness = thickness or 1.5
stroke.Parent = parent
return stroke
end
-- ================================= Sound System =================================
local function playSound(soundId)
if not ScriptAlive or not soundId then
return
end
pcall(function()
local sound = Instance.new("Sound")
sound.SoundId = soundId
sound.Volume = 0.8
sound.Parent = SoundService
sound:Play()
sound.Ended:Connect(function()
if sound and sound.Parent then
sound:Destroy()
end
end)
task.delay(10, function()
if sound and sound.Parent then
sound:Destroy()
end
end)
end)
end
-- ================================= Lucide Notification System =================================
local notificationNumber = 0
local activeNotification = nil
local function notify(title, message, icon, soundId)
if not ScriptAlive or not ScreenGui.Parent then
return
end
notificationNumber = notificationNumber + 1
local currentNumber = notificationNumber
if activeNotification then
pcall(function()
activeNotification:Destroy()
end)
activeNotification = nil
end
local notification = Instance.new("Frame")
notification.Name = "Notification"
notification.Size = UDim2.fromOffset(310, 82)
notification.AnchorPoint = Vector2.new(1, 0)
notification.Position = UDim2.new(1, 340, 0, 25)
notification.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
notification.BorderSizePixel = 0
notification.ZIndex = 100
notification.Parent = ScreenGui
activeNotification = notification
createCorner(notification, 12)
createStroke(notification, Color3.fromRGB(255, 45, 65), 1.5)
local iconImage = Instance.new("ImageLabel")
iconImage.Size = UDim2.fromOffset(35, 35)
iconImage.Position = UDim2.fromOffset(14, 23)
iconImage.BackgroundTransparency = 1
iconImage.Image = icon or Icons.Bell
iconImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
iconImage.ScaleType = Enum.ScaleType.Fit
iconImage.ZIndex = 101
iconImage.Parent = notification
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -70, 0, 24)
titleLabel.Position = UDim2.fromOffset(60, 12)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = tostring(title)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 15
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 101
titleLabel.Parent = notification
local messageLabel = Instance.new("TextLabel")
messageLabel.Size = UDim2.new(1, -75, 0, 35)
messageLabel.Position = UDim2.fromOffset(60, 36)
messageLabel.BackgroundTransparency = 1
messageLabel.Text = tostring(message)
messageLabel.TextColor3 = Color3.fromRGB(190, 190, 198)
messageLabel.TextSize = 12
messageLabel.Font = Enum.Font.Gotham
messageLabel.TextWrapped = true
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.TextYAlignment = Enum.TextYAlignment.Top
messageLabel.ZIndex = 101
messageLabel.Parent = notification
playSound(soundId or Sounds.Notification)
TweenService:Create(
notification,
TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
{Position = UDim2.new(1, -20, 0, 25)}
):Play()
task.delay(3, function()
if currentNumber ~= notificationNumber or not notification.Parent then
return
end
local tween = TweenService:Create(
notification,
TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
{Position = UDim2.new(1, 340, 0, 25)}
)
tween:Play()
tween.Completed:Wait()
if currentNumber == notificationNumber and notification.Parent then
notification:Destroy()
if activeNotification == notification then
activeNotification = nil
end
end
end)
end
-- Centre crosshair dot
local CrosshairDot = Instance.new("Frame")
CrosshairDot.Name = "CentreDot"
CrosshairDot.AnchorPoint = Vector2.new(0.5, 0.5)
CrosshairDot.Size = UDim2.fromOffset(7, 7)
CrosshairDot.Position = UDim2.fromScale(0.5, 0.5)
CrosshairDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CrosshairDot.BorderSizePixel = 0
CrosshairDot.Parent = ScreenGui
local CrosshairCorner = Instance.new("UICorner")
CrosshairCorner.CornerRadius = UDim.new(1, 0)
CrosshairCorner.Parent = CrosshairDot
local CrosshairStroke = Instance.new("UIStroke")
CrosshairStroke.Color = Color3.fromRGB(0, 0, 0)
CrosshairStroke.Thickness = 1
CrosshairStroke.Parent = CrosshairDot
-- Startup loading card
local LOADING_DURATION = 5.5
local LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingNotification"
LoadingFrame.AnchorPoint = Vector2.new(0.5, 0)
LoadingFrame.Position = UDim2.new(0.5, 0, 0, 34)
LoadingFrame.Size = UDim2.fromOffset(330, 104)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
LoadingFrame.BackgroundTransparency = 0.04
LoadingFrame.BorderSizePixel = 0
LoadingFrame.Parent = ScreenGui
createCorner(LoadingFrame, 12)
createStroke(LoadingFrame, Color3.fromRGB(255, 45, 65), 1.5)
local LoadingTitle = Instance.new("TextLabel")
LoadingTitle.Name = "Title"
LoadingTitle.BackgroundTransparency = 1
LoadingTitle.Position = UDim2.fromOffset(16, 10)
LoadingTitle.Size = UDim2.new(1, -32, 0, 22)
LoadingTitle.Font = Enum.Font.GothamBold
LoadingTitle.Text = "BLOOD DEBT"
LoadingTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadingTitle.TextSize = 15
LoadingTitle.TextXAlignment = Enum.TextXAlignment.Left
LoadingTitle.Parent = LoadingFrame
local LoadingStatus = Instance.new("TextLabel")
LoadingStatus.Name = "Status"
LoadingStatus.BackgroundTransparency = 1
LoadingStatus.Position = UDim2.fromOffset(16, 35)
LoadingStatus.Size = UDim2.new(1, -82, 0, 18)
LoadingStatus.Font = Enum.Font.Gotham
LoadingStatus.Text = "Loading role categories & map database..."
LoadingStatus.TextColor3 = Color3.fromRGB(190, 190, 198)
LoadingStatus.TextSize = 11
LoadingStatus.TextXAlignment = Enum.TextXAlignment.Left
LoadingStatus.Parent = LoadingFrame
local LoadingPercent = Instance.new("TextLabel")
LoadingPercent.Name = "Percent"
LoadingPercent.BackgroundTransparency = 1
LoadingPercent.AnchorPoint = Vector2.new(1, 0)
LoadingPercent.Position = UDim2.new(1, -16, 0, 35)
LoadingPercent.Size = UDim2.fromOffset(52, 18)
LoadingPercent.Font = Enum.Font.GothamBold
LoadingPercent.Text = "0%"
LoadingPercent.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadingPercent.TextSize = 11
LoadingPercent.TextXAlignment = Enum.TextXAlignment.Right
LoadingPercent.Parent = LoadingFrame
local ProgressTrack = Instance.new("Frame")
ProgressTrack.Name = "ProgressTrack"
ProgressTrack.Position = UDim2.fromOffset(16, 68)
ProgressTrack.Size = UDim2.new(1, -32, 0, 9)
ProgressTrack.BackgroundColor3 = Color3.fromRGB(37, 37, 44)
ProgressTrack.BorderSizePixel = 0
ProgressTrack.Parent = LoadingFrame
local ProgressTrackCorner = Instance.new("UICorner")
ProgressTrackCorner.CornerRadius = UDim.new(1, 0)
ProgressTrackCorner.Parent = ProgressTrack
local ProgressFill = Instance.new("Frame")
ProgressFill.Name = "Fill"
ProgressFill.Size = UDim2.new(0, 0, 1, 0)
ProgressFill.BackgroundColor3 = Color3.fromRGB(255, 45, 65)
ProgressFill.BorderSizePixel = 0
ProgressFill.Parent = ProgressTrack
local ProgressFillCorner = Instance.new("UICorner")
ProgressFillCorner.CornerRadius = UDim.new(1, 0)
ProgressFillCorner.Parent = ProgressFill
-- Shared centre point used by both aimlock and object interaction.
local function getViewportCenter()
local camera = Workspace.CurrentCamera
if not camera then
return nil
end
local viewport = camera.ViewportSize
return Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
end
-- ================================= Map-Aware Role Detection & ESP =================================
local ESPObjects = {}
local function resolveExplicitRoleText(value, activeMap, activeModifier)
if type(value) ~= "string" or value == "" then
return nil
end
local normalized = normalizeWeaponName(value)
if normalized == "" or MODIFIER_LOOKUP[normalized] then
return nil
end
-- Never return "Target" role; treat Target as Bystander
if normalized == "target" then
return "Bystander"
end
if KNOWN_ROLE_NAMES[normalized] then
local mapped = KNOWN_ROLE_NAMES[normalized]
if mapped == "Vigilante" and activeModifier == "Modifier: Detectives" then
return "Detective"
end
if mapped == "Juggernaut" and activeMap and activeMap.Roles and activeMap.Roles.Juggernaut then
return activeMap.Roles.Juggernaut
end
return mapped
end
if TEAM_WAR_FACTIONS[normalized] then
return "Team War: " .. TEAM_WAR_FACTIONS[normalized]
end
return string.sub(value, 1, 42)
end
local function getRole(player)
if not player then
return "Innocent", nil
end
local activeMap, activeModifier = getCurrentMapInfo()
local character = player.Character
local backpack = player:FindFirstChild("Backpack")
-- 1. Hero Check (Highest priority in Debt Mode when a player picks up a dropped Vigilante gun):
local equippedVigilanteGun = nil
local hasBystanderProp = false
local function checkToolsForHero(container)
if not container then return end
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
-- 2. Weapon & Map-Based Role Detection (Primary source of truth for specialized roles):
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
-- If the player is on a Team War team AND has a Sharpshooter weapon, show both their Faction & Sharpshooter role
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
-- 3. Juggernaut Boss Health / Character Model Check (if boss hasn't drawn their weapon yet)
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
-- 4. Explicit Role/Class/Faction attributes or StringValues on Player or Character
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
-- 5. Map-Contextual Default Role (from Workspace.BloodFolder map)
if activeMap then
if activeMap.Mode == "Scav War" then
return "Scavenger", nil
elseif activeMap.Mode == "Juggernaut" and activeMap.Roles and activeMap.Roles.Wave1 then
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
local function getRoleDisplay(role, weaponName)
local color
if role == "Killer" then
color = Color3.fromRGB(255, 70, 70)
elseif role == "Hero" then
color = Color3.fromRGB(255, 215, 65)
elseif role == "Vigilante" or role == "Detective" or role == "Politsiya" then
color = Color3.fromRGB(85, 150, 255)
elseif string.find(role, "Juggernaut: The Bear", 1, true) then
color = Color3.fromRGB(215, 90, 45)
elseif string.find(role, "Juggernaut: Sharpshooter", 1, true) or string.find(role, "Sharpshooter", 1, true) then
color = Color3.fromRGB(0, 230, 180)
elseif string.find(role, "Juggernaut", 1, true) then
color = Color3.fromRGB(195, 105, 255)
elseif role == "Foresters" or role == "SEATO Reinforcements" or role == "NETO Reinforcements" then
color = Color3.fromRGB(75, 210, 165)
elseif string.find(role, "Team War", 1, true) then
color = Color3.fromRGB(90, 220, 220)
elseif role == "Scavenger" or role == "Robber" or role == "NETO Soldier" or role == "Survivor" then
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
local function countActivePlayerHighlights()
local count = 0
for _, esp in pairs(ESPObjects) do
if esp.Highlight and esp.Highlight.Parent and esp.Highlight.Enabled then
count = count + 1
end
end
return count
end
local function destroyPlayerESP(player)
local esp = ESPObjects[player]
if esp then
if esp.Highlight then
pcall(function()
esp.Highlight.Adornee = nil
esp.Highlight:Destroy()
end)
end
if esp.Billboard then
pcall(function()
esp.Billboard.Adornee = nil
esp.Billboard:Destroy()
end)
end
ESPObjects[player] = nil
end
end
local function clearAllPlayerESP()
for player in pairs(ESPObjects) do
destroyPlayerESP(player)
end
end
-- Parent all Highlights and BillboardGuis to ScreenGui (using .Adornee) rather than inside
-- Player.Character or Tool models. When Blood Debt destroys all characters and the map model
-- at the end of a match, Roblox's C++ Highlight renderer will NOT crash from mass-destroying
-- Character-parented Highlights during Workspace teardown!
local function createESP(player)
if not Config.ESPEnabled or not Config.ScriptReady or not ScriptAlive then
return
end
if ESPObjects[player] or player == LocalPlayer then
return
end
local character = player.Character
if not character or not character:IsDescendantOf(Workspace) then
return
end
local humanoid = character:FindFirstChildOfClass("Humanoid")
local rootPart = character:FindFirstChild("HumanoidRootPart")
if not humanoid or humanoid.Health <= 0 or not rootPart then
return
end
local highlight = nil
if countActivePlayerHighlights() < (MAX_TOTAL_HIGHLIGHTS - MAX_WEAPON_HIGHLIGHTS) then
highlight = Instance.new("Highlight")
highlight.Name = "ESPHighlight_" .. tostring(player.UserId)
highlight.Adornee = character
highlight.Enabled = Config.ESPMode == "Highlight"
highlight.FillColor = Color3.new(0, 1, 0)
highlight.FillTransparency = 1 -- Outline only; no filled interior.
highlight.OutlineColor = Color3.new(1, 1, 1)
highlight.OutlineTransparency = 0.35
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.Parent = ScreenGui
end
local billboardGui = Instance.new("BillboardGui")
billboardGui.Name = "ESPRole_" .. tostring(player.UserId)
billboardGui.Adornee = rootPart
billboardGui.Size = UDim2.new(0, 260, 0, 50)
billboardGui.AlwaysOnTop = true
billboardGui.StudsOffset = Vector3.new(0, 3.5, 0)
billboardGui.Parent = ScreenGui
local roleText = Instance.new("TextLabel")
roleText.Parent = billboardGui
roleText.Size = UDim2.new(1, 0, 1, 0)
roleText.Position = UDim2.new(0, 0, 0, 0)
roleText.Text = "Innocent"
roleText.TextColor3 = Color3.new(0, 1, 0)
roleText.BackgroundTransparency = 1
roleText.TextStrokeTransparency = 0
roleText.Font = Enum.Font.SourceSansBold
roleText.TextSize = 13
ESPObjects[player] = {
Highlight = highlight,
Billboard = billboardGui,
RoleText = roleText,
Character = character,
Humanoid = humanoid,
RootPart = rootPart,
LastUpdate = 0,
}
end
local function updateESP()
if not Config.ESPEnabled then
for _, esp in pairs(ESPObjects) do
if esp.Highlight then esp.Highlight.Enabled = false end
if esp.Billboard then esp.Billboard.Enabled = false end
end
return
end
local currentTime = os.clock()
local stalePlayers = {}
for player, esp in pairs(ESPObjects) do
local characterValid = esp.Character and esp.Character.Parent and esp.Character:IsDescendantOf(Workspace)
local humanoidValid = esp.Humanoid and esp.Humanoid.Parent and esp.Humanoid.Health > 0
local rootValid = esp.RootPart and esp.RootPart.Parent
local playerValid = player.Parent == Players and player.Character == esp.Character
if not playerValid or not characterValid or not humanoidValid or not rootValid then
table.insert(stalePlayers, player)
elseif currentTime - esp.LastUpdate > 0.6 then
esp.LastUpdate = currentTime
local role, weaponName = getRole(player)
local roleLabel, roleColor = getRoleDisplay(role, weaponName)
if esp.Highlight then
esp.Highlight.Adornee = esp.Character
esp.Highlight.Enabled = Config.ESPMode == "Highlight"
esp.Highlight.FillColor = roleColor
esp.Highlight.OutlineColor = roleColor
end
if esp.Billboard then
esp.Billboard.Adornee = esp.RootPart
esp.Billboard.Enabled = true
end
if esp.RoleText then
esp.RoleText.Text = roleLabel
esp.RoleText.TextColor3 = roleColor
end
end
end
for _, player in ipairs(stalePlayers) do
destroyPlayerESP(player)
if player.Parent == Players and player.Character then
createESP(player)
end
end
for _, player in ipairs(Players:GetPlayers()) do
if player ~= LocalPlayer and player.Character and not ESPObjects[player] then
createESP(player)
end
end
end
-- ================================= Vigilante-Only Ground Weapon Drop & Hero Pickup Tracking =================================
local trackedWorldTools = setmetatable({}, { __mode = "k" }) -- [Tool] = true
local highlightedWeapons = setmetatable({}, { __mode = "k" }) -- [Tool] = Highlight
local groundWeapons = setmetatable({}, { __mode = "k" }) -- [Tool] = BasePart
local lastDroppedWeapon = nil
local groundWeaponScanInitialized = false
local boundBloodFolder = nil
local bloodFolderConnections = {}
local function getHoldingPlayerFromTool(tool)
local parent = tool and tool.Parent
while parent and parent ~= Workspace do
if parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then
return Players:GetPlayerFromCharacter(parent)
end
if parent:IsA("Backpack") and parent.Parent and parent.Parent:IsA("Player") then
return parent.Parent
end
parent = parent.Parent
end
return nil
end
local function isWeaponInHands(tool)
return getHoldingPlayerFromTool(tool) ~= nil
end
local function getGroundWeaponPart(tool)
if not tool or not tool:IsA("Tool") or not tool:IsDescendantOf(Workspace) then
return nil
end
if isWeaponInHands(tool) then
return nil
end
local handle = tool:FindFirstChild("Handle", true)
if handle and handle:IsA("BasePart") then
return handle
end
for _, descendant in ipairs(tool:GetDescendants()) do
if descendant:IsA("BasePart") then
return descendant
end
end
return nil
end
local function hookVigilanteToolAncestry(tool)
if not tool or not tool:IsA("Tool") or not isVigilanteWeapon(tool.Name) then
return
end
-- Guard so each Tool instance only ever receives ONE AncestryChanged listener
if ToolAncestryConnections[tool] then
return
end
local conn = tool.AncestryChanged:Connect(function()
if not ScriptAlive then return end
if not tool.Parent then
local existingConn = ToolAncestryConnections[tool]
if existingConn then
ToolAncestryConnections[tool] = nil
pcall(function() existingConn:Disconnect() end)
end
return
end
local holder = getHoldingPlayerFromTool(tool)
if holder then
if everDroppedVigilanteTools[tool] then
heroPlayers[holder] = tool.Name
elseif not initialVigilanteOwners[tool] then
initialVigilanteOwners[tool] = holder
elseif initialVigilanteOwners[tool] ~= holder then
heroPlayers[holder] = tool.Name
end
else
local bloodFolder = Workspace:FindFirstChild("BloodFolder")
if bloodFolder and tool:IsDescendantOf(bloodFolder) then
everDroppedVigilanteTools[tool] = true
trackedWorldTools[tool] = true
end
end
end)
ToolAncestryConnections[tool] = conn
trackConnection(conn)
end
local function registerCandidateTool(instance)
if instance and instance:IsA("Tool") and isVigilanteWeapon(instance.Name) then
trackedWorldTools[instance] = true
everDroppedVigilanteTools[instance] = true
hookVigilanteToolAncestry(instance)
end
end
local function unregisterCandidateTool(instance)
if not instance then return end
trackedWorldTools[instance] = nil
groundWeapons[instance] = nil
local hl = highlightedWeapons[instance]
if hl then
pcall(function()
hl.Adornee = nil
hl:Destroy()
end)
highlightedWeapons[instance] = nil
end
if lastDroppedWeapon == instance then
lastDroppedWeapon = nil
end
end
local function clearAllWeaponHighlights()
for weapon, highlight in pairs(highlightedWeapons) do
pcall(function()
highlight.Adornee = nil
highlight:Destroy()
end)
highlightedWeapons[weapon] = nil
end
end
local function bindBloodFolderEvents(folder)
if boundBloodFolder == folder then
return
end
for _, conn in ipairs(bloodFolderConnections) do
pcall(function() conn:Disconnect() end)
end
table.clear(bloodFolderConnections)
table.clear(trackedWorldTools)
table.clear(groundWeapons)
clearAllWeaponHighlights()
resetRoundHeroTracking()
boundBloodFolder = folder
if not folder then
return
end
-- Seed existing dropped Vigilante tools in BloodFolder
local ok, descendants = pcall(function()
return folder:GetDescendants()
end)
if ok and descendants then
for _, inst in ipairs(descendants) do
registerCandidateTool(inst)
end
end
local addConn = folder.DescendantAdded:Connect(function(inst)
if not ScriptAlive then return end
if inst.Parent == folder and (inst:IsA("Model") or inst:IsA("Folder")) then
lastMapScanClock = 0
resetRoundHeroTracking()
clearAllWeaponHighlights()
end
if inst:IsA("Tool") then
registerCandidateTool(inst)
elseif inst:IsA("BasePart") and inst.Parent and inst.Parent:IsA("Tool") then
registerCandidateTool(inst.Parent)
end
end)
local remConn = folder.DescendantRemoving:Connect(function(inst)
if not ScriptAlive then return end
if inst.Parent == folder and (inst:IsA("Model") or inst:IsA("Folder")) then
lastMapScanClock = 0
clearAllWeaponHighlights()
end
if trackedWorldTools[inst] then
local droppedTool = inst
task.defer(function()
if droppedTool and droppedTool.Parent then
local holder = getHoldingPlayerFromTool(droppedTool)
if holder then
everDroppedVigilanteTools[droppedTool] = true
heroPlayers[holder] = droppedTool.Name
end
end
end)
unregisterCandidateTool(inst)
end
end)
table.insert(bloodFolderConnections, addConn)
table.insert(bloodFolderConnections, remConn)
trackConnection(addConn)
trackConnection(remConn)
end
local function refreshGroundWeaponRegistry()
local bloodFolder = Workspace:FindFirstChild("BloodFolder")
if bloodFolder ~= boundBloodFolder then
bindBloodFolderEvents(bloodFolder)
end
local currentGroundWeapons = {}
local toolsToRemove = {}
for tool in pairs(trackedWorldTools) do
if not tool or not tool.Parent or not tool:IsDescendantOf(Workspace) then
local holder = tool and getHoldingPlayerFromTool(tool)
if holder and everDroppedVigilanteTools[tool] then
heroPlayers[holder] = tool.Name
end
table.insert(toolsToRemove, tool)
elseif isWeaponInHands(tool) then
local holder = getHoldingPlayerFromTool(tool)
if holder and everDroppedVigilanteTools[tool] then
heroPlayers[holder] = tool.Name
end
table.insert(toolsToRemove, tool)
elseif isVigilanteWeapon(tool.Name) then
local part = getGroundWeaponPart(tool)
if part then
everDroppedVigilanteTools[tool] = true
currentGroundWeapons[tool] = part
if groundWeaponScanInitialized and not groundWeapons[tool] then
lastDroppedWeapon = tool
notify(
"Vigilante Gun Dropped",
tool.Name .. " is on the ground! (D-Pad Right to teleport)",
Icons.BellRing,
Sounds.GunDrop
)
end
end
end
end
for _, tool in ipairs(toolsToRemove) do
unregisterCandidateTool(tool)
end
groundWeapons = currentGroundWeapons
groundWeaponScanInitialized = true
end
local function updateWeaponHighlight()
if not Config.WeaponHighlight then
clearAllWeaponHighlights()
return
end
local activeHighlightCount = 0
local staleTools = {}
for weapon, highlight in pairs(highlightedWeapons) do
if not weapon or not weapon.Parent or not weapon:IsDescendantOf(Workspace)
or isWeaponInHands(weapon) or not isVigilanteWeapon(weapon.Name)
or not highlight or not highlight.Parent then
table.insert(staleTools, weapon)
else
activeHighlightCount = activeHighlightCount + 1
end
end
for _, weapon in ipairs(staleTools) do
local hl = highlightedWeapons[weapon]
if hl then
pcall(function()
hl.Adornee = nil
hl:Destroy()
end)
end
highlightedWeapons[weapon] = nil
end
for tool in pairs(groundWeapons) do
if activeHighlightCount >= MAX_WEAPON_HIGHLIGHTS then
break
end
if isVigilanteWeapon(tool.Name) and not highlightedWeapons[tool] and not isWeaponInHands(tool) then
local highlight = Instance.new("Highlight")
highlight.Name = "ToolESP"
highlight.Adornee = tool
highlight.FillColor = Color3.new(1, 1, 0)
highlight.FillTransparency = 1 -- Outline only; no filled interior.
highlight.OutlineColor = Color3.new(1, 1, 0)
highlight.OutlineTransparency = 0.15
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.Parent = ScreenGui
highlightedWeapons[tool] = highlight
activeHighlightCount = activeHighlightCount + 1
end
end
end
local function chooseGroundWeapon()
if lastDroppedWeapon and isVigilanteWeapon(lastDroppedWeapon.Name) then
local lastPart = groundWeapons[lastDroppedWeapon]
if lastPart and lastPart.Parent and getGroundWeaponPart(lastDroppedWeapon) then
return lastDroppedWeapon, lastPart
end
lastDroppedWeapon = nil
end
local character = LocalPlayer.Character
local rootPart = character and character:FindFirstChild("HumanoidRootPart")
local chosenTool, chosenPart = nil, nil
local closestDistance = math.huge
for tool, part in pairs(groundWeapons) do
if isVigilanteWeapon(tool.Name) and part and part.Parent and getGroundWeaponPart(tool) then
local distance = rootPart and (part.Position - rootPart.Position).Magnitude or 0
if distance < closestDistance then
closestDistance = distance
chosenTool, chosenPart = tool, part
end
end
end
return chosenTool, chosenPart
end
local teleportToGroundWeaponBusy = false
local function teleportToGroundWeapon()
if not Config.ScriptReady or teleportToGroundWeaponBusy then
return
end
teleportToGroundWeaponBusy = true
task.delay(0.35, function()
teleportToGroundWeaponBusy = false
end)
refreshGroundWeaponRegistry()
local tool, targetPart = chooseGroundWeapon()
if not tool or not targetPart then
notify("No Vigilante Gun", "There is no Vigilante gun on the ground.", Icons.Warning, Sounds.WindowsNotification)
return
end
local character = LocalPlayer.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
local rootPart = character and character:FindFirstChild("HumanoidRootPart")
if not character or not character.Parent or not humanoid or humanoid.Health <= 0 or not rootPart then
notify("Teleport Failed", "Your character is not available.", Icons.Error, Sounds.WindowsNotification)
return
end
local confirmedPart = getGroundWeaponPart(tool)
if not confirmedPart then
refreshGroundWeaponRegistry()
notify("No Vigilante Gun", "The ground gun is no longer available.", Icons.Warning, Sounds.WindowsNotification)
return
end
local pos = confirmedPart.Position
if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z or pos.Magnitude > 1e6 then
notify("Teleport Failed", "Invalid weapon coordinates.", Icons.Error, Sounds.WindowsNotification)
return
end
local currentPivot = character:GetPivot()
local destination = pos + Vector3.new(0, 3, 0)
local targetPivot = CFrame.new(destination) * currentPivot.Rotation
local ok, err = pcall(function()
rootPart.AssemblyLinearVelocity = Vector3.zero
rootPart.AssemblyAngularVelocity = Vector3.zero
character:PivotTo(targetPivot)
end)
if ok then
notify("Teleported", "Moved to " .. tool.Name, Icons.Success, Sounds.Popup)
else
warn("[BloodDebt] Ground-weapon teleport failed: " .. tostring(err))
notify("Teleport Failed", "The character could not be moved.", Icons.Error, Sounds.WindowsNotification)
end
end
-- ================================= KillerEscape Detection & D-Pad Down Teleport =================================
-- Detects Workspace.KillerEscape -> Escape (or inside Workspace.BloodFolder.KillerEscape -> Escape)
-- Alerts when the Killer Escape opens and teleports LocalPlayer to it when pressing D-Pad Down.
local killerEscapeNotifiedForInstance = nil
local teleportToKillerEscapeBusy = false
local function resolveEscapeTargetPosition(escapeObj)
if not escapeObj then
return nil, nil
end
if escapeObj:IsA("BasePart") then
return escapeObj.Position, escapeObj
end
if escapeObj:IsA("Model") then
if escapeObj.PrimaryPart then
return escapeObj.PrimaryPart.Position, escapeObj.PrimaryPart
end
local part = escapeObj:FindFirstChildWhichIsA("BasePart", true)
if part then
return part.Position, part
end
local ok, pivot = pcall(function()
return escapeObj:GetPivot()
end)
if ok and pivot then
return pivot.Position, escapeObj
end
end
local childPart = escapeObj:FindFirstChildWhichIsA("BasePart", true)
if childPart then
return childPart.Position, childPart
end
return nil, nil
end
local function findKillerEscapeTarget()
-- 1. Check Workspace:FindFirstChild("KillerEscape") first as specified
local killerEscapeFolder = Workspace:FindFirstChild("KillerEscape")
if not killerEscapeFolder then
local bloodFolder = Workspace:FindFirstChild("BloodFolder")
if bloodFolder then
killerEscapeFolder = bloodFolder:FindFirstChild("KillerEscape", true)
end
end
if not killerEscapeFolder then
return nil, nil
end
-- Look for "Escape" under KillerEscape
local escapeObj = killerEscapeFolder:FindFirstChild("Escape") or killerEscapeFolder:FindFirstChild("Escape", true)
if escapeObj then
local pos, targetInst = resolveEscapeTargetPosition(escapeObj)
if pos then
return pos, targetInst
end
end
-- Fallback: if KillerEscape itself has a BasePart child while active
local fallbackPos, fallbackInst = resolveEscapeTargetPosition(killerEscapeFolder)
if fallbackPos then
return fallbackPos, fallbackInst
end
return nil, nil
end
local function checkKillerEscapeAvailability()
if not Config.ScriptReady or not ScriptAlive then
return
end
local pos, escapeInst = findKillerEscapeTarget()
if pos and escapeInst then
if killerEscapeNotifiedForInstance ~= escapeInst then
killerEscapeNotifiedForInstance = escapeInst
notify(
"Killer Escape Available",
"Press D-Pad Down to teleport to Killer Escape!",
Icons.BellRing,
Sounds.Popup
)
end
else
killerEscapeNotifiedForInstance = nil
end
end
local function teleportToKillerEscape()
if not Config.ScriptReady or teleportToKillerEscapeBusy then
return
end
teleportToKillerEscapeBusy = true
task.delay(0.35, function()
teleportToKillerEscapeBusy = false
end)
local pos, escapeInst = findKillerEscapeTarget()
if not pos or not escapeInst then
notify(
"Escape Unavailable",
"KillerEscape.Escape is not available right now.",
Icons.Warning,
Sounds.WindowsNotification
)
return
end
local character = LocalPlayer.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
local rootPart = character and character:FindFirstChild("HumanoidRootPart")
if not character or not character.Parent or not humanoid or humanoid.Health <= 0 or not rootPart then
notify("Teleport Failed", "Your character is not available.", Icons.Error, Sounds.WindowsNotification)
return
end
if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z or pos.Magnitude > 1e6 then
notify("Teleport Failed", "Invalid KillerEscape coordinates.", Icons.Error, Sounds.WindowsNotification)
return
end
local currentPivot = character:GetPivot()
local destination = pos + Vector3.new(0, 3, 0)
local targetPivot = CFrame.new(destination) * currentPivot.Rotation
local ok, err = pcall(function()
rootPart.AssemblyLinearVelocity = Vector3.zero
rootPart.AssemblyAngularVelocity = Vector3.zero
character:PivotTo(targetPivot)
end)
if ok then
notify("Killer Escape", "Teleported to Killer Escape!", Icons.Success, Sounds.Popup)
else
warn("[BloodDebt] KillerEscape teleport failed: " .. tostring(err))
notify("Teleport Failed", "Could not move character to Killer Escape.", Icons.Error, Sounds.WindowsNotification)
end
end
-- ================================= Aimlock: Hold L2 / LT (Works Through Walls, No Distance Cap) =================================
local aimlockHeld = false
local aimlockTriggerDown = false
local aimTargetPlayer = nil
local aimTargetPart = nil
local smoothedAimPosition = nil
local nextAimScanAt = 0
local function getCharacterParts(player)
if not player or player == LocalPlayer then
return nil, nil, nil, nil
end
local character = player.Character
if not character or not character.Parent then
return nil, nil, nil, nil
end
local humanoid = character:FindFirstChildOfClass("Humanoid")
local head = character:FindFirstChild("Head")
local rootPart = character:FindFirstChild("HumanoidRootPart")
if not humanoid or humanoid.Health <= 0 or (not head and not rootPart) then
return nil, nil, nil, nil
end
return character, humanoid, head, rootPart
end
-- Works through walls and has NO world-distance requirement!
-- Evaluates every living player's Head and HumanoidRootPart in front of the camera (Z > 0)
-- and picks the one closest to the centre crosshair.
local function getClosestAimPartToCrosshair()
local camera = Workspace.CurrentCamera
local center = getViewportCenter()
if not camera or not center then
return nil, nil, math.huge
end
local bestPlayer = nil
local bestPart = nil
local bestDistance = AIMLOCK_RADIUS_PIXELS
for _, player in ipairs(Players:GetPlayers()) do
if player ~= LocalPlayer then
local character, _, head, rootPart = getCharacterParts(player)
if character then
local candidates = {}
if head then table.insert(candidates, head) end
if rootPart then table.insert(candidates, rootPart) end
for _, targetPart in ipairs(candidates) do
local screenPosition, _ = camera:WorldToViewportPoint(targetPart.Position)
-- Only require Z > 0 (in front of camera); works through walls and at any distance!
if screenPosition.Z > 0 then
local screenDistance = (Vector2.new(screenPosition.X, screenPosition.Y) - center).Magnitude
if screenDistance < bestDistance then
bestDistance = screenDistance
bestPlayer = player
bestPart = targetPart
end
end
end
end
end
end
return bestPlayer, bestPart, bestDistance
end
local function getScreenDistance(part, camera)
if not part or not part.Parent or not camera then
return math.huge
end
local center = getViewportCenter()
if not center then
return math.huge
end
local screenPosition, _ = camera:WorldToViewportPoint(part.Position)
if screenPosition.Z <= 0 then
return math.huge
end
return (Vector2.new(screenPosition.X, screenPosition.Y) - center).Magnitude
end
local function isAimTargetValid()
if not aimTargetPlayer or not aimTargetPart then
return false
end
local character, humanoid = getCharacterParts(aimTargetPlayer)
return character ~= nil
and humanoid ~= nil
and aimTargetPart.Parent ~= nil
and aimTargetPart:IsDescendantOf(character)
end
local function startAimlockHold()
if not Config.ScriptReady or not Config.AimlockEnabled or not aimlockTriggerDown then
return
end
aimlockHeld = true
aimTargetPlayer, aimTargetPart = getClosestAimPartToCrosshair()
smoothedAimPosition = aimTargetPart and aimTargetPart.Position or nil
nextAimScanAt = 0
end
local function stopAimlockHold()
aimlockHeld = false
aimTargetPlayer = nil
aimTargetPart = nil
smoothedAimPosition = nil
end
pcall(function()
RunService:UnbindFromRenderStep("BloodDebt_AimLock")
end)
-- Run after Roblox's camera update with NaN / zero-vector CFrame protection so camera math never crashes the client.
RunService:BindToRenderStep("BloodDebt_AimLock", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
if not Config.AimlockEnabled or not Config.ScriptReady or not aimlockHeld or not ScriptAlive then
return
end
local camera = Workspace.CurrentCamera
if not camera then
return
end
local now = os.clock()
if now >= nextAimScanAt then
nextAimScanAt = now + AIMLOCK_RESCAN_INTERVAL
local candidatePlayer, candidatePart, candidateDistance = getClosestAimPartToCrosshair()
if candidatePlayer and candidatePart then
local currentDistance = getScreenDistance(aimTargetPart, camera)
local sameCandidate = candidatePlayer == aimTargetPlayer and candidatePart == aimTargetPart
local switchMargin = candidatePlayer == aimTargetPlayer and 3 or AIMLOCK_SWITCH_MARGIN
if not isAimTargetValid()
or sameCandidate
or candidateDistance + switchMargin < currentDistance then
if not sameCandidate then
aimTargetPlayer = candidatePlayer
aimTargetPart = candidatePart
end
end
elseif not isAimTargetValid() then
aimTargetPlayer = nil
aimTargetPart = nil
end
end
if not isAimTargetValid() then
aimTargetPlayer, aimTargetPart = getClosestAimPartToCrosshair()
smoothedAimPosition = nil
end
if not aimTargetPart then
return
end
local targetPosition = aimTargetPart.Position
local dt = math.clamp(tonumber(deltaTime) or 0.016, 0.0001, 0.25)
local positionAlpha = math.clamp(1 - math.exp(-AIMLOCK_SMOOTHING * dt), 0, 1)
if not smoothedAimPosition then
smoothedAimPosition = targetPosition
else
smoothedAimPosition = smoothedAimPosition:Lerp(targetPosition, positionAlpha)
end
local camPos = camera.CFrame.Position
local offset = smoothedAimPosition - camPos
if offset.Magnitude < 0.05 or offset.X ~= offset.X then
return
end
local desiredCFrame = CFrame.lookAt(camPos, smoothedAimPosition, camera.CFrame.UpVector)
camera.CFrame = camera.CFrame:Lerp(desiredCFrame, positionAlpha)
end)
-- ================================= Centre-ray interaction / controller X -> Q =================================
local qBusy = false
local virtualInput = nil
local virtualInputUnavailableWarned = false
local executorKeyPress = type(keypress) == "function" and keypress or nil
local executorKeyRelease = type(keyrelease) == "function" and keyrelease or nil
local executorMouseMove = type(mousemoveabs) == "function" and mousemoveabs or nil
local virtualInputOK, virtualInputResult = pcall(function()
return UserInputService:CreateVirtualInput()
end)
if virtualInputOK then
virtualInput = virtualInputResult
end
local function raycastFromCrosshair()
local camera = Workspace.CurrentCamera
local center = getViewportCenter()
if not camera or not center then
return nil, nil
end
local unitRay = camera:ViewportPointToRay(center.X, center.Y)
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
if LocalPlayer.Character then
raycastParams.FilterDescendantsInstances = { LocalPlayer.Character }
else
raycastParams.FilterDescendantsInstances = {}
end
raycastParams.IgnoreWater = true
local result = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, raycastParams)
return result, center
end
local function isPlayerCharacterPart(instance)
local current = instance
while current and current ~= Workspace do
if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then
return Players:GetPlayerFromCharacter(current) ~= nil
end
current = current.Parent
end
return false
end
local function getPromptFromHit(hitInstance)
local current = hitInstance
while current and current ~= Workspace do
local prompt = current:FindFirstChildWhichIsA("ProximityPrompt", true)
if prompt then
return prompt
end
current = current.Parent
end
return nil
end
local function activateProximityPrompt(prompt)
if not prompt or not prompt.Parent or not prompt.Enabled then
return false
end
if type(fireproximityprompt) == "function" then
local ok = pcall(fireproximityprompt, prompt)
if ok then
return true
end
end
local beganOK = pcall(function()
prompt:InputHoldBegin()
end)
if not beganOK then
return false
end
local holdTime = math.max(prompt.HoldDuration, 0.05)
task.delay(holdTime, function()
if prompt and prompt.Parent then
pcall(function()
prompt:InputHoldEnd()
end)
end
end)
return true
end
local function sendQToGame(center)
if executorKeyPress and executorKeyRelease and executorMouseMove then
task.spawn(function()
local ok, err = pcall(function()
executorMouseMove(center.X, center.Y)
RunService.RenderStepped:Wait()
executorKeyPress(0x51)
task.wait(0.06)
executorKeyRelease(0x51)
end)
if not ok then
warn("[BloodDebt] Executor key bridge failed: " .. tostring(err))
end
end)
return true
end
if virtualInput then
task.spawn(function()
local ok, err = pcall(function()
virtualInput:SendMousePosition(center)
RunService.RenderStepped:Wait()
virtualInput:SendKey(true, Enum.KeyCode.Q, false)
task.wait(0.06)
virtualInput:SendKey(false, Enum.KeyCode.Q, false)
end)
if not ok then
warn("[BloodDebt] Could not send virtual Q input: " .. tostring(err))
end
end)
return true
end
if not virtualInputUnavailableWarned then
virtualInputUnavailableWarned = true
warn("[BloodDebt] No key injection bridge is available. Controller X cannot be converted to Q in this executor/client.")
end
return false
end
local function findDoorEventFromHit(hitInstance)
local bloodFolder = Workspace:FindFirstChild("BloodFolder")
if not bloodFolder or not hitInstance or not hitInstance:IsDescendantOf(bloodFolder) then
return nil, nil
end
local ancestor = hitInstance
while ancestor and ancestor ~= bloodFolder do
if string.lower(ancestor.Name) == "lock" then
local lockEvent = ancestor:FindFirstChild("DoorEventyer", true)
if lockEvent and lockEvent:IsA("RemoteEvent") then
return lockEvent, "Lock"
end
break
end
ancestor = ancestor.Parent
end
ancestor = hitInstance
while ancestor and ancestor ~= bloodFolder do
local scopeName = string.lower(ancestor.Name)
if scopeName == "maindoor" or scopeName == "mayndoor" then
local doorEvents = {}
for _, descendant in ipairs(ancestor:GetDescendants()) do
if descendant.Name == "DoorEventyer" and descendant:IsA("RemoteEvent") then
local insideLock = false
local parent = descendant.Parent
while parent and parent ~= ancestor do
if string.lower(parent.Name) == "lock" then
insideLock = true
break
end
parent = parent.Parent
end
if not insideLock then
table.insert(doorEvents, descendant)
end
end
end
if #doorEvents == 1 then
return doorEvents[1], "Door"
end
if #doorEvents > 1 then
return nil, nil
end
end
ancestor = ancestor.Parent
end
ancestor = hitInstance
while ancestor and ancestor ~= bloodFolder do
local candidate = ancestor:FindFirstChild("DoorEventyer")
if candidate and candidate:IsA("RemoteEvent") then
return candidate, "Door"
end
ancestor = ancestor.Parent
end
return nil, nil
end
local function fireDoorOrLockEvent(hitInstance)
local event, eventKind = findDoorEventFromHit(hitInstance)
if not event then
return false
end
local normalId = eventKind == "Lock" and Enum.NormalId.Front or Enum.NormalId.Back
local ok, err = pcall(function()
event:FireServer(normalId)
end)
if not ok then
warn("[BloodDebt] " .. eventKind .. " event failed: " .. tostring(err))
return false
end
return true
end
local function handleControllerQ()
if not Config.ScriptReady or qBusy then
return
end
qBusy = true
task.delay(Q_INPUT_DEBOUNCE, function()
qBusy = false
end)
local result, center = raycastFromCrosshair()
if not result or not result.Instance or not center then
return
end
if isPlayerCharacterPart(result.Instance) then
return
end
if fireDoorOrLockEvent(result.Instance) then
return
end
if sendQToGame(center) then
return
end
local prompt = getPromptFromHit(result.Instance)
if prompt then
activateProximityPrompt(prompt)
end
end
local function toggleAimlockFromController()
if not Config.ScriptReady then
return
end
Config.AimlockEnabled = not Config.AimlockEnabled
if Config.AimlockEnabled then
startAimlockHold()
else
stopAimlockHold()
end
if refreshUIButtons then
refreshUIButtons()
end
notify(
"Aimlock",
Config.AimlockEnabled and "Aimlock enabled (through walls, no distance limit)." or "Aimlock disabled.",
Config.AimlockEnabled and Icons.Success or Icons.Info,
Sounds.Notification
)
end
local lastDPadLeftAt = 0
local lastDPadRightAt = 0
local lastDPadDownAt = 0
local CONTROLLER_PRESS_DEBOUNCE = 0.20
local function onDPadLeftAction(_, inputState)
if inputState == Enum.UserInputState.Begin then
local now = os.clock()
if now - lastDPadLeftAt >= CONTROLLER_PRESS_DEBOUNCE then
lastDPadLeftAt = now
toggleAimlockFromController()
end
end
return Enum.ContextActionResult.Sink
end
local function onDPadRightAction(, inputState)
if inputState == Enum.UserInputState.Begin then
local now = os.clock()
if now - lastDPadRightAt >= CONTROLLER_PRESS_DEBOUNCE then
lastDPadRightAt = now
teleportToGroundWeapon()
end
end
return Enum.ContextActionResult.Sink
end
local function onDPadDownAction(, inputState)
if inputState == Enum.UserInputState.Begin then
local now = os.clock()
if now - lastDPadDownAt >= CONTROLLER_PRESS_DEBOUNCE then
lastDPadDownAt = now
teleportToKillerEscape()
end
end
return Enum.ContextActionResult.Sink
end
pcall(function()
ContextActionService:UnbindAction("BloodDebt_ToggleAimlock")
ContextActionService:UnbindAction("BloodDebt_TeleportToGroundGun")
ContextActionService:UnbindAction("BloodDebt_TeleportToKillerEscape")
end)
local dPadLeftBound = pcall(function()
ContextActionService:BindActionAtPriority(
"BloodDebt_ToggleAimlock",
onDPadLeftAction,
false,
Enum.ContextActionPriority.High.Value + 1000,
Enum.KeyCode.DPadLeft
)
end)
local dPadRightBound = pcall(function()
ContextActionService:BindActionAtPriority(
"BloodDebt_TeleportToGroundGun",
onDPadRightAction,
false,
Enum.ContextActionPriority.High.Value + 1000,
Enum.KeyCode.DPadRight
)
end)
local dPadDownBound = pcall(function()
ContextActionService:BindActionAtPriority(
"BloodDebt_TeleportToKillerEscape",
onDPadDownAction,
false,
Enum.ContextActionPriority.High.Value + 1000,
Enum.KeyCode.DPadDown
)
end)
if not dPadLeftBound or not dPadRightBound or not dPadDownBound then
warn("[BloodDebt] Could not bind one or more D-pad actions through ContextActionService.")
end
trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
if input.KeyCode == Enum.KeyCode.ButtonL2 then
aimlockTriggerDown = true
startAimlockHold()
return
end
if input.KeyCode == Enum.KeyCode.DPadLeft then
onDPadLeftAction("BloodDebt_ToggleAimlock", Enum.UserInputState.Begin, input)
return
elseif input.KeyCode == Enum.KeyCode.DPadRight then
onDPadRightAction("BloodDebt_TeleportToGroundGun", Enum.UserInputState.Begin, input)
return
elseif input.KeyCode == Enum.KeyCode.DPadDown then
onDPadDownAction("BloodDebt_TeleportToKillerEscape", Enum.UserInputState.Begin, input)
return
end
if input.KeyCode == Enum.KeyCode.ButtonX and Config.ScriptReady then
handleControllerQ()
end
end))
trackConnection(UserInputService.InputEnded:Connect(function(input)
if input.KeyCode == Enum.KeyCode.ButtonL2 then
aimlockTriggerDown = false
stopAimlockHold()
end
end))
trackConnection(UserInputService.WindowFocusReleased:Connect(function()
aimlockTriggerDown = false
stopAimlockHold()
end))
-- ================================= Crash-Safe NR / Executor Actor Injection =================================
-- IMPORTANT POST-MATCH CRASH PREVENTION:
-- Many executors crash if ⁠run_on_actor⁠ is called on an Actor that is being destroyed at round end,
-- or if ⁠getactors()⁠ is polled in a loop across round transitions.
-- We ONLY inject on Actors currently parented inside a live Tool in LocalPlayer.Character or LocalPlayer.Backpack,
-- verify the Actor is still alive after a 0.5s settling delay, and never poll ⁠getactors()⁠ in a background loop!
local nrNoActorWarned = false
local nrInjectionQueued = false
local nrActorAppliedState = setmetatable({}, { __mode = "k" })
local executorRunOnActor = nil
pcall(function()
if type(runonactor) == "function" then
executorRunOnActor = runonactor
elseif type(run_on_actor) == "function" then
executorRunOnActor = run_on_actor
elseif type(actor) == "table" and type(actor.runonactor) == "function" then
executorRunOnActor = actor.runonactor
elseif type(actor) == "table" and type(actor.run_on_actor) == "function" then
executorRunOnActor = actor.run_on_actor
end
end)
local function isAliveLocalWeaponActor(obj)
if not obj then return false end
local ok, valid = pcall(function()
if not obj.Parent or not obj:IsA("Actor") then
return false
end
if not obj:FindFirstChild("weap_cl", true) then
return false
end
local char = LocalPlayer.Character
local humanoid = char and char:FindFirstChildOfClass("Humanoid")
if char and humanoid and humanoid.Health > 0 and obj:IsDescendantOf(char) then
return true
end
local backpack = LocalPlayer:FindFirstChild("Backpack")
if backpack and obj:IsDescendantOf(backpack) then
return true
end
return false
end)
return ok and valid
end
local function getActiveWeaponActors()
local actors = {}
local seen = {}
local function scanContainer(container)
if not container or not container.Parent then return end
local ok, descendants = pcall(function()
return container:GetDescendants()
end)
if not ok or not descendants then return end
for _, obj in ipairs(descendants) do
if not seen[obj] and isAliveLocalWeaponActor(obj) then
seen[obj] = true
table.insert(actors, obj)
end
end
end
scanContainer(LocalPlayer.Character)
scanContainer(LocalPlayer:FindFirstChild("Backpack"))
return actors
end
local function makeNRActorSource()
local recoilScale = Config.NREnabled and 0 or 1
local disableAnims = Config.NREnabled
return string.format([[
local RECOIL_SCALE = %f
local DISABLE_ANIMS = %s
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local success, sharedLib = pcall(function()
local gunRes = ReplicatedStorage:FindFirstChild("gun_res")
local lib = gunRes and gunRes:FindFirstChild("lib")
local sharedMod = lib and lib:FindFirstChild("shared")
return sharedMod and require(sharedMod) or nil
end)
if success and sharedLib and type(sharedLib.getStat) == "function" then
if not sharedLib._oldGetStat then
sharedLib._oldGetStat = sharedLib.getStat
sharedLib.getStat = function(p1, p2, ...)
local ok, result = pcall(sharedLib._oldGetStat, p1, p2, ...)
if not ok then
return nil
end
if p2 == "mult" or p2 == "recoilMult" then
if type(result) == "number" then
return result * (sharedLib._RECOIL_SCALE or 1)
end
end
if sharedLib._DISABLE_ANIMS and (p2 == "fire" or p2 == "adsFire" or p2 == "Stockedfire") then
return ""
end
return result
end
end
sharedLib._RECOIL_SCALE = RECOIL_SCALE
sharedLib._DISABLE_ANIMS = DISABLE_ANIMS
end
]], recoilScale, tostring(disableAnims))
end
local function runNRInjection()
if not Config.ScriptReady or not ScriptAlive then
return 0
end
if not executorRunOnActor then
if not nrNoActorWarned then
nrNoActorWarned = true
warn("[BloodDebt NR] This executor does not expose runonactor/run_on_actor. NR cannot inject in this client.")
end
return 0
end
local actors = getActiveWeaponActors()
local source = makeNRActorSource()
local injectedCount = 0
for _, targetActor in ipairs(actors) do
if isAliveLocalWeaponActor(targetActor) and nrActorAppliedState[targetActor] ~= Config.NREnabled then
local ok, err = pcall(function()
executorRunOnActor(targetActor, source)
end)
if ok then
nrActorAppliedState[targetActor] = Config.NREnabled
injectedCount = injectedCount + 1
else
warn("[BloodDebt NR] Actor injection failed: " .. tostring(err))
end
end
end
if injectedCount > 0 then
nrNoActorWarned = false
end
return injectedCount
end
local function scheduleNRInjection(delaySeconds)
if nrInjectionQueued or not Config.NREnabled or not ScriptAlive then return end
nrInjectionQueued = true
task.delay(delaySeconds or 0.55, function()
nrInjectionQueued = false
if Config.NREnabled and Config.ScriptReady and ScriptAlive then
runNRInjection()
end
end)
end
local function setNREnabled(enabled, notifyUser)
Config.NREnabled = enabled == true
local updatedActors = 0
if Config.ScriptReady then
updatedActors = runNRInjection()
end
if refreshUIButtons then
refreshUIButtons()
end
if notifyUser then
if updatedActors > 0 then
notify(
"NR (No Recoil)",
string.format("NR %s (%d weapon Actor updated).", Config.NREnabled and "enabled" or "disabled", updatedActors),
Config.NREnabled and Icons.Success or Icons.Info,
Sounds.Notification
)
else
notify(
"NR (No Recoil)",
string.format("NR %s. Will apply when a firearm is equipped.", Config.NREnabled and "enabled" or "disabled"),
Config.NREnabled and Icons.Success or Icons.Info,
Sounds.Notification
)
end
end
end
local boundContainers = setmetatable({}, { __mode = "k" })
local function bindNRContainer(container)
if not container or boundContainers[container] then return end
boundContainers[container] = true
trackConnection(container.DescendantAdded:Connect(function(descendant)
if not ScriptAlive then return end
if descendant:IsA("Actor") or descendant.Name == "weap_cl" then
scheduleNRInjection(0.55)
end
end))
end
bindNRContainer(LocalPlayer.Character)
bindNRContainer(LocalPlayer:FindFirstChild("Backpack"))
trackConnection(LocalPlayer.CharacterAdded:Connect(function(character)
-- Clean up any stale round references when LocalPlayer respawns between matches
stopAimlockHold()
task.delay(1.0, function()
if not ScriptAlive or not character.Parent then return end
bindNRContainer(character)
local bp = LocalPlayer:FindFirstChild("Backpack")
if bp then
bindNRContainer(bp)
end
scheduleNRInjection(0.5)
end)
end))
trackConnection(LocalPlayer.ChildAdded:Connect(function(child)
if child.Name == "Backpack" then
bindNRContainer(child)
scheduleNRInjection(0.5)
end
end))
trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
if gameProcessed or not Config.ScriptReady then return end
if input.KeyCode == Enum.KeyCode.B then
setNREnabled(not Config.NREnabled, true)
end
end))
-- ================================= Lucide Toolbar, Reopen Button & Settings Panel UI =================================
local Toolbar = Instance.new("Frame")
Toolbar.Name = "Toolbar"
Toolbar.Size = UDim2.fromOffset(62, 180)
Toolbar.Position = UDim2.new(0, 18, 0.5, -90)
Toolbar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Toolbar.BorderSizePixel = 0
Toolbar.Visible = false
Toolbar.ZIndex = 20
Toolbar.Parent = ScreenGui
createCorner(Toolbar, 15)
createStroke(Toolbar, Color3.fromRGB(255, 45, 65), 1.5)
local ToolbarLayout = Instance.new("UIListLayout")
ToolbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ToolbarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ToolbarLayout.Padding = UDim.new(0, 8)
ToolbarLayout.Parent = Toolbar
local function createIconButton(parent, name, icon)
local button = Instance.new("ImageButton")
button.Name = name
button.Size = UDim2.fromOffset(44, 44)
button.BackgroundColor3 = Color3.fromRGB(37, 37, 44)
button.BorderSizePixel = 0
button.AutoButtonColor = true
button.Image = icon
button.ImageColor3 = Color3.fromRGB(255, 255, 255)
button.ScaleType = Enum.ScaleType.Fit
button.ZIndex = 21
button.Parent = parent
createCorner(button, 11)
return button
end
local SettingsIconButton = createIconButton(Toolbar, "SettingsButton", Icons.Settings)
local AimlockIconButton = createIconButton(Toolbar, "AimlockButton", Icons.Crosshair)
local ESPIconButton = createIconButton(Toolbar, "ESPButton", Icons.Eye)
local HideToolbarButton = Instance.new("TextButton")
HideToolbarButton.Name = "HideButton"
HideToolbarButton.Size = UDim2.fromOffset(22, 22)
HideToolbarButton.Position = UDim2.new(1, -8, 0, -8)
HideToolbarButton.AnchorPoint = Vector2.new(0, 0)
HideToolbarButton.BackgroundColor3 = Color3.fromRGB(170, 35, 50)
HideToolbarButton.BorderSizePixel = 0
HideToolbarButton.Text = "×"
HideToolbarButton.TextSize = 17
HideToolbarButton.TextColor3 = Color3.new(1, 1, 1)
HideToolbarButton.Font = Enum.Font.GothamBold
HideToolbarButton.ZIndex = 25
HideToolbarButton.Parent = Toolbar
createCorner(HideToolbarButton, 20)
-- Floating Reopen Button using the requested Settings Image ID (⁠Icons.Settings⁠)
local ReopenButton = createIconButton(ScreenGui, "ReopenButton", Icons.Settings)
ReopenButton.AnchorPoint = Vector2.new(0.5, 0.5)
ReopenButton.Size = UDim2.fromOffset(52, 52)
ReopenButton.Position = UDim2.new(0, 44, 0.5, 0)
ReopenButton.Visible = false
ReopenButton.Active = true
ReopenButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ReopenButton.ZIndex = 30
createStroke(ReopenButton, Color3.fromRGB(255, 45, 65), 1.5)
-- Expanded Settings Panel styled with the same dark + crimson stroke Lucide theme
local SettingsPanel = Instance.new("Frame")
SettingsPanel.Name = "SettingsPanel"
SettingsPanel.Size = UDim2.fromOffset(300, 316)
SettingsPanel.Position = UDim2.new(0, 92, 0.5, -158)
SettingsPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
SettingsPanel.BorderSizePixel = 0
SettingsPanel.Visible = false
SettingsPanel.ZIndex = 20
SettingsPanel.Parent = ScreenGui
createCorner(SettingsPanel, 14)
createStroke(SettingsPanel, Color3.fromRGB(255, 45, 65), 1.5)
local PanelTitleIcon = Instance.new("ImageLabel")
PanelTitleIcon.Size = UDim2.fromOffset(20, 20)
PanelTitleIcon.Position = UDim2.fromOffset(14, 14)
PanelTitleIcon.BackgroundTransparency = 1
PanelTitleIcon.Image = Icons.Settings
PanelTitleIcon.ImageColor3 = Color3.fromRGB(255, 45, 65)
PanelTitleIcon.ScaleType = Enum.ScaleType.Fit
PanelTitleIcon.ZIndex = 21
PanelTitleIcon.Parent = SettingsPanel
local PanelTitle = Instance.new("TextLabel")
PanelTitle.Size = UDim2.new(1, -76, 0, 28)
PanelTitle.Position = UDim2.fromOffset(42, 10)
PanelTitle.BackgroundTransparency = 1
PanelTitle.Text = "Blood Debt Settings"
PanelTitle.TextColor3 = Color3.new(1, 1, 1)
PanelTitle.TextSize = 16
PanelTitle.Font = Enum.Font.GothamBold
PanelTitle.TextXAlignment = Enum.TextXAlignment.Left
PanelTitle.ZIndex = 21
PanelTitle.Parent = SettingsPanel
local PanelCloseButton = Instance.new("TextButton")
PanelCloseButton.Name = "ClosePanel"
PanelCloseButton.Size = UDim2.fromOffset(24, 24)
PanelCloseButton.Position = UDim2.new(1, -34, 0, 12)
PanelCloseButton.BackgroundColor3 = Color3.fromRGB(170, 35, 50)
PanelCloseButton.BorderSizePixel = 0
PanelCloseButton.Text = "×"
PanelCloseButton.TextSize = 16
PanelCloseButton.TextColor3 = Color3.new(1, 1, 1)
PanelCloseButton.Font = Enum.Font.GothamBold
PanelCloseButton.ZIndex = 22
PanelCloseButton.Parent = SettingsPanel
createCorner(PanelCloseButton, 12)
local PanelDescription = Instance.new("TextLabel")
PanelDescription.Size = UDim2.new(1, -24, 0, 28)
PanelDescription.Position = UDim2.fromOffset(14, 38)
PanelDescription.BackgroundTransparency = 1
PanelDescription.Text = "D-Pad: Left=Aim | Right=Gun TP | Down=Escape TP"
PanelDescription.TextColor3 = Color3.fromRGB(190, 190, 198)
PanelDescription.TextSize = 11
PanelDescription.Font = Enum.Font.Gotham
PanelDescription.TextXAlignment = Enum.TextXAlignment.Left
PanelDescription.ZIndex = 21
PanelDescription.Parent = SettingsPanel
local function createTextButton(parent, name, text, position)
local button = Instance.new("TextButton")
button.Name = name
button.Size = UDim2.new(1, -24, 0, 34)
button.Position = position
button.BackgroundColor3 = Color3.fromRGB(42, 42, 50)
button.BorderSizePixel = 0
button.Text = text
button.TextColor3 = Color3.new(1, 1, 1)
button.TextSize = 12
button.Font = Enum.Font.GothamSemibold
button.AutoButtonColor = true
button.ZIndex = 21
button.Parent = parent
createCorner(button, 8)
return button
end
local WeaponESPToggleButton = createTextButton(
SettingsPanel,
"WeaponESPToggle",
"Vigilante Weapon ESP: ON",
UDim2.fromOffset(12, 72)
)
local NRToggleButton = createTextButton(
SettingsPanel,
"NRToggle",
"NR (No Recoil) [Key B]: ON",
UDim2.fromOffset(12, 112)
)
local GroundGunTPButton = createTextButton(
SettingsPanel,
"GroundGunTP",
"Teleport to Dropped Vigilante Gun (D-Pad Right)",
UDim2.fromOffset(12, 152)
)
local KillerEscapeTPButton = createTextButton(
SettingsPanel,
"KillerEscapeTP",
"Teleport to Killer Escape (D-Pad Down)",
UDim2.fromOffset(12, 192)
)
local GunDropPreviewButton = createTextButton(
SettingsPanel,
"GunDropPreview",
"Preview Gun Drop Sound",
UDim2.fromOffset(12, 232)
)
local NotificationPreviewButton = createTextButton(
SettingsPanel,
"NotificationPreview",
"Preview Default Notification",
UDim2.fromOffset(12, 272)
)
local function updateIconButtonColor(button, enabled)
button.BackgroundColor3 = enabled
and Color3.fromRGB(145, 30, 48)
or Color3.fromRGB(37, 37, 44)
end
local function updateTextToggleColor(button, label, enabled)
button.Text = label .. (enabled and ": ON" or ": OFF")
button.BackgroundColor3 = enabled
and Color3.fromRGB(145, 30, 48)
or Color3.fromRGB(42, 42, 50)
end
refreshUIButtons = function()
updateIconButtonColor(AimlockIconButton, Config.AimlockEnabled)
updateIconButtonColor(ESPIconButton, Config.ESPEnabled)
updateIconButtonColor(SettingsIconButton, SettingsPanel.Visible)
updateTextToggleColor(WeaponESPToggleButton, "Vigilante Weapon ESP", Config.WeaponHighlight)
updateTextToggleColor(NRToggleButton, "NR (No Recoil) [Key B]", Config.NREnabled)
end
trackConnection(SettingsIconButton.Activated:Connect(function()
if not Config.ScriptReady then return end
SettingsPanel.Visible = not SettingsPanel.Visible
refreshUIButtons()
notify(
"Settings",
SettingsPanel.Visible and "Settings panel opened." or "Settings panel closed.",
Icons.Bell,
Sounds.Notification
)
end))
trackConnection(PanelCloseButton.Activated:Connect(function()
SettingsPanel.Visible = false
refreshUIButtons()
end))
trackConnection(AimlockIconButton.Activated:Connect(function()
if not Config.ScriptReady then return end
Config.AimlockEnabled = not Config.AimlockEnabled
if Config.AimlockEnabled then
startAimlockHold()
else
stopAimlockHold()
end
refreshUIButtons()
notify(
"Aimlock",
Config.AimlockEnabled and "Aimlock enabled (through walls, no distance limit)." or "Aimlock disabled.",
Config.AimlockEnabled and Icons.Success or Icons.Info,
Sounds.Notification
)
end))
trackConnection(ESPIconButton.Activated:Connect(function()
if not Config.ScriptReady then return end
Config.ESPEnabled = not Config.ESPEnabled
refreshUIButtons()
if not Config.ESPEnabled then
for _, esp in pairs(ESPObjects) do
if esp.Highlight then esp.Highlight.Enabled = false end
if esp.Billboard then esp.Billboard.Enabled = false end
end
else
updateESP()
end
notify(
"Player ESP",
Config.ESPEnabled and "ESP enabled." or "ESP disabled.",
Config.ESPEnabled and Icons.Success or Icons.Info,
Sounds.Notification
)
end))
trackConnection(WeaponESPToggleButton.Activated:Connect(function()
if not Config.ScriptReady then return end
Config.WeaponHighlight = not Config.WeaponHighlight
refreshUIButtons()
updateWeaponHighlight()
notify(
"Weapon ESP",
Config.WeaponHighlight and "Vigilante gun highlight enabled." or "Vigilante gun highlight disabled.",
Config.WeaponHighlight and Icons.Success or Icons.Info,
Sounds.Notification
)
end))
trackConnection(NRToggleButton.Activated:Connect(function()
if not Config.ScriptReady then return end
setNREnabled(not Config.NREnabled, true)
end))
trackConnection(GroundGunTPButton.Activated:Connect(function()
if not Config.ScriptReady then return end
teleportToGroundWeapon()
end))
trackConnection(KillerEscapeTPButton.Activated:Connect(function()
if not Config.ScriptReady then return end
teleportToKillerEscape()
end))
trackConnection(GunDropPreviewButton.Activated:Connect(function()
notify(
"Gun Drop",
"Playing gun drop sound preview.",
Icons.Bell,
Sounds.GunDrop
)
end))
trackConnection(NotificationPreviewButton.Activated:Connect(function()
notify(
"Notification Test",
"This is the default notification sound.",
Icons.BellRing,
Sounds.Notification
)
end))
trackConnection(HideToolbarButton.Activated:Connect(function()
Toolbar.Visible = false
SettingsPanel.Visible = false
ReopenButton.Visible = true
refreshUIButtons()
end))
-- Drag or tap the floating ReopenButton (with Icons.Settings image)
local activeDragInput = nil
local dragStartPosition = nil
local buttonStartCenter = nil
local buttonWasDragged = false
local buttonDragThreshold = 8
trackConnection(ReopenButton.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1
or input.UserInputType == Enum.UserInputType.Touch then
activeDragInput = input
dragStartPosition = input.Position
local buttonSize = ReopenButton.AbsoluteSize
buttonStartCenter = ReopenButton.AbsolutePosition + Vector2.new(buttonSize.X * 0.5, buttonSize.Y * 0.5)
buttonWasDragged = false
end
end))
trackConnection(UserInputService.InputChanged:Connect(function(input)
if not activeDragInput then return end
local isMouseMove = input.UserInputType == Enum.UserInputType.MouseMovement
local isTouchMove = input.UserInputType == Enum.UserInputType.Touch
if not isMouseMove and not isTouchMove then return end
if isTouchMove and input ~= activeDragInput then return end
local delta = input.Position - dragStartPosition
if delta.Magnitude >= buttonDragThreshold then
buttonWasDragged = true
end
if buttonWasDragged then
local camera = Workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
local halfWidth = ReopenButton.AbsoluteSize.X * 0.5
local halfHeight = ReopenButton.AbsoluteSize.Y * 0.5
local x = math.clamp(buttonStartCenter.X + delta.X, halfWidth, viewport.X - halfWidth)
local y = math.clamp(buttonStartCenter.Y + delta.Y, halfHeight, viewport.Y - halfHeight)
ReopenButton.Position = UDim2.fromOffset(x, y)
end
end))
trackConnection(UserInputService.InputEnded:Connect(function(input)
if not activeDragInput then return end
local samePointer = input == activeDragInput
or (activeDragInput.UserInputType == Enum.UserInputType.MouseButton1
and input.UserInputType == Enum.UserInputType.MouseButton1)
if samePointer then
local shouldOpen = not buttonWasDragged
activeDragInput = nil
dragStartPosition = nil
buttonStartCenter = nil
if shouldOpen then
Toolbar.Visible = true
ReopenButton.Visible = false
refreshUIButtons()
notify(
"Interface",
"Your UI has been reopened.",
Icons.Settings,
Sounds.Notification
)
else
task.delay(0.25, function()
buttonWasDragged = false
end)
end
end
end))
-- ================================= Startup & Leak-Free Player Tool Listeners =================================
local watchedPlayerContainers = setmetatable({}, { __mode = "k" })
local function watchPlayerToolsForHero(player, container)
if not container or watchedPlayerContainers[container] then return end
watchedPlayerContainers[container] = true
for _, child in ipairs(container:GetChildren()) do
if child:IsA("Tool") and isVigilanteWeapon(child.Name) then
hookVigilanteToolAncestry(child)
if everDroppedVigilanteTools[child] then
heroPlayers[player] = child.Name
elseif not initialVigilanteOwners[child] then
initialVigilanteOwners[child] = player
elseif initialVigilanteOwners[child] ~= player then
heroPlayers[player] = child.Name
end
end
end
trackPlayerConnection(player, container.ChildAdded:Connect(function(child)
if not ScriptAlive then return end
if child:IsA("Tool") and isVigilanteWeapon(child.Name) then
hookVigilanteToolAncestry(child)
if everDroppedVigilanteTools[child] then
heroPlayers[player] = child.Name
elseif not initialVigilanteOwners[child] then
initialVigilanteOwners[child] = player
elseif initialVigilanteOwners[child] ~= player then
heroPlayers[player] = child.Name
end
end
end))
end
local function bindPlayerESP(player)
if player == LocalPlayer then return end
disconnectPlayerConnections(player)
if player.Character then
watchPlayerToolsForHero(player, player.Character)
end
local bp = player:FindFirstChild("Backpack")
if bp then
watchPlayerToolsForHero(player, bp)
end
trackPlayerConnection(player, player.ChildAdded:Connect(function(child)
if not ScriptAlive then return end
if child.Name == "Backpack" then
watchPlayerToolsForHero(player, child)
end
end))
trackPlayerConnection(player, player.CharacterRemoving:Connect(function()
destroyPlayerESP(player)
end))
trackPlayerConnection(player, player.CharacterAdded:Connect(function(character)
heroPlayers[player] = nil
destroyPlayerESP(player)
watchPlayerToolsForHero(player, character)
task.wait(0.8)
if ScriptAlive and player.Parent == Players and player ~= LocalPlayer then
createESP(player)
end
end))
end
for _, player in ipairs(Players:GetPlayers()) do
bindPlayerESP(player)
end
trackConnection(Players.PlayerAdded:Connect(bindPlayerESP))
trackConnection(Players.PlayerRemoving:Connect(function(player)
heroPlayers[player] = nil
disconnectPlayerConnections(player)
destroyPlayerESP(player)
end))
-- Register global cleanup handler so re-executing the script never leaks connections or Highlights
GLOBAL_ENV.__BloodDebtCleanup = function()
ScriptAlive = false
stopAimlockHold()
pcall(function()
RunService:UnbindFromRenderStep("BloodDebt_AimLock")
end)
pcall(function()
ContextActionService:UnbindAction("BloodDebt_ToggleAimlock")
ContextActionService:UnbindAction("BloodDebt_TeleportToGroundGun")
ContextActionService:UnbindAction("BloodDebt_TeleportToKillerEscape")
end)
for player in pairs(PlayerConnections) do
disconnectPlayerConnections(player)
end
for _, conn in ipairs(ActiveConnections) do
pcall(function() conn:Disconnect() end)
end
table.clear(ActiveConnections)
clearAllPlayerESP()
clearAllWeaponHighlights()
if ScreenGui and ScreenGui.Parent then
pcall(function() ScreenGui:Destroy() end)
end
end
task.spawn(function()
while ScriptAlive and ScreenGui.Parent do
updateESP()
updateWeaponHighlight()
checkKillerEscapeAvailability()
task.wait(0.6)
end
end)
task.spawn(function()
while ScriptAlive and ScreenGui.Parent and not Config.ScriptReady do
task.wait(0.15)
end
if not ScriptAlive or not ScreenGui.Parent then return end
refreshGroundWeaponRegistry()
while ScriptAlive and ScreenGui.Parent do
refreshGroundWeaponRegistry()
task.wait(0.3)
end
end)
local function disableDefaultGamepadCursor()
if not GamepadService then
return
end
pcall(function()
GamepadService:DisableGamepadCursor()
end)
end
disableDefaultGamepadCursor()
task.spawn(function()
while ScriptAlive and ScreenGui.Parent do
disableDefaultGamepadCursor()
task.wait(0.5)
end
end)
-- Run a real-time 5.5-second progress sequence.
local loadingStartedAt = os.clock()
while ScriptAlive and ScreenGui.Parent do
local elapsed = os.clock() - loadingStartedAt
local progress = math.clamp(elapsed / LOADING_DURATION, 0, 1)
ProgressFill.Size = UDim2.new(progress, 0, 1, 0)
LoadingPercent.Text = string.format("%d%%", math.floor(progress * 100 + 0.5))
if progress >= 1 then
break
end
RunService.RenderStepped:Wait()
end
if not ScriptAlive then
return
end
-- Enable features after the loading bar completes.
Config.ScriptReady = true
Config.ESPEnabled = true
Config.WeaponHighlight = true
Config.AimlockEnabled = true
Config.NREnabled = true
Toolbar.Visible = true
SettingsPanel.Visible = false
ReopenButton.Visible = false
refreshUIButtons()
-- Initial NR injection; later equipment/Actor additions re-run it via DescendantAdded events.
task.delay(0.6, runNRInjection)
for _, player in ipairs(Players:GetPlayers()) do
if player ~= LocalPlayer and player.Character then
createESP(player)
end
end
if LoadingFrame and LoadingFrame.Parent then
LoadingFrame:Destroy()
end
notify(
"Blood Debt UI",
"Lucide icons, sound effects, KillerEscape TP (D-Pad Down), and through-walls aimlock loaded.",
Icons.Success,
Sounds.Notification
)
warn("Blood Debt script loaded for PlaceId 79187287306411: Lucide UI + sounds, KillerEscape D-Pad Down teleport, through-walls aimlock, BloodFolder map detection, and post-match crash prevention.")

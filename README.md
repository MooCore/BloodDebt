# Blood Debt

Run `Script.lua` as the entry point. It downloads each component from `modules/`, compiles it with `loadstring`, and executes it in a shared module environment. The module environment keeps shared state available without putting the entire script into one Luau chunk or exceeding the compiler's main-chunk local register limit.

The loader requires an executor that supports `game:HttpGet`, `loadstring`, and `setfenv`. The script is restricted to Roblox PlaceId `79187287306411`.

Modules:

- `00_Core.lua`: services, shared state, cleanup, and common helpers
- `01_Maps.lua`: map aliases and map detection
- `02_RoleDatabase.lua`: role weapon categories, weapon registries, and role mapping
- `03_UIFoundation.lua`: ScreenGui, loading UI, notifications, and shared UI helpers
- `04_ESP.lua`: role resolution and player ESP
- `05_WeaponsAndEscape.lua`: dropped-weapon tracking, Hero tracking, and escape teleport
- `06_Aimlock.lua`: aimlock selection and camera updates
- `07_Controller.lua`: controller input, interaction, and D-pad bindings
- `08_NoRecoil.lua`: NR actor injection and toggles
- `09_UI.lua`: responsive toolbar, settings panel, and UI controls
- `10_Lifecycle.lua`: player listeners, cleanup, loops, and final startup

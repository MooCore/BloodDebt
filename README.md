# Blood Debt

Run `Script.lua` as the entry point. It downloads each component from `modules/`, compiles it with `loadstring`, and executes it in a shared module environment. The module environment keeps shared state available without putting the entire script into one Luau chunk or exceeding the compiler's main-chunk local register limit.

The loader requires an executor that supports `game:HttpGet`, `loadstring`, and `setfenv`. The script is restricted to Roblox PlaceId `79187287306411`.

Modules:

- `00_Core.lua`: services, shared state, cleanup, and common helpers
- `01_Maps.lua`: map aliases and map detection
- `02_RoleDatabase.lua`: map-aware role weapon categories and weapon registries
- `03_UIFoundation.lua`: ScreenGui, loading UI, notifications, and shared UI helpers
- `04_ESP.lua`: role resolution and player ESP, including health bars and lobby exclusion
- `05_WeaponsAndEscape.lua`: dropped-weapon tracking, Hero tracking, role-weapon highlighting/teleport, and escape teleport
- `06_Aimlock.lua`: held-target camera lock, Scriptable camera follow, and camera-state restoration on release
- `07_Controller.lua`: controller input, interaction, and D-pad bindings
- `08_NoRecoil.lua`: NR actor injection and toggles
- `09_UI.lua`: responsive toolbar, settings panel, and UI controls
- `11_AdvancedFeatures.lua`: projectile bullet redirection that prioritizes the exact active aimlock target (by UserId and locked body part), role-based fallback targeting, configurable Follow Aimlock Target setting, optional hint-match ESP, TEAM1/TEAM2 Team War role override, Killer/Vigilante/Juggernaut dropped-weapon ESP and teleport, and nametag display modes
- `10_Lifecycle.lua`: player listeners, cleanup, loops, and final startup

Bullet redirection first follows the player currently held by aimlock, using the same locked body part and the target's UserId so it does not accidentally switch to another role-filtered player. When aimlock is not actively holding a player, redirection falls back to the selected role returned by the existing map-aware `getRole()` resolver. Follow Aimlock Target is enabled by default and can be toggled in Advanced Settings. The aimlock temporarily uses a Scriptable camera while the controller trigger is held, keeps the camera following the local character while facing the locked player, and restores the previous camera type and subject when released or when the target becomes invalid. The executor must support actor execution (`runonactor`, `run_on_actor`, or `run_on_thread`) for projectile redirection and no-recoil. The regular ESP, UI, controller, teleport, and no-recoil modules remain separate from this feature.

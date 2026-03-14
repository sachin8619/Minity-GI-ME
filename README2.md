## Minty-GI – Deep Project Overview

This file is an extended, technical companion to `README.md`. It documents the overall architecture, main subsystems, and patterns used inside Minty-GI so you can understand and reuse the codebase as a reference when building similar projects.

Minty-GI is a Windows-only, internal C++ tool for the Unity-based game Genshin Impact, built as a DLL that injects into the game process, hooks DirectX 11, and renders a custom ImGui-based menu with various gameplay and visual features. The public source is **intentionally incomplete**: offsets, bypass logic, encryption, and some functions were removed and must be reimplemented by you.

---

## High-Level Architecture

- **Entry / bootstrap**
  - `dllmain.cpp` – Entry point of the injected DLL; starts the main threads and initialises core systems.
  - `threads.cpp` – Defines the worker threads responsible for running game loop logic, updating features, and drawing the GUI.

- **Bypass**
  - `bypass.cpp` (mostly empty in this leak) – Intended for anti-cheat bypass, manual mapping, or other protection-related logic. All sensitive code has been stripped; only the integration points remain.

- **Engine / SDK layer**
  - `SDK.cpp` / `SDK.h` – C++ wrappers over Unity and game-specific (MoleMole) types.
    - `Unity::String`, `Unity::GameObject`, `Unity::Transform`, `Unity::Vector3`, etc.
    - `MoleMole::EntityManager`, `MoleMole::BaseEntity`, `MoleMole::LoadingManager`, and related helpers.
  - `SDK_offsets.h` – Central place for **all function pointers and offsets** into the game’s assemblies. In this public version all offsets are `0x0` or placeholders, so you must reverse and fill them in.
  - `SDK_types.h` – Game-specific enums, structs, and type definitions.
  - `SDK_utils.h` – Shared macros, helpers, and small utility types used across the SDK.

This layer turns raw addresses obtained via `Offsets::...` into convenient, type-safe C++ functions. Examples:

- `Unity::String::FromCString` uses `Offsets::Marshal::PtrToStringAnsi` to allocate Unity strings.
- `MoleMole::EntityManager::get_EntityManager()` locates the global entity manager via `Offsets::SingletonManager`.
- `MoleMole::BaseEntity::getPosition()` / `setPosition()` read/write world positions via `Offsets::BaseEntity` methods.
- `MoleMole::LoadingManager::IsLoaded()` checks whether the game world is ready before features run.

Any gameplay feature eventually talks to the game through this SDK abstraction.

---

## Feature System

### The `Feature` base class

Features are the building blocks of Minty-GI. Each feature represents a toggleable module (e.g. ESP, NoClip, AutoLoot) and is derived from a common `Feature` base class (defined in `Feature.h` and described in `README.md`):

- **Core metadata**
  - `std::string m_Name` – Display name used in the menu and configs.
  - `std::string m_Description` – Short explanation shown in tooltips.
- **Config and hotkey**
  - `Hotkey h_Enable` – Hotkey object controlling the enable/disable toggle.
  - `ConfigField<bool> m_Enabled` – Boolean config value backing the feature’s state.
- **Virtual lifecycle**
  - `virtual void Options()` – ImGui controls for settings (sliders, checkboxes, etc.).
  - `virtual void Status()` – Optional status text for the “Active functions” window.
  - `virtual void OnUpdate()` – Per-frame logic for the feature.
  - `virtual void ProcessHotkeys()` – Per-frame hotkey handling.
  - `virtual void InitConfig()` – Called at startup and whenever a config is loaded.
  - `virtual void InitHooks()` – Called at startup to install hooks needed by the feature.

Feature instances are long-lived singletons (via `Singleton<T>`) in most cases, and Minty-GI’s main loop regularly calls their lifecycle methods.

### `Module` and `FeatureManager`

Features are grouped into modules (categories) using `Module` and `FeatureManager` (`src/Functions/FeatureManager.h`):

- **Module**
  - Holds a `std::string m_Name` and `std::vector<Feature*> m_Features`.
  - Created with either one feature or a vector of features.
- **FeatureManager : Singleton**
  - Owns a `std::vector<Module> m_Modules`.
  - Provides:
    - `std::vector<Module> GetModules()`
    - `void AddModule(Module module)`

At startup, various files in `src/Functions/**` create their features and register them with `FeatureManager::Instance().AddModule(...)`. The GUI queries `FeatureManager` dynamically to populate the menu and the “Active functions” list.

### Example: ESP feature (`src/Functions/World/ESP.cpp`)

The ESP feature illustrates a typical feature implementation:

- **Config initialisation (`InitConfig`)**
  - Sets default toggles (e.g. `b_Monsters`, `b_NPCs`, `b_Chests`, etc.).
  - Sets default drawing range (`f_Range = 100.f`) and other visual settings.
- **Options UI (`Options`)**
  - Uses ImGui to provide checkboxes and sliders:
    - Filter flags: monsters, NPCs, animals, chests, oculi, collectibles, etc.
    - Drawing options: box colour, outline colour, “draw lines”, draw distance.
  - Modifications mark the cache as dirty via the `DIRTY_CACHE()` macro.
- **Runtime behaviour (`OnUpdate`)**
  - Early exits if:
    - Feature is disabled.
    - World is not yet loaded (`MoleMole::LoadingManager::IsLoaded()` is false).
    - Cached avatar / camera / entity list is invalid or empty.
  - Iterates cached entities and draws ESP boxes via `ESPBase::DrawActor`, using colours derived from the chosen ImGui colour pickers.
- **Background cache update (`OnUpdate_ESP_Cache`)**
  - Runs separately to:
    - Retrieve the current `EntityManager` and local avatar.
    - Compute distance to each candidate entity.
    - Filter entities using `ESP_FilterEntity` and the feature’s flags.
    - Populate `cachedEntities` map keyed by distance, within the configured range.

The pattern here—caching heavy work, then using lightweight per-frame drawing—is common for performance-sensitive features.

---

## GUI and Rendering

### DirectX hook and ImGui bootstrap

- **DirectX hooking**
  - `src/GUI/DirectX/DirectXHook.*` – Installs a hook on the game’s DirectX 11 rendering pipeline (swapchain/device/context).
  - The hook calls into ImGui’s backends to render the custom overlay on top of the game.

- **GUI initialisation (`InitGUI.cpp`)**
  - `GUI::Init(HWND window, ID3D11Device* device, ID3D11DeviceContext* context)`:
    - Creates an ImGui context.
    - Initialises Win32 and DX11 ImGui backends.
    - Disables ImGui’s `.ini` file (uses in-memory settings instead).
    - Loads custom fonts from embedded resources (`FontsLoader::Instance().LoadFont(...)`).
    - Loads images (e.g. logos, cursor textures) via `ImageLoader::Instance().LoadImageFromResources(...)`.
    - Configures a custom style and colour palette tailored to Minty-GI.
    - Pushes multiple ImGui style vars (rounding, padding, spacing, no window border).
    - Sets `Menu::Instance().b_Opened = true` so the menu appears when injected.

### Main menu (`MainGUI.cpp`)

`Menu::DrawFrame()` is responsible for the main window:

- **Layout**
  - Fixed-size, centered ImGui window with a top bar showing:
    - Project name and version string (`"MINTY GI | ... | 5.7.0.4"`).
    - Current system time (`HH:MM`).
  - Left side: a listbox with collapsible headers for each module.
    - Each header expands to show its features (from `FeatureManager::GetModules()`).
    - Clicking a feature selects it as the current function.
  - Right side:
    - A header child showing:
      - A help marker tooltip (using `m_Description`).
      - Feature name and enable toggle (`ConfigCheckbox` + hotkey button).
    - A main child area calling `_currentFunction->Options()` to render that feature’s settings.
    - When the feature is disabled, its options are visually disabled.

- **Status and FPS windows**
  - `Menu::DrawStatus()`
    - Small ImGui window listing all currently enabled (non-special) features in a table.
  - `Menu::DrawFPS()`
    - Minimal FPS overlay (`"Minty GI | FPS: X"`).

- **Hotkeys and animation (`GUI::Render`)**
  - Uses `Settings::Configs::Instance().h_OpenMenu` as the open/close hotkey.
  - When toggling the menu:
    - Saves/restores the original cursor visibility and lock state using `Offsets::Cursor`.
  - Implements fade-in/fade-out animation for the menu and teleporting overlay via ImGui style alpha and timeline calculations.
  - Calls:
    - `menu.DrawFrame()` for main UI.
    - `menu.DrawFPS()` / `menu.DrawStatus()` if enabled in settings.
    - `menu.ExecuteHotkeys()` and `menu.ExecuteOuter()` to propagate hotkey processing to all features.

The result is a fully custom, animated menu integrated tightly with the feature system and configuration layer.

---

## Configuration System

- **Config storage**
  - `ConfigManager.cpp` / `ConfigManager.h` manage reading/writing config files (paths, formats, multiple named configs).
  - `ConfigField<T>` (used widely, e.g. `ConfigField<bool> m_Enabled`) binds individual in-memory fields to values in the config file.
  - Features define their config fields in `InitConfig()` and expect `ConfigManager` to handle persistence.

- **Runtime updates**
  - When the user toggles a feature via UI or hotkey, the project calls:
    - `Config::SetValue(feature->m_Enabled, !feature->m_Enabled);`
    - Then applies the result back to the field (`feature->m_Enabled.setValue(...)`).
  - This pattern centralises config writes while still letting features own their logic.

---

## Directory Layout (Summary)

This complements the brief overview in `README.md` with more detail:

- **Root**
  - `Minty-GI.sln`, `Minty-GI.vcxproj` – Visual Studio solution & project for building the DLL.
  - `README.md` – Original high-level description from the authors.
  - `README2.md` – This extended architectural overview (you are reading it).

- **`src/Bootstrap`** (file names may vary slightly)
  - `dllmain.cpp`, `threads.cpp`, etc. – DLL entrypoint, hook installation, main worker threads.

- **`src/Bypass`**
  - `bypass.cpp` – Placeholder for anti-cheat related logic (stripped).

- **`src/Config`**
  - `ConfigManager.*` – Config file IO, field binding, and profile management.

- **`src/Engine`**
  - `SDK.*`, `SDK_offsets.h`, `SDK_types.h`, `SDK_utils.h` – Unity/MoleMole wrappers and offsets.

- **`src/Frameworks/ImGui`**
  - Dear ImGui and related backends:
    - `imgui*.cpp/.h`
    - `imgui_impl_dx11.*`, `imgui_impl_win32.*`
    - Freetype integration (`imgui_freetype.h` and `freetype/*`).

- **`src/Functions`**
  - Core feature system:
    - `Feature.h`, `FeatureManager.h`.
  - **Subfolders:**
    - `Player` – Player-related features (Godmode, Infinite Stamina, Noclip, No Skill Cooldown, etc.).
    - `World` – World-related features (ESP, AutoLoot, AutoDestroy, Autotalk, DumbEnemies, AutoActivateTP).
    - `Visuals` – Visual tweaks (FOV changer, HideDamage, FakeTime, FakeWeather, GraphicsChanger, ObjectSpawner, etc.).
    - `Teleports` – Teleport tools (MapTP, QuestTP, ChestTP, TeleportBase).
    - `Settings` – Global settings feature(s), config UI, etc.

- **`src/GUI`**
  - `DirectX` – DX11 hook, frame rendering entry (`DirectXHook.*`).
  - `Menu` – ImGui menu code: `InitGUI.*`, `MainGUI.*`, `Hotkey.*`.

- **`src/Resources`**
  - Image and font assets embedded in the compiled binary (referenced by `resource.h`).

- **`src/Utils`**
  - `Singleton.h` – Generic singleton pattern.
  - `ProjectGlobals.h` – Global variables and project-level constants.
  - `stb_image.h` – Image loading library used by `ImageLoader`.
  - Other small utilities shared across subsystems.

---

## Adding a New Feature (Practical Guide)

This is a typical workflow for adding your own feature using the existing architecture:

1. **Create the feature class**
   - Pick an appropriate subfolder under `src/Functions/` (e.g. `Player`, `World`, `Visuals`).
   - Create `MyFeature.h` / `MyFeature.cpp`:
     - Derive from `Feature`.
     - Implement:
       - `InitConfig()` – Setup default config values.
       - `InitHooks()` – Install any hooks you need (if applicable).
       - `Options()` – ImGui settings UI (checkboxes, sliders, hotkeys).
       - `OnUpdate()` – Periodic logic, using `SDK` and `Offsets` functions.
       - `ProcessHotkeys()` – Additional per-frame hotkey actions.
     - Add a constructor that passes a human-readable name and description to `Feature(...)`.

2. **Declare a singleton instance (if needed)**
   - Use the `Singleton<T>` pattern or a static instance in your CPP file.
   - Make sure you can access `MyFeature::Instance()` globally for caching or filters.

3. **Register the feature with `FeatureManager`**
   - Somewhere in the feature registration code (often a central file in `src/Functions`), call:
     - `FeatureManager::Instance().AddModule(Module("My Module Name", new MyFeature()));`
     - or group multiple features in one module by passing a vector of `Feature*`.

4. **Hook into the main loop**
   - Ensure the main update thread calls `OnUpdate()` and `ProcessHotkeys()` on all features, and that the GUI is initialised before use.
   - In practice, this is already wired up: `Menu::ExecuteHotkeys()` and the core update logic iterate `FeatureManager::GetModules()` automatically.

5. **Persist settings**
   - Use `ConfigField<T>` members in your feature and initialise them in `InitConfig()`.
   - When toggling things in `Options()`, update the config fields; `ConfigManager` will handle saving/loading.

---

## Building and Running

**Important:** The repository is not intended to compile successfully “as-is”. You must have experience with C++ game hacking, reverse engineering, and anti-cheat systems to make it work.

- **Environment**
  - Windows 10+ (x64).
  - Visual Studio (with C++ and Windows Desktop development workloads).
  - DirectX 11 SDK (now part of the Windows SDK).

- **Steps (high-level)**
  1. Open `Minty-GI.sln` in Visual Studio.
  2. Restore any missing dependencies (if necessary; most are vendored).
  3. Implement your own offsets in `SDK_offsets.h` by reversing the current game version.
  4. Recreate/remove stripped or stubbed functionality (bypass, encryption, removed functions).
  5. Build the project as a DLL (usually x64, Release).
  6. Inject the DLL into the target process (using your own injection method).

Because of frequent game and anti-cheat updates, these steps require maintenance and adaptation for each new version.

---

## Security, Legality, and Ethics

- Minty-GI is a **cheat-like tool** for an online game. Using similar code in live environments can:
  - Violate the game’s Terms of Service.
  - Lead to account bans or other penalties.
  - Potentially violate regional laws depending on jurisdiction and usage.
- Treat this repository as a **learning resource**:
  - Engine abstraction patterns for Unity games.
  - Feature/module systems with config integration.
  - ImGui-based in-game overlays and DX11 hooks.
- If you adapt this code, do so responsibly and in accordance with local laws and the game’s policies (e.g. in private, offline, or test environments where permitted).

---

## Limitations of This Public Source

- **Missing offsets** – All calls into the game assemblies rely on offsets that are reset to `0x0`. You must reverse these yourself.
- **Stripped bypass logic** – Anti-cheat and protection code has been removed.
- **Incomplete feature set** – Some functions, features, or sub-systems are intentionally omitted or only partially present.
- **Version-specific** – Many structures and offsets are for a particular past version of Genshin Impact and will not match current builds.

Despite these limitations, the project provides a **complete architectural example** of:

- How to structure a medium-sized C++ internal tool.
- How to wrap a Unity-based engine in a clean C++ SDK.
- How to design and implement a feature/module system with hotkeys and config.
- How to integrate ImGui into a DirectX 11 game for a polished custom UI.

Use `README.md` for a quick start, and this `README2.md` whenever you need a deeper understanding of how the pieces of Minty-GI fit together.


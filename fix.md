## Minty-GI – Build Fix Guide

This guide assumes you are using the project in:

`C:\Users\This PC\Documents\Minity-GI ME\Minty-GI.sln`

Always open and build **this** solution (not the Desktop copy), so that all fixes in this folder are actually used.

---

### 1. Open the correct solution

- In Visual Studio, open:
  - `C:\Users\This PC\Documents\Minity-GI ME\Minty-GI.sln`
- Make sure the **Startup Project** is the `Minty-GI` project.

---

### 2. Confirm the code fixes are present

These are already applied in this folder, but you can quickly verify:

- **`src\Config\ConfigManager.h`**
  - Inside `Config::GetValue` and `Config::SetValue`, the checks should use:
    - `if (path.find(":") != std::string::npos) { ... }`
  - There should be **no** `path.get()` calls anywhere.

- **`src\Utils\obfusheader.h`**
  - File should exist and contain a simple macro:
    - `#define QENC(x) (x)`

- **`src\Engine\SDK_types.h`**
  - Near the bottom there should be a `namespace MoleMole` block defining:
    - `template<typename T> struct RepeatedFieldArray { ... };`
    - `struct RepeatedField { int count; RepeatedFieldArray<int>* array; };`

- **`src\Functions\Player\InfinityStamina.cpp`**
  - In `InfinityStamina::InitHooks()` make sure this line ends with `;`:
    - `Hooks::Attach(Offsets::DataItem::HandleNormalProp, hook_HandleNormalProp);`

If these match, you are using the fixed code.

---

### 3. Install and configure FreeType (for ImGui)

The build error:

- `C1083: Cannot open include file: 'freetype/config/ftheader.h'`

means the compiler can’t find FreeType headers.

**Steps (vcpkg example, recommended):**

1. Install vcpkg (if not already installed) and integrate it with VS:
   - Follow official instructions from the vcpkg repo.
2. In a Developer Command Prompt, install FreeType:
   - `vcpkg install freetype:x64-windows`
3. In Visual Studio, for the `Minty-GI` project:
   - Right-click the project → **Properties**.
   - Under **Configuration**: choose `All Configurations`, `All Platforms` (or the one you use).
   - Go to **C/C++ → Additional Include Directories**.
   - Add the path where vcpkg installed FreeType, for example:
     - `C:\path\to\vcpkg\installed\x64-windows\include`
   - Click **Apply**.

After this, the include `#include <freetype/config/ftheader.h>` in `src\Frameworks\ImGui\ft2build.h` should be resolved.

---

### 4. Ensure `<thread>` is available

Teleport features use `std::thread` in files like:

- `src\Functions\Teleports\MapTP.cpp`
- `src\Functions\Teleports\OculiTP.cpp`
- `src\Functions\Teleports\QuestTP.cpp`
- `src\Functions\Teleports\ChestTP.cpp`

If you see errors such as:

- `'thread': identifier not found`
- `'thread': is not a member of 'std'`

then:

1. Open each of the above `.cpp` files.
2. At the top (after other standard includes), add:
   - `#include <thread>`
3. Make sure the project uses at least C++11 (see next section).

---

### 5. Set the C++ language standard and handle codecvt warnings

`src\Engine\SDK.cpp` uses `std::wstring_convert` and `<codecvt>`, which are **deprecated** in C++17 but still work.

You may see warnings like:

- `C4996: std::wstring_convert ... are deprecated in C++17`

To compile cleanly:

1. In Visual Studio, open **Project Properties** for `Minty-GI`.
2. Under **C/C++ → Language → C++ Language Standard**:
   - Select at least `/std:c++17` (or `/std:c++14` if available and preferred).
3. To silence the deprecation warnings (optional):
   - Go to **C/C++ → Preprocessor → Preprocessor Definitions**.
   - Add:
     - `_SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING`
   - Or, to silence more broadly (less recommended):
     - `_SILENCE_ALL_CXX17_DEPRECATION_WARNINGS`

These are **warnings**, not hard errors, unless the project treats warnings as errors.

---

### 6. Fix Runtime "Access is denied" Error

If you encounter this runtime error after building:

```
thread '<unnamed>' panicked at src\lib.rs:24:29:
called `Result::unwrap()` on an `Err` value: Error { code: HRESULT(0x80070005), message: "Access is denied." }
```

**CRITICAL: This error suggests an external Rust dependency or component is failing.**

**Solutions (try in order):**

1. **Run as Administrator** (Most Important)
   - Right-click the executable
   - Select "Run as administrator"
   - This is the most common fix for access denied errors

2. **Fix File Permissions**
   - Run `fix_permissions.bat` (included in project)
   - This takes ownership and grants full permissions to the folder

3. **Check External Dependencies**
   - The error may come from a third-party Rust library
   - Ensure all dependencies are properly installed
   - Check if any external tools need admin rights

4. **Graphics Driver Issues**
   - Update AMD/NVIDIA graphics drivers
   - The stack trace shows `AmdPowerXpressRequestHighPerformance`
   - Try disabling GPU switching in graphics control panel

5. **Disable Security Software**
   - Temporarily disable Windows Defender or other antivirus
   - Add Minty-GI to antivirus exclusions
   - Disable Windows SmartScreen temporarily

6. **Verify Game Status**
   - Ensure Genshin Impact is running before injecting
   - Some features require the game to be in a specific state
   - Try running game in windowed mode

7. **Enable Debug Logging**
   - Set environment variable: `RUST_BACKTRACE=1`
   - This provides more detailed error information

8. **Check for External Rust Components**
   - Look for any .dll files that might be Rust-based
   - Check if any build tools use Rust (cargo, rustc)
   - Verify all third-party libraries are compatible

---

### 8. Fix DirectX Hooking Pattern
   - If hanging at "[...] Hooking Present...", the pattern signatures are missing
   - Open `src\GUI\DirectX\DirectXHook.cpp`
   - Replace lines 202 and 206 with proper pattern signatures:
     - Pattern #1: `48 89 5C 24 ? 48 89 6C 24 ? 48 89 74 24 ? 57 48 83 EC 20 48 8B F2 48 8B E9 48 85 D2 75 ?`
     - Pattern #2: `40 55 56 57 41 54 41 55 41 56 41 57 48 8D AC 24 ? ? ? ? 48 81 EC ? ? ? ? 48 8B 05 ? ? ? ? 48 33 C4 48 89 85 ? ? ? ? 4C 8B FA`
   - This fix is already applied in the current codebase

---

### 9. Build the project

1. In Visual Studio:
   - Select configuration: typically `Release` and platform `x64` (or what the project expects).
2. Choose **Build → Build Solution**.
3. Wait for compilation to finish.

If the build **fails**:

- In Visual Studio, go to **Build → Build Solution** again.
- Export the full error list to a file.
- Check if errors reference **Documents** paths (not `Desktop`).
- If needed, share the updated error log for further assistance.

---

### 8. Run and see the UI

After a successful build:

- Use **Debug → Start without Debugging** or run the produced executable / loader (depending on project design).
- The ImGui-based UI should appear once injected/launched as intended by the original project.

If the program runs but you can’t see the UI or overlay:

- Make sure you’re following the original project usage instructions (often found in `README2.md`).
- Check that the game / target process is running if this is meant to inject into a game.

---

### 9. If you change folders again

If you later copy the project somewhere else (e.g. Desktop):

- Always apply the same fixes in that new copy, **or**
- Re-clone / re-copy from this working `Documents\Minity-GI ME` folder.

Building from multiple, slightly different copies at once can easily reintroduce the same errors.


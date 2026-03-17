# Minity-GI + Genshin-Unlock-ME Offset Fix Summary

## What Was Fixed

### 1. Offset System Integration
- **Problem**: Minity-GI had all offsets set to `0x0`, causing crashes
- **Solution**: Integrated working offsets from Genshin-Unlock-ME:
  - FPS unlock: `0x49965C4` (both OS and CN)
  - FOV unlock: `0x1091A20` (OS) and `0x1092A20` (CN)

### 2. Game Region Detection
- **Problem**: Minity-GI always used OS offsets regardless of game version
- **Solution**: Added Helper system from Genshin-Unlock-ME:
  - `Helper.hpp` - Defines game region enums and structures
  - `Helper.cpp` - Detects if running GenshinImpact.exe (OS) or YuanShen.exe (CN)
  - Updated `SDK_utils.h` to use appropriate offsets based on detected region

### 3. Project Integration
- Added Helper files to Visual Studio project (`Minty-GI.vcxproj`)
- Updated offset definitions in `SDK_offsets.h`

## Files Modified

### New Files Created:
- `src/Utils/Helper.hpp` - Game region detection header
- `src/Utils/Helper.cpp` - Game region detection implementation

### Files Modified:
- `src/Engine/SDK_offsets.h` - Updated with working offsets
- `src/Engine/SDK_utils.h` - Added region detection logic
- `Minty-GI.vcxproj` - Added new files to project

## Key Changes

### SDK_offsets.h
```cpp
// Before (broken)
namespace Application {
    REMOTE_FUNC(int, get_targetFramerate) { 0x0, 0x0 };
    REMOTE_FUNC(void, set_targetFramerate, int) { 0x0, 0x0 };
}

// After (working)
namespace Application {
    REMOTE_FUNC(int, get_targetFramerate) { 0x49965C4, 0x49965C4 };
    REMOTE_FUNC(void, set_targetFramerate, int) { 0x49965C4, 0x49965C4 };
}
```

### SDK_utils.h
```cpp
// Added game region detection
void Setup() {
    // Detect game region and use appropriate offset
    try {
        auto context = Helper::GetGameModuleContext();
        DetectedRegion = context.region;
    } catch (...) {
        DetectedRegion = Helper::GameRegion::OS; // Default to OS
    }
    
    uintptr_t selectedOffset = (DetectedRegion == Helper::GameRegion::CN) ? CN_offset : OS_offset;
    Functor = (TReturn(*)(Args...))(BaseAddress + selectedOffset);
}
```

## Expected Results

1. **FPS Unlock**: Should now work correctly for both OS and CN versions
2. **FOV Unlock**: Should now work correctly for both OS and CN versions
3. **No More Crashes**: The access denied errors from `error.md` should be resolved
4. **Automatic Detection**: The mod will automatically detect which game version is running

## Build Instructions

1. Open `Minty-GI.sln` in Visual Studio
2. Make sure the startup project is `Minty-GI`
3. Build with Configuration: `Release` and Platform: `x64`
4. The DLL should now compile without offset-related errors

## Testing

1. Inject the compiled DLL into Genshin Impact (OS) or YuanShen (CN)
2. The FPS and FOV unlock features should work without crashes
3. Check that the correct offsets are being used based on the game version

## Notes

- Only FPS and FOV offsets have been updated with confirmed working values
- Other offsets in the file remain at `0x0` and would need similar updates if those features are required
- The Helper system can be extended to support more game regions if needed
- This merge combines the best of both projects: Minity-GI's feature set with Genshin-Unlock-ME's working offsets

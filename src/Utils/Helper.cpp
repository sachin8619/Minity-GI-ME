#include "Helper.hpp"

#include <Windows.h>
#include <stdexcept>

namespace Helper {
GameModuleContext GetGameModuleContext() {
    if (const HMODULE osModule = GetModuleHandleW(L"GenshinImpact.exe");
        osModule != nullptr) {
        return GameModuleContext {
            .module = osModule,
            .region = GameRegion::OS
        };
    }
    if (const HMODULE cnModule = GetModuleHandleW(L"YuanShen.exe");
        cnModule != nullptr) {
        return GameModuleContext {
            .module = cnModule,
            .region = GameRegion::CN
        };
    }
    // Throw a simple exception instead of using WIL
    throw std::runtime_error("Game module not found");
}
}

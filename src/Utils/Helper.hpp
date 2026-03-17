#pragma once

#include <cstdint>
#include <Windows.h>

namespace Helper {
enum class GameRegion : uint8_t {
    OS,
    CN
};

struct GameModuleContext {
    HMODULE module;
    GameRegion region;
};

GameModuleContext GetGameModuleContext();
}

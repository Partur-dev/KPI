#include "GameApplication.hh"

auto app_main() -> int32_t {
    GameApplication("Fifteen Puzzle", 500, 255).run();
    return 0;
}

#ifdef _WIN32
    #include <Windows.h>

int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int) {
    return app_main();
}
#else
int main() {
    return app_main();
}
#endif

#pragma once

#include <cstdint>
#include <string_view>

struct GLFWwindow;

class Application {
public:
    Application(std::string_view title, int32_t width, int32_t height) :
        _title(title),
        _width(width),
        _height(height) {};

    virtual ~Application() = default;

    void run();

protected:
    virtual bool initialize();
    virtual bool load();
    virtual void unload();
    virtual void renderScene(float dt);
    virtual void keyPressed(int32_t key, int32_t action);
    virtual void update(float dt);

private:
    static void keyCallback(GLFWwindow* window, int32_t key, int32_t scancode, int32_t action, int32_t mods);

    void close();

    void render(float dt);
    double getDeltaTime();

    std::string_view _title;
    int32_t _width = 0;
    int32_t _height = 0;
    GLFWwindow* _windowHandle = nullptr;
};

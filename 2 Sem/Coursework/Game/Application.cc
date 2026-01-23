#include "Application.hh"

#include <glad/glad.h>

#include <GLFW/glfw3.h>
#include <imgui.h>
#include <imgui_impl_glfw.h>
#include <imgui_impl_opengl3.h>
#include <spdlog/spdlog.h>

void Application::keyCallback(GLFWwindow* window, int32_t key, int32_t /*scancode*/, int32_t action, int32_t /*mods*/) {
    auto app = static_cast<Application*>(glfwGetWindowUserPointer(window));
    if (app) {
        app->keyPressed(key, action);
    }
}

void Application::run() {
    if (!initialize()) {
        spdlog::error("App: Unable to initialize");
        return;
    }

    spdlog::info("App: Initialized");

    if (!load()) {
        spdlog::error("App: Unable to load resources");
        unload();
        glfwDestroyWindow(_windowHandle);
        glfwTerminate();
        return;
    }

    spdlog::info("App: Loaded");

    double previousTime = glfwGetTime();
    while (!glfwWindowShouldClose(_windowHandle)) {
        double currentTime = glfwGetTime();
        float deltaTime = static_cast<float>(currentTime - previousTime);
        previousTime = currentTime;

        glfwPollEvents();
        update(deltaTime);
        render(deltaTime);
    }

    spdlog::info("App: Unloading");
    unload();
    spdlog::info("App: Unloaded");
}

void Application::close() {
    glfwSetWindowShouldClose(_windowHandle, 1);
}

bool Application::initialize() {
    if (!glfwInit()) {
        spdlog::error("Glfw: Unable to initialize");
        return false;
    }

    glfwWindowHint(GLFW_DECORATED, GLFW_TRUE);
    glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_API);
    glfwWindowHint(GLFW_RESIZABLE, GLFW_TRUE);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_SCALE_TO_MONITOR, GLFW_TRUE);

    _windowHandle = glfwCreateWindow(_width, _height, _title.data(), nullptr, nullptr);

    if (_windowHandle == nullptr) {
        spdlog::error("Glfw: Unable to create window");
        glfwTerminate();
        return false;
    }

    glfwMakeContextCurrent(_windowHandle);
    glfwSetWindowUserPointer(_windowHandle, this);
    glfwSetKeyCallback(_windowHandle, keyCallback);
    gladLoadGLLoader((GLADloadproc)glfwGetProcAddress);

    ImGui::CreateContext();
    ImGui_ImplGlfw_InitForOpenGL(_windowHandle, true);
    ImGui_ImplOpenGL3_Init("#version 410");
    ImGui::StyleColorsDark();

    return true;
}

bool Application::load() {
    glEnable(GL_DEPTH_TEST);

    glfwSwapInterval(1);

    return true;
}

void Application::unload() {
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();

    glfwTerminate();
}

void Application::render(float dt) {
    glClearColor(0.f, 0.f, 0.f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplGlfw_NewFrame();
    ImGui::NewFrame();
    {
        renderScene(dt);
        ImGui::Render();
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
        ImGui::EndFrame();
    }

    glfwSwapBuffers(_windowHandle);
}

void Application::renderScene(float /*dt*/) {}

void Application::keyPressed(int32_t /*key*/, int32_t /*action*/) {}

void Application::update(float /*dt*/) {}

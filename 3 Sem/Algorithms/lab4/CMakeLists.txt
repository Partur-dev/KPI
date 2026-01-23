cmake_minimum_required(VERSION 3.20)
project(lab4 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(IMGUI_DIR ${CMAKE_CURRENT_SOURCE_DIR}/external/imgui)
set(GLAD_DIR  ${CMAKE_CURRENT_SOURCE_DIR}/external/glad)

add_definitions(-DGL_SILENCE_DEPRECATION)

# ---------- GLFW via FetchContent ----------
include(FetchContent)

FetchContent_Declare(
  glfw
  GIT_REPOSITORY https://github.com/glfw/glfw.git
  GIT_TAG 3.3.9
)
FetchContent_MakeAvailable(glfw)

# ---------- OpenGL ----------
find_package(OpenGL REQUIRED)

# ---------- GLAD (local) ----------
add_library(glad STATIC
  ${GLAD_DIR}/src/glad.c
)
target_include_directories(glad PUBLIC
  ${GLAD_DIR}/include
)

# ---------- ImGui (local) ----------
add_library(imgui STATIC
  ${IMGUI_DIR}/imgui.cpp
  ${IMGUI_DIR}/imgui_draw.cpp
  ${IMGUI_DIR}/imgui_tables.cpp
  ${IMGUI_DIR}/imgui_widgets.cpp
  # ${IMGUI_DIR}/imgui_demo.cpp

  ${IMGUI_DIR}/backends/imgui_impl_glfw.cpp
  ${IMGUI_DIR}/backends/imgui_impl_opengl3.cpp
)

target_include_directories(imgui PUBLIC
  ${IMGUI_DIR}
  ${IMGUI_DIR}/backends
)

target_link_libraries(imgui PUBLIC glfw glad OpenGL::GL)

# ---------- App ----------
add_executable(lab4
  src/main.cc
)

target_include_directories(lab4 PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(lab4 PRIVATE
  imgui
  glfw
  glad
  OpenGL::GL
)

# macOS niceties (GLFW usually handles these, but harmless)
if(APPLE)
  target_link_libraries(lab4 PRIVATE
    "-framework Cocoa"
    "-framework IOKit"
    "-framework CoreVideo"
  )
endif()

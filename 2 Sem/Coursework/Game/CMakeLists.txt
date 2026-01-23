project(game)

set(SOURCES
    Application.cc
    Game.cc
    GameApplication.cc
    Main.cc
    Heuristic.cc
    Solver.cc
)

if(WIN32)
    add_executable(game WIN32
        ${SOURCES}
    )
else()
    add_executable(game
        ${SOURCES}
    )
endif()

target_link_libraries(game
    PRIVATE
        glad imgui glm cgltf stb_image spdlog
)

target_compile_options(game PRIVATE
    $<$<CXX_COMPILER_ID:MSVC>:/W4 /WX>
    $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-Wall -Wextra -Werror>
)


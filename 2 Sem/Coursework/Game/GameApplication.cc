#include "GameApplication.hh"
#include "GLFW/glfw3.h"
#include "Heuristic.hh"
#include "imgui.h"
#include "spdlog/spdlog.h"
#include <chrono>
#include <fstream>
#include <string>
#include <thread>

const int32_t commonFlags
    = ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoCollapse;

bool NumButton(uint8_t n) {
    if (n == 0) {
        ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.F, 0.F, 0.F, 0.F));
        ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(0.F, 0.F, 0.F, 0.F));
        ImGui::PushStyleColor(ImGuiCol_ButtonActive, ImVec4(0.F, 0.F, 0.F, 0.F));
    }

    auto strN = std::to_string(n);
    auto result = ImGui::Button(n == 0 ? " " : strN.c_str(), ImVec2(50, 50));

    if (n == 0) {
        ImGui::PopStyleColor(3);
    }

    return result;
}

void GameApplication::update(float /*dt*/) {
    if (_state == GameState::FINISHED || _state == GameState::NONE) {
        return;
    }

    if (_game.isSolved()) {
        _state = GameState::FINISHED;
        _elapsedTime = std::chrono::duration_cast<std::chrono::seconds>(std::chrono::steady_clock::now() - _startTime);
    } else if (_state == GameState::PLAYING || _state == GameState::SOLVING || _state == GameState::SOLVER) {
        auto elapsed = std::chrono::steady_clock::now() - _startTime;
        _elapsedTime = std::chrono::duration_cast<std::chrono::seconds>(elapsed);
    }
}

bool GameApplication::initialize() {
    if (!Application::initialize()) {
        return false;
    }

    auto& io = ImGui::GetIO();
    auto& style = ImGui::GetStyle();

    style.ItemSpacing = ImVec2(5, 5);
    style.WindowPadding = ImVec2(10, 10);
    style.FramePadding = ImVec2(5, 5);
    style.WindowRounding = 10.F;
    style.FrameRounding = 5.F;
    style.Colors[ImGuiCol_Button] = ImVec4(0.2F, 0.2F, 0.2F, 1.0F);
    style.Colors[ImGuiCol_ButtonHovered] = ImVec4(0.3F, 0.3F, 0.3F, 1.0F);
    style.Colors[ImGuiCol_ButtonActive] = ImVec4(0.4F, 0.4F, 0.4F, 1.0F);

#if defined(__APPLE__)
    const auto* fontPath = "/System/Library/Fonts/SFNS.ttf";
#elif defined(_WIN32)
    const auto* fontPath = "C:\\Windows\\Fonts\\Arial.ttf";
#else
    const auto* fontPath = "";
#endif

    auto* font = io.Fonts->AddFontFromFileTTF(fontPath, 16.F);
    if (font == nullptr) {
        spdlog::error("Unable to load font, using default");
    } else {
        io.FontDefault = font;
    }

    return true;
}

void GameApplication::renderGame() {
    ImGui::SetNextWindowPos(ImVec2(10, 10));
    ImGui::SetNextWindowSize(ImVec2(235, 235));

    ImGui::Begin("Game", nullptr, commonFlags);

    {
        for (int32_t i = 0; i < _game.size(); ++i) {
            if (NumButton(_game.get(i)) && _state == GameState::PLAYING) {
                _game.move(i);
            }

            if (i % _game.dimension() != 3 || i == _game.size() - 1) {
                ImGui::SameLine();
            }
        }
    }

    ImGui::End();
}

void GameApplication::renderInfo() {
    ImGui::SetNextWindowPos(ImVec2(255, 10));
    ImGui::SetNextWindowSize(ImVec2(235, 135));

    ImGui::Begin("Info", nullptr, commonFlags);
    {
        if (ImGui::Button("New game")) {
            _game.shuffle();
            _state = GameState::PLAYING;
            _startTime = std::chrono::steady_clock::now();
            _moves = 0;
        }

        ImGui::SameLine();

        if (ImGui::Button("Reset")) {
            _game.reset();
            _state = GameState::NONE;
        }

        if (_state == GameState::PLAYING) {
            ImGui::SameLine();
            if (ImGui::Button("Save")) {
                saveState();
            }
        } else if (_state == GameState::NONE || _state == GameState::FINISHED) {
            ImGui::SameLine();
            if (ImGui::Button("Load")) {
                loadState();
            }
        }

        if (!_error.empty()) {
            ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.F, 0.F, 0.F, 1.F));
            ImGui::Text("%s", _error.data());
            ImGui::PopStyleColor();

            ImGui::SameLine();
            if (ImGui::Button("Dismiss")) {
                _error = "";
            }
        }

        if (_state == GameState::PLAYING || _state == GameState::SOLVING || _state == GameState::SOLVER
            || _state == GameState::FINISHED) {
            if (!_game.isSolvable()) {
                ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.F, 0.F, 0.F, 1.F));
                ImGui::Text("Game is not solvable!");
                ImGui::PopStyleColor();
            }

            ImGui::Text("Inversion Count: %d", _game.inversionCount());
            ImGui::Text("Moves: %d", _moves);

            if (_state == GameState::FINISHED) {
                ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.F, 1.F, 0.F, 1.F));
            }

            ImGui::Text("Elapsed: %llus", _elapsedTime.count());

            if (_state == GameState::FINISHED) {
                ImGui::PopStyleColor();
            }
        }
    }
    ImGui::End();
}

void GameApplication::renderSolver() {
    ImGui::SetNextWindowPos(ImVec2(255, 155));
    ImGui::SetNextWindowSize(ImVec2(235, 90));

    ImGui::Begin("Solver", nullptr, commonFlags);
    {
        if (_state == GameState::PLAYING) {
            if (ImGui::Button("Solve")) {
                _state = GameState::SOLVING;
                std::thread([&] {
                    _solverStep = 0;
                    _solver.reset(_game);
                    _solver.solve(ManhattanDistance());
                    _state = GameState::SOLVER;
                }).detach();
            }
        } else if (_state == GameState::SOLVING) {
            ImGui::Text("Solving...");
        } else if (_state == GameState::FINISHED) {
            ImGui::Text("Game is already solved");
        }

        if (_state == GameState::SOLVER) {
            if (ImGui::Button("Abort")) {
                _solverStep = -1;
                _state = GameState::PLAYING;
            }

            ImGui::SameLine();
            ImGui::Text("Elapsed: %.2fs", _solver.elapsed().count() / 1000.F);

            if (ImGui::Button("Prev")) {
                if (_solverStep > 0) {
                    _game = _solver.path()[--_solverStep];
                    _moves--;
                }
            }

            ImGui::SameLine();
            ImGui::Text("%d/%zu", _solverStep, _solver.path().size() - 1);
            ImGui::SameLine();

            if (ImGui::Button("Next")) {
                if (_solverStep < static_cast<uint32_t>(_solver.path().size()) - 1) {
                    _game = _solver.path()[++_solverStep];
                    _moves++;
                }
            }
        }
    }
    ImGui::End();
}

void GameApplication::renderScene(float /*dt*/) {
    renderGame();
    renderInfo();
    renderSolver();
}

void GameApplication::keyPressed(int32_t key, int32_t action) {
    if (_state != GameState::PLAYING) {
        return;
    }

    if (action == GLFW_PRESS) {
        switch (key) {
        case GLFW_KEY_UP:
        case GLFW_KEY_W:
            _game.move(Move::UP);
            _moves++;
            break;
        case GLFW_KEY_DOWN:
        case GLFW_KEY_S:
            _game.move(Move::DOWN);
            _moves++;
            break;
        case GLFW_KEY_LEFT:
        case GLFW_KEY_A:
            _game.move(Move::LEFT);
            _moves++;
            break;
        case GLFW_KEY_RIGHT:
        case GLFW_KEY_D:
            _game.move(Move::RIGHT);
            _moves++;
            break;
        default:
            break;
        }
    }
}

void GameApplication::saveState() {
    std::ofstream file("game_state.txt");
    if (file.is_open()) {
        for (int32_t i = 0; i < _game.size(); ++i) {
            file << _game.get(i) << " ";
        }
        file << "\n" << _moves << "\n";

        auto elapsed = std::chrono::duration_cast<std::chrono::seconds>(_elapsedTime);
        file << elapsed.count() << "\n";

        file.close();

        spdlog::info("Game state saved successfully");
    } else {
        spdlog::error("Failed to save game state");
    }
}

void GameApplication::loadState() {
    std::ifstream file("game_state.txt");

    if (file.is_open()) {
        _game = Game();
        for (int32_t i = 0; i < _game.size(); ++i) {
            int32_t value = -1;
            file >> value;

            if (value < 0 || value > _game.size() - 1) {
                spdlog::error("Invalid value {} at index {}", value, i);
                file.close();
                _game.reset();
                _error = "Save file is corrupted";
                return;
            }

            _game.set(i, value);
        }

        int32_t moves = -1;
        file >> moves;
        if (moves < 0) {
            spdlog::error("Invalid moves count {}", moves);
            file.close();
            _game.reset();
            _error = "Save file is corrupted";
            return;
        }
        _moves = moves;
        _state = GameState::PLAYING;

        int32_t elapsedSeconds = -1;
        file >> elapsedSeconds;

        if (elapsedSeconds < 0) {
            spdlog::error("Invalid elapsed time {}", elapsedSeconds);
            file.close();
            _game.reset();
            _error = "Save file is corrupted";
            return;
        }

        _elapsedTime = std::chrono::seconds(elapsedSeconds);
        _startTime = std::chrono::steady_clock::now() - _elapsedTime;
        spdlog::info("Game state loaded successfully");

        file.close();
    } else {
        _error = "Failed to open save file";
        spdlog::error("Failed to open save file");
    }
}

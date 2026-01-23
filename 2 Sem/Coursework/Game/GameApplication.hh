#pragma once

#include "Application.hh"
#include "Game.hh"
#include "Solver.hh"
#include <string_view>

enum class GameState { NONE, PLAYING, SOLVING, SOLVER, FINISHED };

class GameApplication : public Application {
    using Application::Application;

    virtual bool initialize() override;
    virtual void update(float dt) override;
    virtual void renderScene(float dt) override;
    virtual void keyPressed(int32_t key, int32_t action) override;

private:
    void renderGame();
    void renderInfo();
    void renderSolver();

    void saveState();
    void loadState();

    Game _game;
    uint32_t _moves;
    std::chrono::time_point<std::chrono::steady_clock> _startTime;
    std::chrono::seconds _elapsedTime;
    Solver _solver;
    uint32_t _solverStep {0};
    GameState _state {GameState::NONE};
    std::string_view _error {};

public:
    virtual ~GameApplication() = default;
};

#pragma once

#include "Game.hh"
#include "Heuristic.hh"
#include <chrono>
#include <deque>
#include <vector>

enum class SolverResult { OK, NOT_SOLVABLE, NO_SOLUTION_FOUND };

class Solver {
public:
    void reset(Game game) {
        _game = game;
        _solved = false;
        _path.clear();
        _startTime = std::chrono::steady_clock::now();
    }

    void solve(const Heuristic& heuristic);

    std::chrono::milliseconds elapsed() const {
        return std::chrono::duration_cast<std::chrono::milliseconds>(_endTime - _startTime);
    }

    bool isSolved() const {
        return _solved;
    }

    SolverResult result() const {
        return _result;
    }

    std::vector<Game>& path() {
        return _path;
    }

private:
    uint32_t search(
        std::deque<Game>& path,
        int32_t moveCost,
        int32_t threshold,
        const Heuristic& heuristic,
        float weight
    );

    SolverResult _result;
    bool _solved {false};
    Game _game;
    std::chrono::time_point<std::chrono::steady_clock> _startTime {};
    std::chrono::time_point<std::chrono::steady_clock> _endTime {};
    std::vector<Game> _path {};
};

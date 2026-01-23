#include "Solver.hh"

uint32_t Solver::search(
    std::deque<Game>& path,
    int32_t moveCost,
    int32_t threshold,
    const Heuristic& heuristic,
    float weight
) {
    const Game& state = *path.rbegin();

    uint32_t h = heuristic.solve(state);

    if (h == 0) {
        return 0;
    }

    uint32_t cost = moveCost + h * weight;
    if (cost > static_cast<uint32_t>(threshold)) {
        return cost;
    }

    uint32_t min = std::numeric_limits<uint32_t>::max();

    for (Move& nextMove : state.validMoves()) {
        Game nextState {state};
        nextState.move(nextMove);

        if (std::find(path.begin(), path.end(), nextState) == path.end()) {
            path.push_back(std::move(nextState));

            uint32_t temp = search(path, moveCost + 1, threshold, heuristic, weight);
            if (temp == 0) {
                return 0;
            }

            if (temp < min) {
                min = temp;
            }

            path.pop_back();
        }
    }

    return min;
}

void Solver::solve(const Heuristic& heuristic) {
    _startTime = std::chrono::steady_clock::now();
    _solved = false;

    if (!_game.isSolvable()) {
        _result = SolverResult::NOT_SOLVABLE;
        return;
    }

    std::deque<Game> path;
    path.push_back(_game);

    uint32_t threshold = heuristic.solve(_game);

    float weight = 1.5F;
    uint32_t result = -1;
    while (result != 0) {
        result = search(path, 0, threshold, heuristic, weight);

        if (result == std::numeric_limits<uint32_t>::max()) {
            _result = SolverResult::NO_SOLUTION_FOUND;
            return;
        }

        threshold = result;
    }

    _path.reserve(path.size());
    std::move(std::begin(path), std::end(path), std::back_inserter(_path));

    _solved = true;
    _endTime = std::chrono::steady_clock::now();

    _result = SolverResult::OK;
}

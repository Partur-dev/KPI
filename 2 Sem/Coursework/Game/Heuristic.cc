#include "Heuristic.hh"
#include "Game.hh"
#include <cmath>

uint32_t ManhattanDistance::solve(const Game& game) const {
    uint32_t distance = 0;

    int dimension = game.dimension();

    for (int n = 0, len = game.size(); n < len; n++) {
        if (game.get(n) == 0)
            continue;

        int realValue {game.get(n) - 1};
        if (realValue == n)
            continue;

        distance += std::abs((realValue / dimension) - (n / dimension))
                    + std::abs((realValue % dimension) - (n % dimension));
    }

    return distance;
}

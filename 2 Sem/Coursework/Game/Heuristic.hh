#pragma once

#include <cstdint>
class Game;

class Heuristic {
public:
    virtual uint32_t solve(const Game& game) const = 0;
    virtual ~Heuristic() = default;
};

class ManhattanDistance : public Heuristic {
public:
    uint32_t solve(const Game& game) const;
};

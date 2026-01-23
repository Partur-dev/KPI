#pragma once

#include <vector>

enum class Move { UP, DOWN, LEFT, RIGHT };

class Game {
public:
    using Board = std::vector<int>;

    Game();
    Game(const Game& p);
    Game(Game&& p);

    bool operator==(const Game& p) const;
    Game& operator=(const Game& p);
    Game& operator=(Game&& p);

    bool move(Move move);
    bool move(int);

    const int& get(int32_t index) const;
    const int& get(int32_t row, int32_t col) const;
    int& get(int32_t index);
    int& get(int32_t row, int32_t col);
    void set(int32_t index, int32_t value);
    void set(int32_t row, int32_t col, int32_t value);

    int32_t inversionCount() const;

    bool isSolvable() const;
    bool isSolved() const;

    std::vector<Move> validMoves() const;
    void shuffle();
    void reset();

    int32_t dimension() const;
    int32_t size() const;

    Board& board();

private:
    int32_t _blankRow {};
    int32_t _blankCol {};
    int32_t _dimension {};
    Board _board {};
};

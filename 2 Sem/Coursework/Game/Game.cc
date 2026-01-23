#include "Game.hh"
#include <algorithm>
#include <random>

Game::Game() : _dimension(4), _board(4 * 4) {
    reset();
}

Game::Game(const Game& p) :
    _blankRow(p._blankRow),
    _blankCol(p._blankCol),
    _dimension(p._dimension),
    _board(p._board) {}

Game::Game(Game&& p) :
    _blankRow(p._blankRow),
    _blankCol(p._blankCol),
    _dimension(p._dimension),
    _board(std::move(p._board)) {}

Game& Game::operator=(const Game& p) {
    _dimension = p._dimension;
    _blankRow = p._blankRow;
    _blankCol = p._blankCol;
    _board = p._board;

    return *this;
}

Game& Game::operator=(Game&& p) {
    _dimension = p._dimension;
    _blankRow = p._blankRow;
    _blankCol = p._blankCol;
    _board = std::move(p._board);

    return *this;
}

bool Game::operator==(const Game& p) const {
    if (_dimension != p._dimension)
        return false;

    if (_blankRow != p._blankRow || _blankCol != p._blankCol)
        return false;

    return std::equal(_board.begin(), _board.end(), p._board.begin());
}

bool Game::move(Move move) {
    switch (move) {
    case Move::UP:
        if (_blankRow == 0)
            return false;

        std::swap(get(_blankRow, _blankCol), get(_blankRow - 1, _blankCol));
        _blankRow--;
        return true;
    case Move::DOWN:
        if (_blankRow == _dimension - 1)
            return false;

        std::swap(get(_blankRow, _blankCol), get(_blankRow + 1, _blankCol));
        _blankRow++;
        return true;
    case Move::LEFT:
        if (_blankCol == 0)
            return false;

        std::swap(get(_blankRow, _blankCol), get(_blankRow, _blankCol - 1));
        _blankCol--;
        return true;
    case Move::RIGHT:
        if (_blankCol == _dimension - 1)
            return false;

        std::swap(get(_blankRow, _blankCol), get(_blankRow, _blankCol + 1));
        _blankCol++;
        return true;
    default:
        return false;
    }
}

bool Game::move(int32_t index) {
    if (index < 0 || index >= size())
        return false;

    auto row = index / _dimension;
    auto col = index % _dimension;

    if (row == _blankRow && col == _blankCol) {
        return false;
    } else if (row == _blankRow && col == _blankCol - 1) {
        return move(Move::LEFT);
    } else if (row == _blankRow && col == _blankCol + 1) {
        return move(Move::RIGHT);
    } else if (row == _blankRow - 1 && col == _blankCol) {
        return move(Move::UP);
    } else if (row == _blankRow + 1 && col == _blankCol) {
        return move(Move::DOWN);
    }

    return true;
}

const int& Game::get(int32_t index) const {
    return _board[index];
}

const int& Game::get(int32_t row, int32_t col) const {
    return _board[row * _dimension + col];
}

int& Game::get(int32_t index) {
    return _board[index];
}

int& Game::get(int32_t row, int32_t col) {
    return _board[row * _dimension + col];
}

void Game::set(int32_t index, int32_t value) {
    if (index < 0 || index >= size())
        return;

    if (value == 0) {
        _blankRow = index / _dimension;
        _blankCol = index % _dimension;
    }

    _board[index] = value;
}

int32_t Game::dimension() const {
    return _dimension;
}

int32_t Game::size() const {
    return _dimension * _dimension;
}

Game::Board& Game::board() {
    return _board;
}

std::vector<Move> Game::validMoves() const {
    std::vector<Move> moves;

    if (_blankRow > 0)
        moves.push_back(Move::UP);
    if (_blankRow < _dimension - 1)
        moves.push_back(Move::DOWN);
    if (_blankCol > 0)
        moves.push_back(Move::LEFT);
    if (_blankCol < _dimension - 1)
        moves.push_back(Move::RIGHT);

    return moves;
}

void Game::shuffle() {
    std::random_device dev {};
    std::mt19937 rng {dev()};
    std::uniform_int_distribution<int> dist {0, 4};

    int32_t times {(size() + 1) * 4};
    for (int32_t i {0}; i < times; i++) {
        std::vector<Move> moves {validMoves()};
        move(moves[dist(rng) % moves.size()]);
    }
}

void Game::reset() {
    int32_t n = 1;
    for (int32_t i = 0; i < size() - 1; i++)
        _board[i] = n++;

    _board[size() - 1] = 0;

    _blankRow = _dimension - 1;
    _blankCol = _dimension - 1;
}

int32_t Game::inversionCount() const {
    int32_t count = 0;

    int32_t len = size();
    int32_t last {len - 1};

    for (int32_t i {0}; i < last; i++) {
        if (_board[i] == 0)
            continue;

        for (int32_t j {i + 1}; j < len; j++) {
            if (_board[j] == 0)
                continue;

            if (_board[i] > _board[j])
                count++;
        }
    }

    return count;
}

// even && blank on even row => inv odd
// even && blank on odd row => inv even
// odd  && inv even => solvable
// odd  && inv odd => unsolvable
bool Game::isSolvable() const {
    int32_t invCount = inversionCount();

    if (_dimension % 2 == 0) {
        if (_blankRow % 2 == 0)
            return (invCount % 2 != 0);
        else
            return (invCount % 2 == 0);
    } else {
        return (invCount % 2 == 0);
    }
}

bool Game::isSolved() const {
    if (_blankRow != _dimension - 1 || _blankCol != _dimension - 1)
        return false;

    return inversionCount() == 0;
}

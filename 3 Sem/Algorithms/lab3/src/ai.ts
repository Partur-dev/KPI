import {
  type GameState,
  type Dot,
  type Player,
  BLUE_ROWS,
  RED_COLS,
  areAdjacent,
  linkExists,
  wouldCross,
  checkWin
} from './game'

export type Difficulty = 'easy' | 'medium' | 'hard'

interface Move {
  from: Dot
  to: Dot
}

export class AIPlayer {
  private player: Player
  private difficulty: Difficulty

  constructor(player: Player, difficulty: Difficulty) {
    this.player = player
    this.difficulty = difficulty
  }

  public findBestMove(state: GameState): Move | null {
    const possibleMoves = this.getPossibleMoves(state, this.player)

    if (possibleMoves.length === 0) return null

    // easy mode - random move
    if (this.difficulty === 'easy') {
      return possibleMoves[Math.floor(Math.random() * possibleMoves.length)]
    }

    // other modes - minimax
    const depth = this.difficulty === 'medium' ? 2 : 3

    // add variability cuz why not
    this.shuffleArray(possibleMoves)

    let bestScore = -Infinity
    let bestMove: Move | null = possibleMoves[0]

    for (const move of possibleMoves) {
      // simulate move
      this.applyMove(state, move)

      const score = this.minimax(state, depth - 1, -Infinity, Infinity, false)

      // undo move
      this.undoMove(state)

      if (score > bestScore) {
        bestScore = score
        bestMove = move
      }
    }

    return bestMove
  }

  private minimax(
    state: GameState,
    depth: number,
    alpha: number,
    beta: number,
    isMaximizing: boolean
  ): number {
    // check for terminal state
    if (checkWin(this.player, state)) return 10000 + depth // prefer winning sooner
    const opponent = this.player === 'blue' ? 'red' : 'blue'
    if (checkWin(opponent, state)) return -10000 - depth

    if (depth === 0) {
      return this.evaluateState(state)
    }

    const currentPlayer = isMaximizing ? this.player : opponent
    const moves = this.getPossibleMoves(state, currentPlayer)

    if (moves.length === 0) return 0

    if (isMaximizing) {
      let maxEval = -Infinity
      for (const move of moves) {
        this.applyMove(state, move)
        const evalScore = this.minimax(state, depth - 1, alpha, beta, false)
        this.undoMove(state)

        maxEval = Math.max(maxEval, evalScore)
        alpha = Math.max(alpha, evalScore)
        if (beta <= alpha) break
      }
      return maxEval
    } else {
      let minEval = Infinity
      for (const move of moves) {
        this.applyMove(state, move)
        const evalScore = this.minimax(state, depth - 1, alpha, beta, true)
        this.undoMove(state)

        minEval = Math.min(minEval, evalScore)
        beta = Math.min(beta, evalScore)
        if (beta <= alpha) break
      }
      return minEval
    }
  }

  // shortest path diff (opponent - me)
  // a path length is 0 for connected links, 1 for an available empty link.
  private evaluateState(state: GameState): number {
    const myDistance = this.getShortestPathDistance(state, this.player)
    const opponent = this.player === 'blue' ? 'red' : 'blue'
    const oppDistance = this.getShortestPathDistance(state, opponent)

    // multiply opponent distance to prioritize blocking
    return oppDistance * 1.5 - myDistance
  }

  private getShortestPathDistance(state: GameState, player: Player): number {
    const dots = player === 'blue' ? state.blueDots : state.redDots
    const links = player === 'blue' ? state.blueLinks : state.redLinks

    // build adjacency graph
    const graph = new Map<Dot, Array<{ node: Dot; cost: 0 | 1 }>>()

    // helper to add edge
    const addEdge = (d1: Dot, d2: Dot, cost: 0 | 1) => {
      if (!graph.has(d1)) graph.set(d1, [])
      graph.get(d1)!.push({ node: d2, cost })
    }

    // populate graph based on board state
    // we iterate all possible adjacencies between dots of this player
    for (let i = 0; i < dots.length; i++) {
      for (let j = i + 1; j < dots.length; j++) {
        const d1 = dots[i]
        const d2 = dots[j]

        if (areAdjacent(d1, d2)) {
          if (linkExists(d1, d2, links)) {
            // already linked: cost 0
            addEdge(d1, d2, 0)
            addEdge(d2, d1, 0)
          } else if (!wouldCross(d1, d2, state)) {
            // can build link: cost 1
            addEdge(d1, d2, 1)
            addEdge(d2, d1, 1)
          }
          // if wouldCross is true, no edge exists (blocked)
        }
      }
    }

    // BFS setup
    const dist = new Map<Dot, number>()
    const queue: Dot[] = []

    // initialize Start Nodes
    const startDots = dots.filter((d) =>
      player === 'blue' ? d.gridRow === 0 : d.gridCol === 0
    )

    for (const start of startDots) {
      dist.set(start, 0)
      queue.push(start)
    }

    let minDistanceToGoal = 1000 // effectively infinity

    while (queue.length > 0) {
      const u = queue.shift()!
      const currentDist = dist.get(u)!

      // check if goal reached
      // blue: bottom row
      // red: right col
      const isGoal =
        player === 'blue'
          ? u.gridRow === BLUE_ROWS - 1
          : u.gridCol === RED_COLS - 1

      if (isGoal) {
        if (currentDist < minDistanceToGoal) {
          minDistanceToGoal = currentDist
        }

        continue // find other paths
      }

      // check neighbors
      const neighbors = graph.get(u) || []
      for (const { node: v, cost } of neighbors) {
        const newDist = currentDist + cost
        if (!dist.has(v) || newDist < dist.get(v)!) {
          dist.set(v, newDist)

          queue.push(v)

          // prioritize lower cost
          queue.sort(
            (a, b) => (dist.get(a) || Infinity) - (dist.get(b) || Infinity)
          )
        }
      }
    }

    return minDistanceToGoal
  }

  // generate all valid moves for a player
  private getPossibleMoves(state: GameState, player: Player): Move[] {
    const moves: Move[] = []
    const dots = player === 'blue' ? state.blueDots : state.redDots
    const existingLinks = player === 'blue' ? state.blueLinks : state.redLinks

    for (let i = 0; i < dots.length; i++) {
      for (let j = i + 1; j < dots.length; j++) {
        const d1 = dots[i]
        const d2 = dots[j]

        if (areAdjacent(d1, d2)) {
          if (
            !linkExists(d1, d2, existingLinks) &&
            !wouldCross(d1, d2, state)
          ) {
            moves.push({ from: d1, to: d2 })
          }
        }
      }
    }
    return moves
  }

  // temp mutate to avoid deep cloning
  private applyMove(state: GameState, move: Move) {
    const links =
      state.currentPlayer === 'blue' ? state.blueLinks : state.redLinks

    links.push({
      from: move.from,
      to: move.to,
      player: state.currentPlayer
    })

    state.currentPlayer = state.currentPlayer === 'blue' ? 'red' : 'blue'
  }

  private undoMove(state: GameState) {
    state.currentPlayer = state.currentPlayer === 'blue' ? 'red' : 'blue'

    const links =
      state.currentPlayer === 'blue' ? state.blueLinks : state.redLinks

    links.pop()
  }

  private shuffleArray(array: any[]) {
    for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1))
      ;[array[i], array[j]] = [array[j], array[i]]
    }
  }
}

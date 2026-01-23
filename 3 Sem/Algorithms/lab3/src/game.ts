export type Player = 'blue' | 'red'

export interface Dot {
  x: number
  y: number
  player: Player
  gridRow: number
  gridCol: number
}

export interface Link {
  from: Dot
  to: Dot
  player: Player
}

export interface GameState {
  currentPlayer: Player
  blueDots: Dot[]
  redDots: Dot[]
  blueLinks: Link[]
  redLinks: Link[]
  selectedDot: Dot | null
  winner: Player | null
}

export const BLUE_ROWS = 5
export const BLUE_COLS = 4
export const RED_ROWS = 4
export const RED_COLS = 5

export function createGameState(): GameState {
  const blueDots: Dot[] = []
  const redDots: Dot[] = []

  // 5 rows x 4 cols, positioned between red dots
  for (let row = 0; row < BLUE_ROWS; row++) {
    for (let col = 0; col < BLUE_COLS; col++) {
      blueDots.push({
        x: 0, // Will be set by renderer
        y: 0,
        player: 'blue',
        gridRow: row,
        gridCol: col
      })
    }
  }

  // 4 rows x 5 cols, positioned between blue rows
  for (let row = 0; row < RED_ROWS; row++) {
    for (let col = 0; col < RED_COLS; col++) {
      redDots.push({
        x: 0, // will be set by renderer
        y: 0,
        player: 'red',
        gridRow: row,
        gridCol: col
      })
    }
  }

  return {
    currentPlayer: 'blue',
    blueDots,
    redDots,
    blueLinks: [],
    redLinks: [],
    selectedDot: null,
    winner: null
  }
}

export function areAdjacent(d1: Dot, d2: Dot): boolean {
  if (d1.player !== d2.player) return false

  const rowDiff = Math.abs(d1.gridRow - d2.gridRow)
  const colDiff = Math.abs(d1.gridCol - d2.gridCol)

  return (rowDiff === 0 && colDiff === 1) || (rowDiff === 1 && colDiff === 0)
}

export function linkExists(d1: Dot, d2: Dot, links: Link[]): boolean {
  return links.some(
    (link) =>
      (link.from === d1 && link.to === d2) ||
      (link.from === d2 && link.to === d1)
  )
}

// check if two line segments intersect
function segmentsIntersect(
  x1: number,
  y1: number,
  x2: number,
  y2: number,
  x3: number,
  y3: number,
  x4: number,
  y4: number
): boolean {
  const denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
  if (Math.abs(denom) < 0.0001) return false // parallel

  const t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom
  const u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / denom

  // use small epsilon to avoid floating point issues at endpoints
  const eps = 0.001
  return t > eps && t < 1 - eps && u > eps && u < 1 - eps
}

// check if a new link would cross any existing link
export function wouldCross(d1: Dot, d2: Dot, state: GameState): boolean {
  const allLinks = [...state.blueLinks, ...state.redLinks]

  for (const link of allLinks) {
    if (
      segmentsIntersect(
        d1.x,
        d1.y,
        d2.x,
        d2.y,
        link.from.x,
        link.from.y,
        link.to.x,
        link.to.y
      )
    ) {
      return true
    }
  }

  return false
}

// uses union-find to check if player has connected their sides
export function checkWin(player: Player, state: GameState): boolean {
  const dots = player === 'blue' ? state.blueDots : state.redDots
  const links = player === 'blue' ? state.blueLinks : state.redLinks

  const parent = new Map<Dot, Dot>()
  const rank = new Map<Dot, number>()

  for (const dot of dots) {
    parent.set(dot, dot)
    rank.set(dot, 0)
  }

  function find(dot: Dot): Dot {
    if (parent.get(dot) !== dot) {
      parent.set(dot, find(parent.get(dot)!))
    }
    return parent.get(dot)!
  }

  function union(d1: Dot, d2: Dot) {
    const r1 = find(d1)
    const r2 = find(d2)
    if (r1 === r2) return

    const rank1 = rank.get(r1)!
    const rank2 = rank.get(r2)!

    if (rank1 < rank2) {
      parent.set(r1, r2)
    } else if (rank1 > rank2) {
      parent.set(r2, r1)
    } else {
      parent.set(r2, r1)
      rank.set(r1, rank1 + 1)
    }
  }

  // union all linked dots
  for (const link of links) {
    union(link.from, link.to)
  }

  if (player === 'blue') {
    // blue -> top to bottom
    const topDots = dots.filter((d) => d.gridRow === 0)
    const bottomDots = dots.filter((d) => d.gridRow === BLUE_ROWS - 1)

    for (const top of topDots) {
      for (const bottom of bottomDots) {
        if (find(top) === find(bottom)) {
          return true
        }
      }
    }
  } else {
    // red -> left to right
    const leftDots = dots.filter((d) => d.gridCol === 0)
    const rightDots = dots.filter((d) => d.gridCol === RED_COLS - 1)

    for (const left of leftDots) {
      for (const right of rightDots) {
        if (find(left) === find(right)) {
          return true
        }
      }
    }
  }

  return false
}

export function getCurrentPlayerDots(state: GameState): Dot[] {
  return state.currentPlayer === 'blue' ? state.blueDots : state.redDots
}

export function getCurrentPlayerLinks(state: GameState): Link[] {
  return state.currentPlayer === 'blue' ? state.blueLinks : state.redLinks
}

// true if successful
export function tryMakeLink(from: Dot, to: Dot, state: GameState): boolean {
  const links = getCurrentPlayerLinks(state)

  if (
    areAdjacent(from, to) &&
    !linkExists(from, to, links) &&
    !wouldCross(from, to, state)
  ) {
    links.push({
      from,
      to,
      player: state.currentPlayer
    })

    if (checkWin(state.currentPlayer, state)) {
      state.winner = state.currentPlayer
    } else {
      state.currentPlayer = state.currentPlayer === 'blue' ? 'red' : 'blue'
    }

    return true
  }

  return false
}

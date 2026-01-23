import {
  type GameState,
  type Dot,
  BLUE_ROWS,
  RED_COLS,
  createGameState,
  getCurrentPlayerDots,
  tryMakeLink
} from './game'
import { AIPlayer } from './ai'

const DOT_RADIUS = 12
const CELL_SIZE = 60
const OFFSET_X = 60
const OFFSET_Y = 60

export type GameMode = 'pvp' | 'ai-easy' | 'ai-medium' | 'ai-hard'

export class GameRenderer {
  private canvas: HTMLCanvasElement
  private ctx: CanvasRenderingContext2D
  private indicator: HTMLDivElement
  private modeSelector: HTMLDivElement
  private state: GameState
  private mode: GameMode
  private ai: AIPlayer | null = null
  private isAIThinking: boolean = false

  constructor(container: HTMLElement) {
    // -- mode selector --
    this.modeSelector = document.createElement('div')
    this.modeSelector.style.cssText =
      'margin: 20px; font-size: 18px; font-family: sans-serif; text-align: center;'
    this.modeSelector.innerHTML = `
      <select id="mode-select" style="padding: 6px 12px; font-size: 16px; border-radius: 999px; border: 1px solid #313244; background: #1e1e2e; color: #cdd6f4;">
        <option value="pvp">Player vs Player</option>
        <option value="ai-easy">vs AI (Easy)</option>
        <option value="ai-medium">vs AI (Medium)</option>
        <option value="ai-hard">vs AI (Hard)</option>
      </select>
      <button id="restart-btn" style="margin-left: 10px; padding: 6px 12px; font-size: 16px; border-radius: 999px; border: none; background: #a6e3a1; color: #1e1e2e; cursor: pointer;">Restart</button>
    `

    // -- canvas --
    this.canvas = document.createElement('canvas')
    this.canvas.style = 'border-radius: 32px;'
    this.ctx = this.canvas.getContext('2d')!
    this.canvas.width = CELL_SIZE * RED_COLS + OFFSET_X
    this.canvas.height = CELL_SIZE * BLUE_ROWS + OFFSET_Y
    this.canvas.style.cursor = 'pointer'

    // -- indicator --
    this.indicator = document.createElement('div')
    this.indicator.style.cssText =
      'margin: 20px; font-size: 24px; font-family: sans-serif; text-align: center;'

    // -- container setup --
    container.style.cssText =
      'display: flex; flex-direction: column; align-items: center; padding: 20px;'
    container.appendChild(this.modeSelector)
    container.appendChild(this.indicator)
    container.appendChild(this.canvas)

    // initial state & event listeners
    this.mode = 'pvp'
    this.state = createGameState()
    this.updateDotPositions()

    this.canvas.addEventListener('click', this.handleClick.bind(this))

    const modeSelect = document.getElementById(
      'mode-select'
    ) as HTMLSelectElement
    modeSelect.addEventListener('change', (e) => {
      this.mode = (e.target as HTMLSelectElement).value as GameMode
      this.reset()
    })

    const restartBtn = document.getElementById(
      'restart-btn'
    ) as HTMLButtonElement
    restartBtn.addEventListener('click', () => this.reset())

    // render initial state
    this.render()
  }

  // set positions based on grid
  private updateDotPositions(): void {
    for (const dot of this.state.blueDots) {
      dot.x = OFFSET_X + CELL_SIZE * 0.5 + dot.gridCol * CELL_SIZE
      dot.y = OFFSET_Y + dot.gridRow * CELL_SIZE
    }

    for (const dot of this.state.redDots) {
      dot.x = OFFSET_X + dot.gridCol * CELL_SIZE
      dot.y = OFFSET_Y + CELL_SIZE * 0.5 + dot.gridRow * CELL_SIZE
    }
  }

  private getDotAt(x: number, y: number): Dot | null {
    const dots = getCurrentPlayerDots(this.state)

    for (const dot of dots) {
      const dx = dot.x - x
      const dy = dot.y - y
      if (dx * dx + dy * dy <= DOT_RADIUS * DOT_RADIUS * 2) {
        return dot
      }
    }
    return null
  }

  private handleClick(e: MouseEvent): void {
    if (this.isAIThinking) return

    const rect = this.canvas.getBoundingClientRect()
    const x = e.clientX - rect.left
    const y = e.clientY - rect.top

    const clickedDot = this.getDotAt(x, y)

    if (!clickedDot) {
      this.state.selectedDot = null
      this.render()
      return
    }

    if (!this.state.selectedDot) {
      this.state.selectedDot = clickedDot
      this.render()
      return
    }

    // try to create a link
    if (this.state.selectedDot === clickedDot) {
      this.state.selectedDot = null
      this.render()
      return
    }

    if (tryMakeLink(this.state.selectedDot, clickedDot, this.state)) {
      if (this.state.winner) {
        this.render()
        setTimeout(() => {
          alert(`${this.state.winner!.toUpperCase()} wins!`)
          this.reset()
        }, 100)
        return
      }

      // if playing against AI and it's now AI's turn
      if (this.mode !== 'pvp' && this.state.currentPlayer === 'red') {
        this.makeAIMove()
      }
    }

    this.state.selectedDot = null
    this.render()
  }

  private async makeAIMove(): Promise<void> {
    this.isAIThinking = true
    this.render()

    // small delay (primarily for better ux in easy/medium modes)
    await new Promise((resolve) => setTimeout(resolve, 500))

    const move = this.ai!.findBestMove(this.state)

    if (move) {
      tryMakeLink(move.from, move.to, this.state)

      if (this.state.winner) {
        this.render()
        this.isAIThinking = false
        setTimeout(() => {
          alert(`${this.state.winner!.toUpperCase()} wins!`)
          this.reset()
        }, 100)
        return
      }
    }

    this.isAIThinking = false
    this.render()
  }

  private reset(): void {
    this.state = createGameState()
    this.updateDotPositions()
    this.isAIThinking = false

    // setup ai if needed
    if (this.mode === 'ai-easy') {
      this.ai = new AIPlayer('red', 'easy')
    } else if (this.mode === 'ai-medium') {
      this.ai = new AIPlayer('red', 'medium')
    } else if (this.mode === 'ai-hard') {
      this.ai = new AIPlayer('red', 'hard')
    } else {
      this.ai = null
    }

    this.render()
  }

  private drawDot(dot: Dot, highlight: boolean = false): void {
    this.ctx.beginPath()
    this.ctx.arc(dot.x, dot.y, DOT_RADIUS, 0, Math.PI * 2)
    this.ctx.fillStyle = dot.player === 'blue' ? '#89b4fa' : '#f38ba8'
    this.ctx.fill()

    if (highlight) {
      this.ctx.strokeStyle = '#f9e2af'
      this.ctx.lineWidth = 3
      this.ctx.stroke()
    }
  }

  private render(): void {
    const { ctx, canvas } = this

    // clear
    ctx.fillStyle = '#181825'
    ctx.fillRect(0, 0, canvas.width, canvas.height)

    // goal lines
    // ctx.fillStyle = 'rgb(137, 180, 250, 0.1)'
    // ctx.fillRect(0, 0, canvas.width, OFFSET_Y / 2)
    // ctx.fillRect(0, canvas.height - OFFSET_Y / 2, canvas.width, OFFSET_Y / 2)

    // ctx.fillStyle = 'rgb(243, 139, 168, 0.1)'
    // ctx.fillRect(0, 0, OFFSET_X / 2, canvas.height)
    // ctx.fillRect(canvas.width - OFFSET_X / 2, 0, OFFSET_X / 2, canvas.height)

    // draw links
    for (const link of this.state.blueLinks) {
      ctx.beginPath()
      ctx.moveTo(link.from.x, link.from.y)
      ctx.lineTo(link.to.x, link.to.y)
      ctx.strokeStyle = '#89b4fa'
      ctx.lineWidth = 4
      ctx.stroke()
    }

    for (const link of this.state.redLinks) {
      ctx.beginPath()
      ctx.moveTo(link.from.x, link.from.y)
      ctx.lineTo(link.to.x, link.to.y)
      ctx.strokeStyle = '#f38ba8'
      ctx.lineWidth = 4
      ctx.stroke()
    }

    // draw dots
    for (const dot of this.state.redDots) {
      this.drawDot(dot, this.state.selectedDot === dot)
    }
    for (const dot of this.state.blueDots) {
      this.drawDot(dot, this.state.selectedDot === dot)
    }

    // update indicator
    let statusText = `Current player: <span style="color: ${
      this.state.currentPlayer === 'blue' ? '#89b4fa' : '#f38ba8'
    }; font-weight: bold;">${this.state.currentPlayer.toUpperCase()}</span>`

    if (this.isAIThinking) {
      statusText += ' <span style="color: #6c6f85;">(AI thinking...)</span>'
    }

    this.indicator.innerHTML = statusText
  }
}

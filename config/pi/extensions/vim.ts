import { CustomEditor, type ExtensionAPI } from "@earendil-works/pi-coding-agent"
import { matchesKey, truncateToWidth } from "@earendil-works/pi-tui"

type Mode = "normal" | "insert"

/** A small modal Vim layer for Pi's prompt editor. */
class VimEditor extends CustomEditor {
  private mode: Mode = "insert"
  private pendingOperator: "d" | null = null

  handleInput(data: string): void {
    if (matchesKey(data, "escape")) {
      this.pendingOperator = null
      if (this.mode === "insert") {
        this.mode = "normal"
        if (this.getText().length > 0) super.handleInput("\x1b[D")
        this.tui.requestRender()
        return
      }

      // Escape in normal mode retains Pi's normal interrupt/abort behavior.
      super.handleInput(data)
      return
    }

    if (this.mode === "insert") {
      super.handleInput(data)
      return
    }

    // Normal mode: printable characters are commands, not prompt text.
    if (this.pendingOperator === "d") {
      this.pendingOperator = null
      if (data === "d") {
        this.deleteCurrentLine()
        return
      }
    }

    switch (data) {
      case "d":
        this.pendingOperator = "d"
        return
      case "i":
        this.mode = "insert"
        this.tui.requestRender()
        return
      case "a":
        super.handleInput("\x1b[C")
        this.mode = "insert"
        this.tui.requestRender()
        return
      case "h":
        super.handleInput("\x1b[D")
        return
      case "j":
        super.handleInput("\x1b[B")
        return
      case "k":
        super.handleInput("\x1b[A")
        return
      case "l":
        super.handleInput("\x1b[C")
        return
      case "b":
        super.handleInput("\x1bb")
        return
      case "w":
        super.handleInput("\x1bf")
        return
      case "0":
        super.handleInput("\x01")
        return
      case "$":
        super.handleInput("\x05")
        return
      case "x":
        super.handleInput("\x04")
        return
      case "u":
        super.handleInput("\x1f")
        return
    }

    // Preserve Pi's non-printable/app-level shortcuts (Ctrl+C, model switching, …)
    // while swallowing unrecognized printable normal-mode commands.
    if (data.length === 1 && data.charCodeAt(0) >= 32) return
    super.handleInput(data)
  }

  private deleteCurrentLine(): void {
    const lines = this.getLines()
    const { line } = this.getCursor()

    super.handleInput("\x01")
    if (lines[line]!.length > 0) super.handleInput("\x0b")

    if (line < lines.length - 1) {
      super.handleInput("\x0b")
    } else if (line > 0) {
      super.handleInput("\x7f")
    }
  }

  render(width: number): string[] {
    const lines = super.render(width)
    if (lines.length > 0) {
      const label = this.mode === "normal" ? " NORMAL " : " INSERT "
      const lastLine = lines[lines.length - 1]!
      lines[lines.length - 1] = truncateToWidth(lastLine, width - label.length, "") + label
    }
    return lines
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    ctx.ui.setEditorComponent((tui, theme, keybindings) =>
      new VimEditor(tui, theme, keybindings),
    )
  })
}

import { appendFile, mkdir, readFile } from "node:fs/promises"
import { dirname, join } from "node:path"
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"

export default function (pi: ExtensionAPI) {
  const memoryPath = join(process.env.HOME ?? ".", ".pi/agent/memory.md")

  pi.registerCommand("remember", {
    description: "Append a durable note to the Pi memory file",
    handler: async (args, ctx) => {
      const note = args.trim()
      if (!note) {
        ctx.ui.notify("Usage: /remember <note>", "warn")
        return
      }
      await mkdir(dirname(memoryPath), { recursive: true })
      await appendFile(memoryPath, `\n- ${note}\n`, "utf8")
      ctx.ui.notify(`Saved to ${memoryPath}`, "info")
    },
  })

  pi.on("before_agent_start", async (event) => {
    try {
      const memory = await readFile(memoryPath, "utf8")
      return {
        systemPrompt: `${event.systemPrompt}\n\n# Pi durable memory\n\n${memory}`,
      }
    } catch {
      return undefined
    }
  })
}

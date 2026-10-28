// appends instruction files listed in context-files.json to every system prompt.
// the list is rendered by the dotnix pi module so it stays an option.
import { readFile } from "node:fs/promises"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"

type ContextFile = { label: string; path: string }

function redactSecrets(text: string): string {
  return text.replace(/(Sudo password:\s*).*/gi, "$1[redacted]")
}

function expandHome(path: string): string {
  return path.startsWith("~/") ? join(process.env.HOME ?? "", path.slice(2)) : path
}

export default function (pi: ExtensionAPI) {
  const listPath = join(dirname(fileURLToPath(import.meta.url)), "context-files.json")

  pi.on("before_agent_start", async (event) => {
    let files: ContextFile[] = []
    try {
      files = JSON.parse(await readFile(listPath, "utf8"))
    } catch {
      return
    }

    const sections: string[] = []
    for (const { label, path } of files) {
      try {
        const content = redactSecrets(await readFile(expandHome(path), "utf8"))
        sections.push(`## ${label}\n\n${content}`)
      } catch {
        // optional files are intentionally ignored
      }
    }

    if (sections.length === 0) return
    return {
      systemPrompt: `${event.systemPrompt}\n\n# Imported global instructions\n\n${sections.join("\n\n")}`,
    }
  })
}

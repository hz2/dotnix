// web_search and web_fetch tools backed by the dotnix-web cli, since pi has no
// built-in web access. the binary path is substituted by the dotnix pi module.
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"
import { Type } from "typebox"

const WEB = "@dotnixWeb@"
const TIMEOUT_MS = 45_000

const SEARCH_PARAMS = Type.Object({
  query: Type.String({ description: "Search query" }),
  count: Type.Optional(Type.Integer({ minimum: 1, maximum: 20, description: "Number of results, default 8" })),
})

const FETCH_PARAMS = Type.Object({
  url: Type.String({ description: "http or https url to fetch" }),
  raw: Type.Optional(Type.Boolean({ description: "Return the raw body instead of rendered text" })),
})

export default function (pi: ExtensionAPI) {
  const run = async (args: string[], signal: AbortSignal | undefined) => {
    const result = await pi.exec(WEB, args, { timeout: TIMEOUT_MS, signal })
    const text = result.code === 0 ? result.stdout : `dotnix-web failed (exit ${result.code}):\n${result.stderr}`
    return { content: [{ type: "text" as const, text: text.trim() || "(no output)" }], details: { code: result.code } }
  }

  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description: "Search the web. Returns numbered results with title, url and snippet.",
    promptSnippet: "Search the web for current docs, release notes, error messages",
    promptGuidelines: ["Use web_search, then web_fetch on the best result, when the answer depends on information outside the repo."],
    parameters: SEARCH_PARAMS,
    executionMode: "parallel",
    async execute(_id, params, signal) {
      return run(["search", "-n", String(params.count ?? 8), params.query], signal)
    },
  })

  pi.registerTool({
    name: "web_fetch",
    label: "Web Fetch",
    description: "Fetch a url and return it as plain text (html is rendered, other types returned as-is). Output is capped.",
    promptSnippet: "Read a web page or raw file by url",
    parameters: FETCH_PARAMS,
    executionMode: "parallel",
    async execute(_id, params, signal) {
      return run(params.raw ? ["fetch", "-r", params.url] : ["fetch", params.url], signal)
    },
  })
}

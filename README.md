# dotnix

Reusable NixOS and home-manager modules under one `dotnix.*` namespace, plus the
hosts that use them. Every module is off until enabled, so importing
`homeModules.default` or `nixosModules.default` changes nothing on its own.

## Layout

```
flake.nix          inputs; outputs are assembled from parts/
parts/             flake-parts modules: hosts, module exports, packages, checks, fmt, devshell
modules/common/    options shared by both module trees (dotnix.user)
modules/nixos/     system modules: user, nix, fish, fonts, audio, zram, nix-daemon fence, hyprland
modules/home/      home modules: shell, git, terminal, editors (helix, neovim), ai (pi, web, skills, rtk)
pkgs/              overlay: dotnix-web, rtk
config/            files the modules install: nvim lua, pi extensions and theme, agent skills
hosts/jos/         the laptop: hardware, system choices, home choices
tests/             eval-only module checks
```

## Use

```bash
sudo nixos-rebuild switch --flake ~/dotnix#jos   # nixos host
home-manager switch --flake ~/dotnix#jos         # any linux box, home only
nix flake check                                  # module tests + builds every config
nix fmt
```

From another flake:

```nix
inputs.dotnix.url = "github:<owner>/dotnix";

# home-manager
imports = [ inputs.dotnix.homeModules.default ];
nixpkgs.overlays = [ inputs.dotnix.overlays.default ];
dotnix.user = { name = "me"; email = "me@example.com"; };
dotnix.editors.helix.enable = true;
dotnix.ai.pi = {
  enable = true;
  providers.gateway = {
    baseUrl = "https://llm.example.com/v1";
    api = "openai-completions";
    apiKey = "!my-token-command";
    models."model-id" = { name = "Model"; contextWindow = 200000; maxTokens = 32000; };
  };
  extensions.gateway-auth = ./pi/gateway-auth.ts;   # add your own
  extensions.vim = null;                            # or drop a built-in
};
dotnix.ai.web.enable = true;    # web_search/web_fetch for pi, dotnix-web on PATH
dotnix.ai.skills.enable = true; # web-research skill for claude/pi/codex
```

On NixOS with the home-manager module, `dotnix.user` set on the system is passed
down to every home-manager user automatically.

## Agent web access

Pi has no built-in web tools, and some environments block the ones Claude Code
ships. `dotnix-web` covers both with plain https: `dotnix-web search <query>` and
`dotnix-web fetch <url>`. `dotnix.ai.web` installs it, registers it as pi tools,
and ships a skill telling shell-only agents to use it. Backends: duckduckgo
(default, no key), searxng, brave.

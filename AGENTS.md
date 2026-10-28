# dotnix

Public repo. Never commit secrets, work-specific hostnames, internal tool names
or employer config; those belong in a private flake that imports these modules
and sets options.

## Architecture

- `modules/` holds reusable modules, `hosts/` holds machine choices. Host files
  only enable modules and set values; anything another machine could reuse
  moves into a module.
- `parts/` assembles flake outputs with flake-parts. Module lists are explicit
  (`modules/*/default.nix`, `parts/modules.nix`); add new modules to both.
- `pkgs/` is the overlay; packages are also exposed as `packages.<system>`.
- `config/` holds non-nix files installed by modules (pi extensions, skills, nvim).

## Module rules

- Options live under `dotnix.<area>.<name>`; bind `cfg = config.dotnix.<...>`.
- Gate everything on `enable` (or an empty-by-default attrset). Importing a
  module must never change a system.
- Typed options with descriptions; prefer `mkDefault` for built-in entries in
  attrsets so consumers can override or null them out.
- No `with pkgs;`, no `rec`, no host values in modules.
- Secrets only as file paths or command strings (pi `!cmd`), never literals.
- When a module touches another module's options that may be absent, use
  `lib.optionalAttrs (options ? x)`, not `mkIf` (mkIf still declares the path).

## Verify

- `nix fmt` then `nix flake check` before every commit; it runs
  `tests/home-modules.nix` and builds the jos system and standalone home.
- Pure refactors: `nix eval --raw .#nixosConfigurations.jos.config.system.build.toplevel.drvPath`
  must not change. If it does, `nix-diff` old and new drvs (devshell has it).
- New module logic gets an assertion in `tests/home-modules.nix`; use
  `hmUnchecked` to test that a bad config trips an assertion.

## Style

Comments lowercase, brief, and explain why. No em dashes, arrows, emoji or
banner comments. Conventional commits, e.g. `feat(ai): ...`, `refactor(home): ...`.

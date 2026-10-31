{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.dotnix.ai.mcp;
in
{
  options.dotnix.ai.mcp = {
    enable = lib.mkEnableOption "shared MCP server definitions via home-manager's programs.mcp";

    servers = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      example = {
        context7 = {
          url = "https://mcp.context7.com/mcp";
          headers.CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
        };
      };
      description = ''
        Passed through verbatim to programs.mcp.servers (see that option for
        the schema). Empty by default, so nothing is shipped here. When
        non-empty, every enabled agent that supports it
        (dotnix.ai.claude, dotnix.ai.codex, programs.opencode) gets
        enableMcpIntegration turned on automatically.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs.mcp = {
          enable = true;
          inherit (cfg) servers;
        };
      }
      (lib.optionalAttrs (options.programs ? claude-code) {
        programs.claude-code.enableMcpIntegration = lib.mkDefault true;
      })
      (lib.optionalAttrs (options.programs ? codex) {
        programs.codex.enableMcpIntegration = lib.mkDefault true;
      })
      (lib.optionalAttrs (options.programs ? opencode) {
        programs.opencode.enableMcpIntegration = lib.mkDefault true;
      })
    ]
  );
}

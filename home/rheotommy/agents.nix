# Coding agents and the tools that sandbox them and review their work.
{ inputs, pkgs, ... }:

let
  # Taken from llm-agents.nix rather than nixpkgs, which lags behind these
  # fast-moving releases.
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.packages = [
    llmAgents.claude-code
    llmAgents.codex
    llmAgents.antigravity-cli

    # Sandboxing for agent-run commands. Claude Code's sandbox and the
    # sandbox-runtime CLI (srt) isolate commands with bubblewrap and relay
    # their network access through socat.
    llmAgents.sandbox-runtime
    pkgs.bubblewrap
    pkgs.socat

    # Review agent-made changes before they are committed.
    llmAgents.hunk

    # Token usage and cost from the agents' local session logs.
    llmAgents.ccusage

    # Agent plugins run their hooks with node from PATH, outside any project,
    # where mise provides none.
    pkgs.nodejs
  ];

  xdg.configFile."hunk/config.toml".source = ./config/hunk.toml;
}

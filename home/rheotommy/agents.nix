# Coding agents and the tools for reviewing their work.
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

    # Review agent-made changes before they are committed.
    llmAgents.hunk
  ];
}

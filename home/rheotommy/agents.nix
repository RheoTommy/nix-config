# Coding agents, their configuration, and the tools that sandbox them and
# review their work.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  # Taken from llm-agents.nix rather than nixpkgs, which lags behind these
  # fast-moving releases.
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

  # The agents' configuration lives in a private repository, cloned with ghq.
  # A flake input would need credentials on every machine and would publish
  # its revisions in flake.lock. The links point at the working copy instead
  # of the store, because the agents, and sessions on request, edit these
  # files in place.
  agentConfig = "${config.home.homeDirectory}/ghq/github.com/RheoTommy/agent-config";
in
{
  home.packages = [
    llmAgents.claude-code
    llmAgents.codex
    llmAgents.chatgpt
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

  home.file =
    lib.mapAttrs (_: path: { source = config.lib.file.mkOutOfStoreSymlink "${agentConfig}/${path}"; })
      {
        ".claude/CLAUDE.md" = "AGENTS.md";
        ".claude/statusline.sh" = "claude/statusline.sh";
        ".claude/hooks" = "claude/hooks";
        # Not the shared skills directory: Claude Code also syncs skills from
        # claude.ai into it, which the other agents must not load.
        ".claude/skills" = "claude/skills";

        ".codex/AGENTS.md" = "AGENTS.md";
        ".codex/config.toml" = "codex/config.toml";
        ".codex/hooks.json" = "codex/hooks.json";
        # herdr's integration installs its Codex hook here rather than in a
        # hooks directory, and checks its version at this path.
        ".codex/herdr-agent-state.sh" = "codex/herdr-agent-state.sh";
        ".codex/skills" = "codex/skills";

        # Of the three agents, only Codex reads this directory. The shared
        # skills go here rather than in ~/.codex/skills, which also holds the
        # skills bundled with Codex and the ones only Codex can use.
        ".agents/skills" = "skills";

        # Antigravity replaces a linked file with a regular one when it
        # writes, so its whole directory is linked.
        ".gemini/config" = "antigravity/config";
      };

  # Not in home.file: Claude Code follows only one level of the link when it
  # saves this file, then writes its temporary file into the read-only store
  # directory. A direct link keeps /effort and the permission prompts working.
  home.activation.linkClaudeSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    target=$HOME/.claude/settings.json
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      run mv "$target" "$target.bak"
    fi
    run ln -sfn ${agentConfig}/claude/settings.json "$target"
  '';
}

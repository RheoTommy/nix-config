# `agyp` and `agyw` run agy on the personal and the work Gemini API key. The
# keys are files that op-secrets writes, so a host that imports this module
# also declares those files.
{
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  # Runs agy on a Gemini API key instead of the signed-in subscription. The
  # provider is set for the one session, not in settings.json, which would
  # move plain `agy` off the subscription too. The key comes from a file
  # rather than `op run`, which needs the desktop app to approve it and so
  # fails over SSH.
  agyKeySettings = builtins.toJSON {
    modelProvider = "gemini";
    # agy's own list for API keys does not have Gemini 4 Carbon yet.
    customModelsConfig.customModels.carbon = {
      # No host, although the settings schema asks for one: agy 1.5.5 puts
      # everything after the scheme into the request path as the model name,
      # and the API answers 404.
      modelName = "gemini-api://models/gemini-4-carbon";
      label = "Gemini 4 Carbon";
    };
  };
  agyWithKey =
    name: secret:
    pkgs.writeShellApplication {
      inherit name;
      text = ''
        GEMINI_API_KEY=$(< ${osConfig.opSecrets.files.${secret}.path})
        export GEMINI_API_KEY
        exec agy --settings ${lib.escapeShellArg agyKeySettings} "$@"
      '';
    };
in
{
  home.packages = [
    (agyWithKey "agyp" "gemini-api-key-personal")
    (agyWithKey "agyw" "gemini-api-key-work")
  ];
}

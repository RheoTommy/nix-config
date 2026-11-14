# Google Workspace CLI (`gws`) for Gmail, Calendar, Tasks, and Drive.
{
  config,
  osConfig,
  pkgs,
  ...
}:

{
  home.packages = [
    pkgs.gws
  ];

  # Symlink out of the store so the OAuth client config stays out of the Nix
  # store and picks up updates written by op-secrets.
  xdg.configFile."gws/client_secret.json".source =
    config.lib.file.mkOutOfStoreSymlink osConfig.opSecrets.files.gws-client-secret.path;
}

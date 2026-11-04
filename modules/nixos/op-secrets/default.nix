# Writes secrets from 1Password to files that root services read, at boot and
# every six hours. A service account reads them, since a service cannot wait
# for someone to approve the desktop app. Its token is the one secret created
# by hand, once, before the first switch:
#   /etc/op-secrets/token  the token of a service account that can read only
#                          the vault the secrets live in
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.opSecrets;
  dir = "/var/lib/op-secrets";
  fetchLines = lib.mapAttrsToList (
    name: file:
    lib.escapeShellArgs (
      [
        name
        (pkgs.writeText "${name}.tpl" file.template)
      ]
      ++ map (service: "${service}.service") file.services
    )
  ) cfg.files;
in
{
  options.opSecrets = {
    package = lib.mkPackageOption pkgs "_1password-cli" { };
    files = lib.mkOption {
      default = { };
      description = "The files to write, each from a template of `op inject`.";
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              template = lib.mkOption {
                type = lib.types.str;
                example = "TOKEN={{ op://vault/item/password }}";
                description = "Text in which each secret reference is replaced by its value.";
              };
              services = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "The long-running services that read the file: they start after it is written, and restart when it changes, even if stopped. Leave out a service that a timer starts, which reads the file when it runs.";
              };
              path = lib.mkOption {
                type = lib.types.str;
                default = "${dir}/${name}";
                readOnly = true;
                description = "Where the file is written.";
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf (cfg.files != { }) {
    systemd.services = lib.mkMerge [
      {
        op-secrets = {
          description = "Write secrets from 1Password to files";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          path = [
            cfg.package
            pkgs.diffutils
          ];
          environment.OP_CONFIG_DIR = "/run/op-secrets";
          # Not only at boot: a token that stopped working would otherwise go
          # unnoticed until the next reboot.
          startAt = "*-*-* 00/6:00:00";
          serviceConfig = {
            Type = "oneshot";
            StateDirectory = "op-secrets";
            StateDirectoryMode = "0700";
            RuntimeDirectory = "op-secrets";
            RuntimeDirectoryMode = "0700";
            UMask = "0077";
            # A oneshot has no time limit by default, and the services that
            # read the files wait for this one.
            TimeoutStartSec = "5min";
            # Not an environment file, which would pass the token to every
            # command the script runs.
            LoadCredential = "token:/etc/op-secrets/token";
          };
          script = ''
            token=$(< "$CREDENTIALS_DIRECTORY/token")

            fetch() {
              local name=$1 template=$2 target="${dir}/$1" new="${dir}/$1.new"
              shift 2
              if ! OP_SERVICE_ACCOUNT_TOKEN=$token timeout --kill-after=5s 60s \
                op inject -f -i "$template" -o "$new"; then
                # Keeping the old value lets services start while the network
                # is down, such as Gatus, which records that it is down. The
                # unit still fails, so that a dead token can be noticed.
                if [[ -e "$target" ]]; then
                  echo "$name: could not fetch; keeping the previous value" >&2
                else
                  echo "$name: could not fetch, and there is no previous value" >&2
                fi
                return 1
              fi
              if cmp -s "$new" "$target"; then
                return 0
              fi
              # Each step is checked by hand: the caller's `||` turns off set -e
              # in here.
              mv "$new" "$target" || return 1
              if (( $# > 0 )); then
                # restart, not try-restart, so that a service that failed for
                # lack of this file starts once it exists. Without --no-block,
                # a restart that waits for this unit would deadlock.
                systemctl restart --no-block "$@" || return 1
              fi
            }

            status=0
            ${lib.concatMapStrings (line: "fetch ${line} || status=1\n") fetchLines}
            exit $status
          '';
          # Here rather than in the script, so that it also runs after a kill.
          postStop = "rm -f ${dir}/*.new";
        };
      }
      (lib.mkMerge (
        lib.mapAttrsToList (
          _: file:
          # Ordered but not wanted: a wanted fetch would run on every restart
          # of the service, and a slow one would space out a crash loop enough
          # to stay under the service's start limit.
          lib.genAttrs file.services (_: {
            after = [ "op-secrets.service" ];
          })
        ) cfg.files
      ))
    ];
  };
}

# The secrets this host reads from the 1Password vault "nixos-desktop".
{ config, ... }:

{
  opSecrets.files = {
    gatus-env = {
      template = ''
        NTFY_TOPIC={{ op://nixos-desktop/ntfy-topic/password }}
        GATUS_TOKEN={{ op://nixos-desktop/gatus-token/password }}
      '';
      services = [ "gatus" ];
    };
    restic-password.template = "{{ op://nixos-desktop/restic-password/password }}";
    calendar-id.template = "{{ op://nixos-desktop/calendar-id/password }}";
    calendar-service-account.template = "{{ op://nixos-desktop/calendar-service-account/notesPlain }}";
    # By item ID: the titles of these items hold parentheses, which a secret
    # reference cannot.
    gemini-api-key-personal = {
      template = "{{ op://nixos-desktop/fymcdgs2nyamg4elxl36jn25zy/credential }}";
      owner = "rheotommy";
    };
    gemini-api-key-work = {
      template = "{{ op://nixos-desktop/qs5rk3ekkkde6yt242cl77epgu/credential }}";
      owner = "rheotommy";
    };
  };
  jobAlerts = {
    environmentFile = config.opSecrets.files.gatus-env.path;
    # A failed run alerts at once, except the very first, when there is no file
    # yet for the alert to read. This catches the timer stopping: two runs
    # missed, plus a little room.
    jobs.op-secrets = 13;
  };
}

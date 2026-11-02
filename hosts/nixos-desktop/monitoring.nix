# Records the Wi-Fi, the line and DNS once a minute with Gatus, so that a slow
# network can be traced to one of them.
{ ... }:

let
  network =
    endpoint:
    {
      group = "network";
      interval = "1m";
    }
    // endpoint;
  resolve =
    name: server:
    network {
      inherit name;
      url = server;
      dns = {
        query-name = "example.com";
        query-type = "A";
      };
      conditions = [ "[DNS_RCODE] == NOERROR" ];
    };
in
{
  services.gatus = {
    enable = true;
    settings = {
      web = {
        address = "127.0.0.1";
        port = 7318;
      };
      storage = {
        type = "sqlite";
        path = "/var/lib/gatus/data.db";
        # Keep each check for a year, so that a later look can compare times of
        # day, seasons, or before and after a change. Gatus's own charts and
        # averages reach back only 30 days.
        maximum-number-of-results = 365 * 24 * 60;
      };
      endpoints = [
        (network {
          name = "router";
          url = "icmp://192.168.3.1";
          conditions = [ "[CONNECTED] == true" ];
        })
        (network {
          name = "internet";
          url = "icmp://1.1.1.1";
          conditions = [ "[CONNECTED] == true" ];
        })
        # What applications use: MagicDNS in tailscaled, which forwards to the
        # tailnet's resolver.
        (resolve "dns" "100.100.100.100")
        # The tailnet's resolver (Control D) asked directly, to tell a slow
        # tailscaled apart from a slow resolver.
        (resolve "dns-upstream" "76.76.2.2")
      ];
    };
  };
}

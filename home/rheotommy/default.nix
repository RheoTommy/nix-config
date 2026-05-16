{ ... }:

{
  imports = [
    ../../modules/home-manager/common
  ];

  home = {
    username = "rheotommy";
    homeDirectory = "/home/rheotommy";
    stateVersion = "25.11";
  };
}

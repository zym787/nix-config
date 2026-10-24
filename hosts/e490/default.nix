{...}: let
  hostVars = import ./variables.nix;
in {
  imports = [
    ./hardware-configuration.nix
    ../../common/nixos/core.nix
    ../../common/nixos/network.nix
    ../../common/nixos/desktop.nix
    ../../common/nixos/audio.nix
    ../../common/nixos/fonts.nix
    ../../common/nixos/ime.nix
    ../../common/nixos/printing.nix
    ../../common/nixos/systemd.nix
  ];

  networking.hostName = hostVars.hostName;

  users.users.drinkto = {
    isNormalUser = true;
    description = "drinkto";
    home = "/home/drinkto";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIIN0efXDzfUMXzuI26CiV2xTAkxp/b4HIphsUVQXxU4 drinkto4nixos"
    ];
    extraGroups = ["networkmanager" "wheel"];
  };

  home-manager.users.drinkto = {
    imports = [../../users/drinkto];
  };
}

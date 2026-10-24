{
  settings,
  pkgs,
  ...
}: let
  packages = settings.packages {inherit pkgs;};
in {
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = settings.permittedInsecurePackages;
  };

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["drinkto"];
    substituters = settings.substituters;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  system.stateVersion = settings.stateVersion;
  time.timeZone = "Asia/Shanghai";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "zh_CN.UTF-8/UTF-8"
      "zh_CN.GB18030/GB18030"
      "zh_CN.GBK/GBK"
      "zh_CN/GB2312"
    ];
  };

  environment.systemPackages = packages.system;
}

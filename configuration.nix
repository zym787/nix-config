# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # import home-manager
      # ./home.nix
    ];

  # 新增用户 drinkto
  users.users.drinkto = {
    isNormalUser = true;
    description = "drinkto";
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = [
    # replace with your own public key
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIIN0efXDzfUMXzuI26CiV2xTAkxp/b4HIphsUVQXxU4 drinkto4nixos"
    ];
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "zh_CN.UTF-8/UTF-8"
    "zh_CN.GB18030/GB18030"
    "zh_CN.GBK/GBK"
    "zh_CN/GB2312"
  ];
  # 字体
  fonts.packages = with pkgs; [
    # Maple Mono (Ligature TTF unhinted)
    maple-mono.truetype
    # Maple Mono NF (Ligature unhinted)
    maple-mono.NF-unhinted
    # Maple Mono NF CN (Ligature unhinted)
    maple-mono.NF-CN-unhinted
    # Maple Mono CN (Ligature hinted)
    maple-mono.CN
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    sarasa-gothic  #更纱黑体
    source-code-pro
    hack-font
    jetbrains-mono
    nerd-fonts.caskaydia-cove
  ];

  # 简单配置一下 fontconfig 字体顺序，以免 fallback 到不想要的字体
  fonts.fontconfig = {
    defaultFonts = {
      emoji = [
        "Maple Mono CN"
        "JetBrainsMono Nerd Font"
        "Noto Color Emoji" 
      ];
      monospace = [
        "Maple Mono CN"
        "JetBrainsMono Nerd Font"
        "Noto Sans Mono CJK SC"
        "Sarasa Mono SC"
        "DejaVu Sans Mono"
      ];
      sansSerif = [
        "JetBrainsMono Nerd Font"
        "Noto Sans CJK SC"
        "Source Han Sans SC"
        "DejaVu Sans"
      ];
      serif = [
        "JetBrainsMono Nerd Font"
        "Noto Serif CJK SC"
        "Source Han Serif SC"
        "DejaVu Serif"
      ];
    };
  };
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      # for flypy chinese input method
      fcitx5-rime
      # needed enable rime using configtool after installed
      fcitx5-configtool
      fcitx5-chinese-addons
      # fcitx5-mozc    # japanese input method
      fcitx5-gtk # gtk im module
    ];
  };
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable Hyprland
  programs.hyprland.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";
  services.xserver.displayManager.gdm.enable = true; 

  

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.displayManager.sddm.enable = true;
  # services.desktopManager.plasma6.enable = true;

  # GPU Driver
  # services.xserver.videoDrivers = [ "modesetting" ];
  # AMD Opensource Driver
  # services.xserver.videoDrivers = [ "amdgpu" ];

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  hardware.pulseaudio.enable = false;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     firefox
  #     tree
  #   ];
  # };

  # 启用 Flakes 特性以及配套的船新 nix 命令行工具
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # essential pkgs
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    curl

    bash-completion
    firefox

    # zen browser

    # inputs.zen-browser.packages."${system}".default # beta
    # inputs.zen-browser.packages."${system}".beta # or "beta-unwrapped"
    # inputs.zen-browser.packages."${system}".twilight # or "twilight-unwrapped"
    # # IMPORTANT: this package relies on the twilight release artifacts from the
    # # official zen repo and no new release is created, the artifacts are replaced
    # inputs.zen-browser.packages."${system}".twilight-official # or "twilight-official-unwrapped"

    # # you can even override the package policies
    # inputs.zen-browser.packages."${system}".default.override {
    #   policies = {
    #       DisableAppUpdate = true;
    #       DisableTelemetry = true;
    #       # find more options here: https://mozilla.github.io/policy-templates/
    #   };
    # }
  ];

#   systemd.services.clash-verge-rev = {
#     enable = true;
#     description = "clash verge rev";
#     serviceConfig = {
#       ExecStart = "${pkgs.clash-verge-rev}/bin/clash-verge-service";
#       tunMode=true;
#       autoStart=true;
#     };
#     wantedBy = [ "multi-user.target" ];
#   };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
#   services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Substituters Set sjtu Mirro
  # nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
  # 只启用指定的二进制缓存源,记得导入 lib
  nix.settings.substituters = lib.mkForce [ "https://mirrors.cernet.edu.cn/nix-channels/store" ];


  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?

}


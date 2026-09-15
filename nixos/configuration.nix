# configuration.nix —— 系统主配置文件（入口）
# =============================================================================
# 这个文件是 NixOS 的“总开关”，本身几乎不写具体配置，只做两件事：
#   1. 引入硬件配置（安装时自动生成的 hardware-configuration.nix）
#   2. 引入我们拆分好的各个模块（modules/、desktop/）和用户级配置（home/）
#
# 设计原则：把“系统级(root)”和“用户级(你的家目录)”分开，
# 把每一类配置拆到独立文件，方便单独阅读、修改、排查问题。
# 改完任意文件后，在终端执行 `sudo nixos-rebuild switch` 即可生效。
# =============================================================================
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # inputs.self.nixosModules.example

    # Or modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix
    # import home-manager
    # ./home.nix
    # ./modules/fcitx5
    # ./modules/catppuccin

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      # inputs.self.overlays.additions
      # inputs.self.overlays.modifications
      # inputs.self.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      #   vscode = prev.vscode.overrideAttrs (old: {
      #     src = prev.fetchurl {
      #       url = "https://mirrors.tuna.tsinghua.edu.cn/.../VSCode_1.112.0_linux-x64.tar.gz";  # 需替换为实际镜像地址
      #       sha256 = "0000000000000000000000000000000000000000000000000000";  # 需要正确的 hash
      #     };
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      allowUnfree = true;
      # 安装不安全的包
      permittedInsecurePackages = [
        "dotnet-runtime_6"
        "pnpm-10.29.2"
      ];
    };
  };

  nix = {
    settings = {
      # Enable flakes and new 'nix' command
      # 启用 Flakes 特性以及配套的船新 nix 命令行工具
      experimental-features = "nix-command flakes";
      # Opinionated: disable global registry
      # flake-registry = "";

      trusted-users = [
        "drinkto"
      ];
    };
    # Opinionated: disable channels
    # channel.enable = false;

    # lader
    # http_proxy = "http://127.0.0.1:7890";
    # https_proxy = "http://127.0.0.1:7890";

    # Substituters Set sjtu Mirro
    # substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
    # 只启用指定的二进制缓存源,记得导入 lib
    # substituters = lib.mkForce [ "https://mirrors.cernet.edu.cn/nix-channels/store" ];
  };

  # Configure network
  networking = {
    hostName = "nixos"; # Define your hostname.

    # Pick only one of the below networking options.
    # wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    networkmanager.enable = true; # Easiest to use and most distros use this by default.

    # Proxy
    # proxy = {
    #   default = "http://user:password@proxy:port/";
    #   noProxy = "127.0.0.1,localhost,internal.domain";
    # };

    # Open ports in the firewall.
    # firewall = {
    #   # allowedTCPPorts = [ ... ];
    #   # allowedUDPPorts = [ ... ];
    #   # Or disable the firewall altogether.
    #   # enable = false;
    # };
  };

  # TODO: Configure your system-wide user settings (groups, etc), add more users as needed.
  users.users = {
    drinkto = {
      # TODO: You can set an initial password for your user.
      # If you do, you can skip setting a root password by passing '--no-root-passwd' to nixos-install.
      # Be sure to change it (using passwd) after rebooting!
      # initialPassword = "correcthorsebatterystaple";
      isNormalUser = true;
      description = "drinkto";
      openssh.authorizedKeys.keys = [
        # replace with your own public key
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIIN0efXDzfUMXzuI26CiV2xTAkxp/b4HIphsUVQXxU4 drinkto4nixos"
      ];
      # TODO: Be sure to add any other groups you need (such as networkmanager, audio, docker, etc)
      extraGroups = [ "networkmanager" "wheel" ]; # Enable ‘sudo’ for the user.
      # packages = with pkgs; [
      #   firefox
      #   tree
      # ];
    };
  };

  # # This setups a SSH server. Very important if you're setting up a headless system.
  # # Feel free to remove if you don't need it.
  # services.openssh = {
  #   enable = true;
  #   settings = {
  #     # Opinionated: forbid root login through SSH.
  #     PermitRootLogin = "no";
  #     # Opinionated: use keys only.
  #     # Remove if you want to SSH using passwords
  #     PasswordAuthentication = false;
  #   };
  # };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time = {
    # Set your time zone.
    timeZone = "Asia/Shanghai";
  };

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "zh_CN.UTF-8/UTF-8"
      "zh_CN.GB18030/GB18030"
      "zh_CN.GBK/GBK"
      "zh_CN/GB2312"
    ];
    # 输入法支援
    inputMethod = {
      enable = true;
      type = "fcitx5";
      # 显式启用 Wayland 前端支持
      fcitx5.waylandFrontend = true;
      fcitx5.addons = with pkgs; [
        # for flypy chinese input method
        fcitx5-rime
        # needed enable rime using configtool after installed
        qt6Packages.fcitx5-configtool
        qt6Packages.fcitx5-chinese-addons
        # fcitx5-mozc    # japanese input method
        qt6Packages.fcitx5-qt
        fcitx5-gtk # gtk im module
      ];
    };
  };

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

  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable Hyprland
  # programs.hyprland.enable = true;
  # environment.sessionVariables.NIXOS_OZONE_WL = "1";
  # environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";
  # services.xserver.displayManager.gdm.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

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
  # hardware.pulseaudio.enable = false;
  services.pulseaudio.enable = false;
  # OR
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput = {
    enable = true;

    # 鼠标设置
    mouse = {
      accelProfile = "adaptive";    # 自适应加速，也可设为 "flat" 关闭加速
      naturalScrolling = false;     # 鼠标滚动方向（false 为传统方向）
      middleEmulation = false;      # 是否用左右键模拟中键
    };

    # 触控板设置
    touchpad = {
      naturalScrolling = true;      # 自然滚动（类似 macOS）
      tapping = true;               # 允许点击（轻触）
      tappingButtonMap = "lrm";     # 轻触映射：左、右、中（lrm）
      clickMethod = "clickfinger";  # 双指右键、三指中键（更适合触控板）
      accelProfile = "adaptive";    # 自适应加速
      disableWhileTyping = true;    # 打字时禁用触控板，防止误触
      scrollMethod = "twofinger";   # 双指滚动
    };
  };


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # essential pkgs
    vim
    wget
    git
    curl

    bash-completion
    firefox

    # appimage-run
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
  # services.openssh.enable = true;
}


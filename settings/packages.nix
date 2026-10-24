{pkgs}: {
  # 系统级：原 environment.systemPackages
  system = with pkgs; [
    vim
    wget
    git
    curl
    bash-completion
    firefox
  ];

  # 桌面与日常
  core = with pkgs; [
    fastfetch
    nnn
    yazi
    kdePackages.dolphin
    zip
    xz
    unzip
    p7zip
    unrar
    ripgrep
    jq
    yq-go
    eza
    fzf
    rofi
    tofi
  ];

  networking = with pkgs; [
    mtr
    iperf3
    dnsutils
    ldns
    aria2
    socat
    nmap
    ipcalc
    localsend
  ];

  dev = with pkgs; [
    vscode
    neovim
    direnv
    llvm
    clang-tools
    cmake
    ninja
    gnumake
    gcc-arm-embedded
    alejandra
  ];

  office = with pkgs; [
    obsidian
    texstudio
    evince
    wpsoffice-cn
    libreoffice
  ];

  ai = with pkgs; [
    cherry-studio
    cc-switch
    codex
    claude-monitor
    opencode-desktop
  ];

  desktop = with pkgs; [
    kitty
    ghostty
    zsh
    waybar
    mako
    waypaper
    hyprlock
    swaybg
    swaylock-effects
    swayidle
    wlogout
    wlsunset
    fuzzel
    uwsm
  ];

  utils = with pkgs; [
    cowsay
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg
    glow
    bat
  ];

  media = with pkgs; [
    splayer-next
    go-musicfox
    netease-cloud-music-gtk
    waylyrics
    logisim-evolution
  ];

  messaging = with pkgs; [
    brave
    telegram-desktop
    qq
    wechat
  ];

  systemTools = with pkgs; [
    btop
    iotop
    iftop
    netcat
    aircrack-ng
    wireshark
    termshark
    strace
    ltrace
    lsof
    sysstat
    lm_sensors
    ethtool
    pciutils
    usbutils
    ntfs3g
    polkit
  ];

  nixTools = with pkgs; [
    nix-output-monitor
    nh
    nix-du
    nix-tree
  ];

  cloud = with pkgs; [
    baidupcs-go
  ];
}

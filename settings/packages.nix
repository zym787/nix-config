# 包分组。system 组由 common/nixos/core.nix 安装到系统；
# 其余组由 users/drinkto 组合成 home.packages。
# 新增/删除包时保持分组语义，不要在两个组里重复同一个包。
{pkgs}: {
  # 系统级基础工具：登录后、任何桌面之前就需要可用。
  system = with pkgs; [
    vim
    wget
    git
    curl
    bash-completion
    firefox
  ];

  # 日常与文件管理
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

  # 网络诊断与传输
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

  # 开发工具（C/C++、嵌入式、Nix 格式化）
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

  # 办公/文档
  office = with pkgs; [
    obsidian
    texstudio
    evince
    wpsoffice-cn
    libreoffice
  ];

  # AI 客户端
  ai = with pkgs; [
    cherry-studio
    cc-switch
    codex
    claude-monitor
    opencode-desktop
  ];

  # 桌面/终端/Wayland 工具（当前 X11 会话也用得到终端和部分工具）
  desktop = with pkgs; [
    kdePackages.bluedevil # KDE 蓝牙托盘/配对界面
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

  # 通用 CLI 工具
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

  # 音乐/媒体/逻辑电路
  media = with pkgs; [
    splayer-next
    go-musicfox
    netease-cloud-music-gtk
    waylyrics
    logisim-evolution
  ];

  # 浏览器/即时通讯
  messaging = with pkgs; [
    brave
    telegram-desktop
    qq
    wechat
  ];

  # 系统监控/诊断
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

  # Nix 相关工具（nom/nh/du/tree）
  nixTools = with pkgs; [
    nix-output-monitor
    nh
    nix-du
    nix-tree
  ];

  # 云盘
  cloud = with pkgs; [
    baidupcs-go
  ];
}

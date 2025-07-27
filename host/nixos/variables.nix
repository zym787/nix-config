{
  # Git Configuration ( For Pulling Software Repos )
  gitUsername = "drinkto";
  gitEmail = "z_one787@163.com";

  # Set Displau Manager
  # `tui` for Text login
  # `sddm` for graphical GUI
  # SDDM background is set with stylixImage
  displayManager = "sddm";

  # Emable/disable bundled applications
  tmuxEnable = true;
  alacrittyEnable = true;
  weztermEnable = true;
  ghosttyEnable = true;
  vscodeEnable = true;
  helixEnable = true;

  # P10K or starship prompt
  userPrompt = "starship";

  # Hyprland Settings
  extraMonitorSettings = "monitor=,1920x1080@60,auto,1";

  # Waybar Settings
  clock24h = true;

  # Program OptionsintelBusID
  browser = "brave"; # Set Default Browser (google-chrome-stable for google-chrome)
  terminal = "kitty"; # Set Default System Terminal
  keyboardLayout = "us";
  consoleKeyMap = "us";

  # For Nvidia Prime support
  # intelID = "PCI:0:2:0";
  # amdID = "PCI:2:0:0";

  # Enable NFS
  enableNFS = true;

  # Enable Printing Support
  printEnable = false;

  # Enable Thunar GUI File Manager
  thunarEnable = true;

  # Set Stylix Image
  # This will set your color palette
  # Default background
  # Add new images to ~/zaneyos/wallpapers
  stylixImage = ../../wallpapers/mountainscapedark.jpg;
  #stylixImage = ../../wallpapers/AnimeGirlNightSky.jpg;
  #stylixImage = ../../wallpapers/Anime-Purple-eyes.png;
  #stylixImage = ../../wallpapers/Rainnight.jpg;
  #stylixImage = ../../wallpapers/zaney-wallpaper.jpg;
  #stylixImage = ../../wallpapers/nix-wallpapers-strips-logo.jpg;
  #stylixImage = ../../wallpapers/beautifulmountainscape.jpg;

  # Set Waybar
  # Available options:
  #waybarChoice= ../../modules/home/waybar/Jerry-simple.nix;
  #waybarChoice = ../../modules/home/waybar/Jerry-curved.nix;
  #waybarChoice = ../../modules/home/waybar/Jerry-waybar.nix;
  #waybarChoice = ../../modules/home/waybar/waybar-ddubs.nix;
  waybarChoice = ../../modules/home/waybar/waybar-ddubs-2.nix;

  # Set Animation style
  # Available options are:
  # animations-def.nix  (default)
  # animations-end4.nix (end-4 project)
  # animations-dynamic.nix (ml4w project)
  # animations-moving.nix (ml4w project)
  animChoice = ../../modules/home/hyprland/animations-end4.nix;
  #animChoice = ../../modules/home/hyprland/animations-def.nix;
  #animChoice = ../../modules/home/hyprland/animations-dynamic.nix;
  #animChoice = ../../modules/home/hyprland/animations-moving.nix;

  # Set network hostId if required (needed for zfs)
  # Otherwise leave as-is
  # hostId = "5ab03f50";
}

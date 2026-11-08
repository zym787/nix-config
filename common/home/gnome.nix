# GNOME 用户级外观与 Shell 扩展。
{
  pkgs,
  lib,
  ...
}: {
  # GNOME Shell 扩展：Home Manager 会安装包，并写入
  # dconf 的 org.gnome.shell.enabled-extensions。
  programs.gnome-shell = {
    enable = true;
    extensions = [
      # 用 GNOME 50 专用集合：pkgs.gnomeExtensions 是 49/50/51 的联合集，
      # 会被 GNOME 51 的 kimpanel v94 覆盖，而 v94 只声明支持 51。
      # 状态栏托盘：AppIndicator、KStatusNotifierItem 和 legacy tray。
      {package = pkgs.gnome50Extensions."appindicatorsupport@rgcjonas.gmail.com";}
      # 输入法面板：原手工安装的 kimpanel@kde.org。
      {package = pkgs.gnome50Extensions."kimpanel@kde.org";}
    ];
  };

  # 旧版 kimpanel 是手工解压到用户扩展目录的。迁移后把它改名备份，
  # 避免用户目录版本遮蔽 Nix/Home Manager 安装的版本。
  home.activation.backupLegacyKimpanel = lib.hm.dag.entryAfter ["installPackages"] ''
    legacy="$HOME/.local/share/gnome-shell/extensions/kimpanel@kde.org"
    if [ -d "$legacy" ] && [ ! -L "$legacy" ]; then
      mv "$legacy" "$legacy.manual-backup.$(${pkgs.coreutils}/bin/date +%Y%m%d%H%M%S)"
    fi
  '';

  # KDE 的 breeze_cursors 在禁用 KDE 后不再位于 XDG_DATA_DIRS，
  # 继续引用会显示灰色方块/没有指针。统一改回 GNOME 自带的 Adwaita。
  home.pointerCursor = {
    enable = true;
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;
    font = {
      name = "Fira Code";
      size = 10;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    colorScheme = "dark";
  };
}

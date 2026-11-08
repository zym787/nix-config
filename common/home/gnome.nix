# GNOME 用户级外观：光标、图标和 GTK 设置。
{pkgs, ...}: {
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

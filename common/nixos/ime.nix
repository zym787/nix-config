{pkgs, ...}: {
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      fcitx5-rime
      qt6Packages.fcitx5-configtool
      qt6Packages.fcitx5-chinese-addons
      qt6Packages.fcitx5-qt
      fcitx5-gtk
    ];
  };
}

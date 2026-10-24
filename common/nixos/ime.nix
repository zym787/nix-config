# 输入法：fcitx5 + Rime，启用 Wayland 前端。
# 安装后在 fcitx5-configtool 里添加/启用 Rime 方案。
{pkgs, ...}: {
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    # 显式启用 Wayland 前端支持（当前是 X11 会话，但保留以便切换）。
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      # Rime 输入法引擎（拼音/双拼/五笔等方案由 Rime 配置决定）
      fcitx5-rime
      # 图形化配置工具
      qt6Packages.fcitx5-configtool
      # 中文附加组件
      qt6Packages.fcitx5-chinese-addons
      # Qt / GTK 输入法模块
      qt6Packages.fcitx5-qt
      fcitx5-gtk
      # fcitx5-mozc # 日语输入法，需要时取消注释
    ];
  };
}

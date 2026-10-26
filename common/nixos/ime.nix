# 输入法：fcitx5 + Rime（雾凇拼音 rime-ice），启用 Wayland 前端。
# 安装后如果方案没自动切换，在 fcitx5-configtool 里重新选择 Rime。
{pkgs, ...}: {
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    # 显式启用 Wayland 前端支持。
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      # Rime + 雾凇拼音：比默认 luna_pinyin 更完整的词库、句子模型和常用短语。
      # rime-data 提供默认 global 配置，rime-ice 提供 rime_ice 方案和词库。
      (fcitx5-rime.override {
        rimeDataPkgs = [rime-ice rime-data];
      })
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

# Obsidian 官方 AppImage 管理。
#
# AppImage 统一放在 ~/Applications/AppImages/，本模块只生成启动器和桌面快捷方式。
# Nixpkgs 的 obsidian 包在当前 Electron/沙箱环境下无法稳定启动，因此不使用。
{
  config,
  pkgs,
  ...
}: let
  appImageDir = "${config.home.homeDirectory}/Applications/AppImages";
  launcher = pkgs.writeShellScriptBin "obsidian-appimage" ''
    set -euo pipefail

    app_dir="${appImageDir}"
    shopt -s nullglob
    apps=("$app_dir"/Obsidian*.AppImage)

    if [ "''${#apps[@]}" -eq 0 ]; then
      echo "未找到 Obsidian AppImage。" >&2
      echo "请把官方的 Obsidian-*.AppImage 放到：$app_dir" >&2
      exit 1
    fi

    # 按文件名排序，自动选择最新版本。
    app=$(printf '%s\n' "''${apps[@]}" | sort -V | tail -n 1)
    exec "$app" "$@"
  '';
in {
  home.packages = [launcher];

  # 创建集中管理目录；AppImage 文件本身不进入 Nix store 或 git。
  home.file."Applications/AppImages/.keep".text = "";

  xdg.dataFile."applications/obsidian-appimage.desktop".text = ''
    [Desktop Entry]
    Version=1.0
    Type=Application
    Name=Obsidian
    GenericName=Knowledge Base
    Comment=Obsidian official AppImage
    Exec=${launcher}/bin/obsidian-appimage %U
    Icon=accessories-text-editor
    Terminal=false
    Categories=Office;TextEditor;
    MimeType=x-scheme-handler/obsidian;text/markdown;
    StartupNotify=true
    StartupWMClass=obsidian
  '';
}

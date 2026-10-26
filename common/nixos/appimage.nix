# AppImage 支持：安装 appimage-run，并注册 binfmt 以便直接执行 AppImage。
{...}: {
  programs.appimage = {
    enable = true;

    # 注册 binfmt_misc 后，带执行权限的 .AppImage 可以直接双击/执行；
    # 如果某个 AppImage 没有执行权限，先 chmod +x，或使用
    # `appimage-run ./foo.AppImage`。
    binfmt = true;
  };
}

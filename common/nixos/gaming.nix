# 游戏：Steam + GameMode + MangoHud + gamescope（按需使用）。
{pkgs, ...}: {
  programs.steam = {
    enable = true;

    # 日常使用 Plasma 桌面会话，不把专用 gamescope 会话设为默认。
    # 如果以后想在 SDDM 里多一个类似 Steam Deck 的会话，再改为 true。
    gamescopeSession.enable = false;

    # 这些工具需要出现在 Steam 的 FHS 环境里，启动项才能直接调用。
    extraPackages = with pkgs; [
      gamemode
      gamescope
      mangohud
    ];
  };

  # 提供普通桌面会话里的 gamescope 命令（Steam 启动项可选用）。
  programs.gamescope.enable = true;
  # gamemoderun 可自动提升游戏进程优先级/CPU governor。
  programs.gamemode.enable = true;

  # 诊断和监控工具（vulkaninfo、mangohud）。
  environment.systemPackages = with pkgs; [
    vulkan-tools
    mangohud
  ];
}

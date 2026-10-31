# 游戏：Steam + GameMode + MangoHud + gamescope（按需使用）。
{pkgs, ...}: {
  programs.steam = {
    enable = true;

    # 专用游戏会话：SDDM 登录界面会多一个 “Steam” 会话，
    # 使用 gamescope + Steam Big Picture，一键进入游戏环境。
    # 日常仍默认 Plasma，工作和游戏会话分离。
    gamescopeSession = {
      enable = true;
      # 匹配 E490 的内屏分辨率/刷新率；进入会话后由 Steam 接管。
      # 如果 Big Picture 网页视图滚动出现乱码，可在 Steam 设置中关闭
      # “GPU accelerated rendering in web views”，或在 steamArgs 加
      # "-cef-disable-gpu"（会牺牲一点 UI 流畅度）。
      # 这里需要考虑使用强制FSR以低分辨率渲染再超分 `-F fsr`
      args = ["-W" "1920" "-H" "1080" "-f" "-r" "60"];

      # Steam 桌面版 Big Picture 没有 Steam Deck 的“性能”菜单；
      # 在游戏会话里默认启用 MangoHud，游戏中按 Shift_R+F12 切换。
      env = {
        MANGOHUD = "1";
      };
    };

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

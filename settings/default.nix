{ ... }:
{
  # 状态兼容版本，不是系统版本。系统是 26.11 unstable，但这里保持 25.05。
  # 除非按 NixOS 发行说明手动升级，否则不要改。
  stateVersion = "25.05";

  # 系统级二进制缓存，供 common/nixos/core.nix 的 nix.settings.substituters 使用。
  # 与 flake.nix 的 nixConfig 保持同步。
  substituters = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=10"
    "https://mirror.sjtu.edu.cn/nix-channels/store"
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://mirrors.cernet.edu.cn/nix-channels/store"
    "https://cache.nixos.org"
  ];

  # P1 先保留原列表并补注释；P5 再删除确认不用的条目。
  permittedInsecurePackages = [
    # Cherry Studio / VS Code 依赖的 Electron
    "electron-40.10.5"
    # Codex 相关工具依赖
    "pnpm-10.29.2"
    # Zotero 依赖；当前未安装 zotero
    "firefox-esr-140-bin-unwrapped-140.17.0esr"
    # .NET 6 运行时；当前未安装 dotnet-sdk
    "dotnet-runtime_6"
  ];

  # 包分组入口：settings.packages { inherit pkgs; }
  packages = import ./packages.nix;
}

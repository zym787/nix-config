# 全局变量与包分组入口。
# flake.nix 通过 `import ./settings { inherit inputs; }` 得到这个 attrset，
# 再经 specialArgs 传给 NixOS / Home Manager 模块。
{...}: {
  # 状态兼容版本，不是系统版本。系统是 26.11 unstable，但这里保持 25.05。
  # 除非按 NixOS 发行说明手动升级，否则不要改。
  stateVersion = "25.05";

  # 系统级二进制缓存，供 common/nixos/core.nix 的 nix.settings.substituters 使用。
  # 这里只列国内镜像；NixOS 默认值会自动补上 https://cache.nixos.org/，
  # 所以不要在这里重复写官方源，否则 nix config show 会出现两条官方地址。
  # 注意：flake.nix 的 nixConfig 是独立列表，仍保留官方源作为兜底。
  substituters = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=10"
    "https://mirror.sjtu.edu.cn/nix-channels/store"
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://mirrors.cernet.edu.cn/nix-channels/store"
  ];

  # 必须显式放行的不安全包；卸载依赖它们的软件后要同步删除对应条目。
  permittedInsecurePackages = [
    # Codex / opencode 相关工具链的构建依赖
    "pnpm-10.29.2"
    # Cherry Studio / VS Code 依赖的 Electron
    "electron-40.10.5"
  ];

  # 包分组函数：settings.packages { inherit pkgs; }
  # system 组由 core.nix 安装到系统；其余组由 users/drinkto 组合成 home.packages。
  packages = import ./packages.nix;
}

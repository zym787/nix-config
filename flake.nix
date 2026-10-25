{
  description = "Drinkto's NixOS configuration";

  # 所有外部输入。升级版本时改这里，然后执行 `nix flake update`。
  inputs = {
    # 系统主体使用 nixos-unstable，走清华 Git 镜像。
    nixpkgs.url = "git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-unstable&shallow=1";

    # Home Manager：让它的 nixpkgs 跟随本 flake 的 nixpkgs，
    # 避免两套 nixpkgs 版本不一致导致包重复或 eval 冲突。
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    # 当前只支持 x86_64-linux；新增架构时在这里扩展。
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    # 全局变量/包分组，传给 NixOS 和 Home Manager 模块。
    settings = import ./settings {inherit inputs;};

    # 自动发现 hosts/ 下的主机目录；以 _ 开头的目录（如 _template）会被忽略。
    hostNames =
      builtins.filter
      (n: !(nixpkgs.lib.hasPrefix "_" n))
      (builtins.attrNames (builtins.readDir ./hosts));

    # 为一台主机生成 NixOS 配置：
    # - specialArgs 把 inputs/settings 传给系统模块；
    # - home-manager 作为 NixOS module 挂载，switch 时一起部署用户配置。
    mkHost = host:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs settings;};
        modules = [
          ./hosts/${host}/default.nix
          home-manager.nixosModules.home-manager
          {
            # 用户级包使用系统 pkgs，避免重复实例化 nixpkgs。
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # 用户模块也需要 inputs 和 settings（stateVersion、包分组等）。
            home-manager.extraSpecialArgs = {inherit inputs settings;};
          }
        ];
      };

    # 生成 { e490 = <nixosSystem>; ... }
    configs = nixpkgs.lib.genAttrs hostNames mkHost;
  in {
    # flake 的 formatter 必须是“按 system 索引”的 attrset，
    # 不能直接是 derivation，否则 nix flake check 会把它当成 system 名。
    # 使用 `nix fmt .` 调用。
    formatter.${system} = pkgs.alejandra;

    # 格式检查作为 flake check 构建；CI 用 `nix flake check` 执行。
    # 这样不绑定具体主机/系统，任何 checkout 都可以验证格式。
    checks.${system}.formatting =
      pkgs.runCommand "check-formatting" {
        nativeBuildInputs = [pkgs.alejandra];
      } ''
        alejandra --check ${./.}
        touch $out
      '';

    # 通过 `nixos-rebuild --flake .#e490` 使用。
    nixosConfigurations = configs;
  };

  # nixConfig 是顶层属性，不能写在 outputs 的 attrset 里，
  # 否则 nix flake check 会报 unknown flake output 'nixConfig'。
  # 它只影响 flake 自身评估，不影响 nixos-rebuild 构建出来的系统；
  # 系统构建使用 common/nixos/core.nix 的 nix.settings.substituters。
  nixConfig = {
    substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=10"
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.cernet.edu.cn/nix-channels/store"
      # flake 命令的官方兜底；系统级列表由 NixOS 默认值补上官方源。
      "https://cache.nixos.org"
    ];
  };
}

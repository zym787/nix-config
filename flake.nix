{
  description = "Drinkto's NixOS configuration";

  inputs = {
    nixpkgs.url = "git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-unstable&shallow=1";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Phase 1 先保留，P5 删除；避免在迁移中途同时改 lock。
    nixpkgs-stable.url = "git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-26.05&shallow=1";
  };

  outputs = { nixpkgs, home-manager, ... } @ inputs:
    let
      system = "x86_64-linux";
      settings = import ./settings { inherit inputs; };

      hostNames = builtins.filter
        (n: !(nixpkgs.lib.hasPrefix "_" n))
        (builtins.attrNames (builtins.readDir ./hosts));

      mkHost = host: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs settings; };
        modules = [
          ./hosts/${host}/default.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs settings; };
          }
        ];
      };

      configs = nixpkgs.lib.genAttrs hostNames mkHost;
    in {
      # flake 的 formatter 必须是“按 system 索引”的 attrset，
      # 不能直接是 derivation，否则 nix flake check 会把它当成 system 名。
      formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;

      nixosConfigurations = configs;
    };

  # nixConfig 是顶层属性，不能写在 outputs 的 attrset 里，
  # 否则 nix flake check 会报 unknown flake output 'nixConfig'。
  nixConfig = {
    substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=10"
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.cernet.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
  };
}

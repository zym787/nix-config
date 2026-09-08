{
  description = "Drinkto's Nix configuration ";

  # ============================================================================
  # inputs:所有外部“原料”(nixpkgs / home-manager / DMS 等)
  # 想升级版本时,改这里的 URL 即可;改完执行 `nix flake update`
  # ============================================================================
  inputs = {
      # Nixpkgs
      # nixpkgs.url = "github:nixos/nixpkgs/nixos-26.11";
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
      # You can access packages and modules from different nixpkgs revs
      # at the same time. Here's an working example:
      # nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
      # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

      # Home-manager, used for managing user configuration
      home-manager = {
        url = "github:nix-community/home-manager";
        # The `follows` keyword in inputs is used for inheritance.
        # Here, `inputs.nixpkgs` of home-manager is kept consistent with
        # the `inputs.nixpkgs` of the current flake,
        # to avoid problems caused by different versions of nixpkgs.
        inputs.nixpkgs.follows = "nixpkgs";
      };

      # Catppuccin
      catppuccin = {
        url = "github:catppuccin/nix";
      };
    };

  outputs = {
      self,
      nixpkgs,
      home-manager,
      catppuccin,
      ...
  } @ inputs: let
    # Supported systems for your flake packages, shell, etc.
    system = [
      "x86_64-linux"
    ];
    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forAllSystems = nixpkgs.lib.genAttrs system;
    inherit (self) outputs;
  in {
    # # Your custom packages
    # # Accessible through 'nix build', 'nix shell', etc
    # packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
    # # Formatter for your nix files, available through 'nix fmt'
    # # Other options beside 'alejandra' include 'nixpkgs-fmt'
    # formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # # Your custom packages and modifications, exported as overlays
    # overlays = import ./overlays {inherit inputs;};
    # # Reusable nixos modules you might want to export
    # # These are usually stuff you would upstream into nixpkgs
    # nixosModules = import ./modules/nixos;
    # # Reusable home-manager modules you might want to export
    # # These are usually stuff you would upstream into home-manager
    # homeManagerModules = import ./modules/home-manager;

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          # > Our main nixos configuration file <
          ./nixos/configuration.nix
          {
            users.users.drinkto.home = "/home/drinkto";
            # given the users in this list the right to specify additional substituters via:
            #    1. `nixConfig.substituters` in `flake.nix`
            # nix.settings.trusted-users = [ "drinkto" ];
          }
          catppuccin.nixosModules.catppuccin

          # # Standalone home-manager configuration entrypoint
          # # Available through 'home-manager --flake .#your-username@your-hostname'
          # homeConfigurations = {
          #   # FIXME replace with your username@hostname
          #   "your-username@your-hostname" = home-manager.lib.homeManagerConfiguration {
          #     # Home-manager requires 'pkgs' instance
          #     pkgs = nixpkgs.legacyPackages.x86_64-linux; # FIXME replace x86_64-linux with your architecture 
          #     extraSpecialArgs = {inherit inputs;};
          #     modules = [
          #       # > Our main home-manager configuration file <
          #       ./home-manager/home.nix
          #     ];
          #   };
          # };

          # 将 home-manager 配置为 NixOS 的一个 module
          # 这样在 nixos-rebuild switch 时，home-manager 配置也会被自动部署
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            # 这里的 import 函数在前面 Nix 语法中介绍过了，不再赘述
            home-manager.users.drinkto = {
              imports = [
                ./home-manager/home.nix
                # catppuccin.homeManagerModules.catppuccin
                catppuccin.homeModules.catppuccin
              ];
            };


            # 使用 home-manager.extraSpecialArgs 自定义传递给 ./home.nix 的参数
            # 取消注释下面这一行，就可以在 home.nix 中使用 flake 的所有 inputs 参数了
            home-manager.extraSpecialArgs = inputs;
          }
        ];
      };
    };
  };


    # the nixConfig here only affects the flake itself, not the system configuration!
    nixConfig = {
      # override the default substituters
      substituters = [
        # cache mirror located in China
        # status: https://mirror.sjtu.edu.cn/
        "https://mirror.sjtu.edu.cn/nix-channels/store"
        # https://mirrors.tuna.tsinghua.edu.cn/status/#server-status
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        # status: https://mirrors.ustc.edu.cn/status/
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://mirrors.cernet.edu.cn/nix-channels/store"
        "https://cache.nixos.org"

        # "https://cache.nixos.org"
        # nix community's cache server
        # "https://nix-community.cachix.org"
        # hyprland
        # "https://hyprland.cachix.org"
      ];
      # trusted-public-keys = [
      #   # nix community's cache server public key
      #   # "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      #   # "nix-community.cachix.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      #   # "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      # ];
      # trusted-public-keys = [
      #   "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      #   "mirror.sjtu.edu.cn/nix-channels/store-1:rHTSQ80kHq27g7pRc2Qk5M5G5V3VvXkDw="
      #   "mirrors.ustc.edu.cn/nix-channels/store-1:ajXR9v+PiP9x63rM2ktGjLtM1F3pwQa5yf5H8tG6yY="
      #   "mirrors.tuna.tsinghua.edu.cn/nix-channels/store-1:o49HOs9Y2Nl4X2yXyf5H8tG6yY="
      # ];
    };

}

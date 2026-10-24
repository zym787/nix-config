{...}: {
  imports = [
    ./git.nix
    ./shell.nix
  ];

  programs.home-manager.enable = true;
}

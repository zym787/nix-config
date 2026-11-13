{...}: {
  programs.localsend = {
    enable = true;
    openFirewall = true; # 53317/TCP+UDP
  };
}

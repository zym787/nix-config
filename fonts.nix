{pkgs, ...}: {
  fonts = {
    packages = with pkgs; [
      dejavu_fonts
      fira-code
      fira-code-symbols
      font-awesome
      hackgen-nf-font
      ibm-plex
      inter
      jetbrains-mono
      material-icons
      maple-mono.NF
      minecraftia
      nerd-fonts.im-writing
      nerd-fonts.blex-mono
      noto-fonts
      noto-fonts-emoji
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-monochrome-emoji
      powerline-fonts
      roboto
      roboto-mono
      #symbola
      terminus_font
      # Maple Mono (Ligature TTF unhinted)
      maple-mono.truetype
      # Maple Mono NF (Ligature unhinted)
      maple-mono.NF-unhinted
      # Maple Mono NF CN (Ligature unhinted)
      maple-mono.NF-CN-unhinted
      # Maple Mono CN (Ligature hinted)
      maple-mono.CN
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      sarasa-gothic  #更纱黑体
      source-code-pro
      hack-font
      jetbrains-mono
      nerd-fonts.caskaydia-cove
    ];
  };
}

{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
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

  # 简单配置一下 fontconfig 字体顺序，以免 fallback 到不想要的字体
  fonts.fontconfig = {
    defaultFonts = {
      emoji = [
        "Maple Mono CN"
        "JetBrainsMono Nerd Font"
        "Noto Color Emoji"
      ];
      monospace = [
        "Maple Mono CN"
        "JetBrainsMono Nerd Font"
        "Noto Sans Mono CJK SC"
        "Sarasa Mono SC"
        "DejaVu Sans Mono"
      ];
      sansSerif = [
        "JetBrainsMono Nerd Font"
        "Noto Sans CJK SC"
        "Source Han Sans SC"
        "DejaVu Sans"
      ];
      serif = [
        "JetBrainsMono Nerd Font"
        "Noto Serif CJK SC"
        "Source Han Serif SC"
        "DejaVu Serif"
      ];
    };
  };
}

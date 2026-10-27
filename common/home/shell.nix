# 所有用户共享的 shell：zsh + oh-my-zsh + starship。
{lib, ...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      # 提示符由 starship 接管；oh-my-zsh 只负责插件和基础函数。
      theme = "";
      plugins = [
        "git"
        "sudo"
        "extract"
        "colored-man-pages"
        "z"
        "history-substring-search"
      ];
    };

    shellAliases = {
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
      lt = "eza --tree";
      cat = "bat";
      g = "git";
      nrs = "sudo nixos-rebuild switch --flake $HOME/Documents/nixos#e490";
      nrb = "sudo nixos-rebuild build --flake $HOME/Documents/nixos#e490";
    };

    # starship 的 Home Manager 模块会加入初始化；这里保留少量交互设置。
    initContent = lib.mkOrder 1000 ''
      setopt HIST_IGNORE_DUPS
      setopt SHARE_HISTORY
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$nix_shell$cmd_duration$character";
      right_format = "$time";

      # 当前没有 AWS/GCP 使用场景，关闭对应模块减少提示符噪音。
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;

      directory = {
        style = "bold cyan";
        truncation_length = 3;
        truncate_to_repo = true;
      };

      git_branch = {
        style = "bold purple";
        symbol = " ";
      };

      git_status = {
        style = "bold red";
      };

      nix_shell = {
        style = "bold yellow";
        symbol = "❄️ ";
        format = "[$symbol$state]($style) ";
      };

      cmd_duration = {
        min_time = 500;
        style = "bold yellow";
        format = "took [$duration]($style) ";
      };

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };

      time = {
        disabled = false;
        time_format = "%H:%M";
        style = "bold dimmed white";
      };
    };
  };
}

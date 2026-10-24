# 所有用户共享的 git 基础；user.name/email 在 users/<name>/default.nix 里设置。
{...}: {
  programs.git.enable = true;
}

# 所有用户共享的 starship 提示符配置。
{...}: {
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      # 当前没有 AWS/GCP 使用场景，关闭对应模块减少提示符噪音。
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;
    };
  };
}

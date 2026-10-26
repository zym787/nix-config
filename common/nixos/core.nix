# 所有主机共享的系统级基础配置。
# 主机特有硬件、hostName、用户列表放在 hosts/<host>/default.nix。
{
  settings,
  pkgs,
  ...
}: let
  # 包分组来自 settings/packages.nix；system 组装到系统 profile。
  packages = settings.packages {inherit pkgs;};
in {
  # 允许 unfree 软件；只放行确实需要的不安全包。
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = settings.permittedInsecurePackages;
  };

  # Nix 守护进程设置：
  # - 启用 flakes / nix 命令；
  # - drinkto 可以用 flake 的 nixConfig 指定 substituters；
  # - 国内镜像在 settings/default.nix，官方源由 NixOS 默认值补上。
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["drinkto"];
    substituters = settings.substituters;
    # DenialWM 官方 cache 的公钥；只追加，不覆盖 NixOS 默认公钥。
    "extra-trusted-public-keys" = [
      "denial.cachix.org-1:wd8YTnvPmugFrtdMJWtR1XdVknR3/g2nmBJkT+vAruo="
    ];
  };

  # 自动清理旧代际，并定期去重/优化 store。
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  # systemd-boot：保留最近 10 个代际，避免 boot 分区无限增长。
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  # 状态兼容版本：来自 settings，保持 25.05，不随系统 26.11 改动。
  system.stateVersion = settings.stateVersion;
  time.timeZone = "Asia/Shanghai";

  # 系统 locale；中文输入法在 common/nixos/ime.nix。
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "zh_CN.UTF-8/UTF-8"
      "zh_CN.GB18030/GB18030"
      "zh_CN.GBK/GBK"
      "zh_CN/GB2312"
    ];
  };

  # 系统级基础包（vim/wget/git/curl 等）；GUI 和日常软件在 home.packages。
  environment.systemPackages = packages.system;
}

# 代理：Clash Verge Rev（Mihomo 内核）。
# 选择它是因为桌面 GUI、订阅/规则管理、TUN/系统代理都齐全；
# dae 更适合无 GUI、配置即代码、eBPF 透明代理的场景。
{...}: {
  programs.clash-verge = {
    enable = true;

    # 系统服务模式：允许 TUN、DNS 接管等需要特权的能力。
    serviceMode = true;

    # TUN 透明代理；模块会自动：
    # - 给 GUI 二进制加 CAP_NET_ADMIN/CAP_NET_RAW 等 capabilities
    # - 把 networking.firewall.checkReversePath 设为 "loose"
    tunMode = true;

    # 登录桌面后自动启动 Clash Verge。
    autoStart = true;

    # 允许 wheel 组访问 service socket；drinkto 已在 wheel 组。
    group = "wheel";
  };
}

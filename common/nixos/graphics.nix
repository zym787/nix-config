# 图形/GPU：Intel UHD 620（i915，主显示）+ AMD Radeon 540X/550X（amdgpu，独显）。
# AMD Polaris 使用内核 amdgpu + Mesa RADV 即可，不需要闭源驱动。
{pkgs, ...}: {
  hardware.graphics = {
    enable = true;
    # Steam/Proton 需要 32-bit Vulkan/OpenGL 库。
    enable32Bit = true;

    # Vulkan loader/tools 让 Vulkan 游戏和 vulkaninfo 可用。
    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-tools
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      vulkan-loader
    ];
  };

  # 确保 AMD 独显驱动加载；Intel i915 由内核自动加载。
  boot.kernelModules = ["amdgpu"];

  # KDE 可以通过 switcheroo-control 选择“使用独显启动”。
  services.switcherooControl.enable = true;
}

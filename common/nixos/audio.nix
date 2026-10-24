# 音频：用 PipeWire 替代 PulseAudio，同时启用 PulseAudio 兼容层。
{...}: {
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    pulse.enable = true; # 让仍依赖 PulseAudio 的程序正常工作
  };
}

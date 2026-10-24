{ ... }:
{
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.libinput = {
    enable = true;

    mouse = {
      accelProfile = "adaptive";
      naturalScrolling = false;
      middleEmulation = false;
    };

    touchpad = {
      naturalScrolling = true;
      tapping = true;
      tappingButtonMap = "lrm";
      clickMethod = "clickfinger";
      accelProfile = "adaptive";
      disableWhileTyping = true;
      scrollMethod = "twofinger";
    };
  };
}

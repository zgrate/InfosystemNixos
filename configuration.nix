# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }:

let 
    HOSTNAME = "";
    SCREEN_IP = "";
    SCREEN_PASSPHRASE = "";
    ZERO_TIER_NETWORK = "";

    screenPythonEnv = pkgs.buildEnv {
      name = "screen-python-envs";
      paths = [
        (pkgs.python311.withPackages(ps: with ps; [requests]))  # Use the Python 3.11 interpreter installed as a system package
      ];
    };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  environment.sessionVariables = {
    SCREEN_IP = SCREEN_IP;
    SCREEN_PASSPHRASE = SCREEN_PASSPHRASE;
  };


  networking.wireless.networks =
  {
    "Hausmeerschweichen" = {
       psk = "1234567890abcde";
    };
  };

#  services.cage.program = "${pkgs.firefox}/bin/firefox -kiosk http://screen.futerkon.pl/";

  services.cage.program = "${screenPythonEnv}/bin/python /usr/script.py";


   users.users.kiosk = {
    isNormalUser = true;
    description = "Kioks user";
    extraGroups = [ "wheel" ];
    hashedPassword = "";
    uid = 1000;
  };


  boot.plymouth.enable = true;
  boot.plymouth.logo = pkgs.fetchurl {
          url = "https://storage.zgrate.ovh/znerd-small.png";
          sha256 = "e8a692068c9ce6ccfe40186ca0e0096d966205b70f413c309ff8051e98e2592e";
        };


  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    mpv
    firefox
    socat
    python311
    git
    htop
  ];


    # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = HOSTNAME; # Define your hostname.
  # Pick only one of the below networking options.
  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  #networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.


  # Set your time zone.
  time.timeZone = "Europe/Warsaw";


  # Enable the X11 windowing system.
  # services.xserver.enable = true;


  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  services.zerotierone.enable = true;
  services.zerotierone.joinNetworks = [ZERO_TIER_NETWORK];


  services.cage.enable = true;
  services.cage.user = "kiosk";

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  nixpkgs.config.pulseaudio = true;

  security.polkit.extraConfig = '' 
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };


  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  networking.dhcpcd.wait = "if-carrier-up";

  systemd.network.wait-online.anyInterface = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}

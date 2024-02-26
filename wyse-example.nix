# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }:

let 
    HOSTNAME = "bajojajo";
    SCREEN_IP = "https://info.zgrate.ovh/";
    SETTINGS_DIR = "/home/kiosk/screen_settings.json";
    ZERO_TIER_NETWORK = "e5cd7a9e1c094dca";
    KIOSK_HASHED_PASSWORD = "$6$4Q1YUuy1.m9Wq01t$fHXCAT5AadB5ajpQ4N.E5wBNGm/X3TrA0rzNGjWyPzm9BWQn/QCHbd.pX5y7ZNjc43No.3iFqSTmYB9HztUXD1";

    NETWORK_CONFIGURATION = {
        "Hausmeerschweichen" = {
           psk = "1234567890abcde";
        };
    };

#    screenPythonEnv = pkgs.buildEnv {
#      name = "screen-python-envs";
#      paths = [
#        (pkgs.python311.withPackages(ps: with ps; [requests]))  # Use the Python 3.11 interpreter installed as a system package
#      ];
#    };

    screensystem = pkgs.python3Packages.callPackage ./pyglue/default.nix {};
in
{
  users.users.root.password = "2137";

  boot.kernelParams = [ "console=tty0" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ rtl8812au ];

  environment.sessionVariables = {
    SCREEN_IP = SCREEN_IP;
    SETTINGS_DIR = SETTINGS_DIR;
  };

  # EFI Boot
  # nixos-generators uses GRUB, do not enable 2 bootloaders at once.
  #boot.loader = {
  #  systemd-boot.enable = true;
  #  efi.canTouchEfiVariables = true;
  #};

  # Plymouth
  boot.plymouth.enable = true;
  boot.plymouth.logo = pkgs.fetchurl {
    url = "https://storage.zgrate.ovh/znerd-small.png";
    sha256 = "e8a692068c9ce6ccfe40186ca0e0096d966205b70f413c309ff8051e98e2592e";
  };

  # Optimise storage
  nix.settings.auto-optimise-store = true;

  # Networking
  systemd.network.wait-online.anyInterface = true;
  networking = {
    hostName = HOSTNAME;
    wireless = {
      enable = true;
      networks = NETWORK_CONFIGURATION;
    };
    dhcpcd.wait = "if-carrier-up";
  };

  # Time zone
  time.timeZone = "Europe/Warsaw";

  # User accounts
  users.groups.kiosk.gid = 1000;
  users.users.kiosk = {
    uid = 1000;
    group = "kiosk";
    description = "Kiosk user";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPassword = KIOSK_HASHED_PASSWORD;
  };

  # Packages installed
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim wget mpv firefox socat python311 git htop pamix vlc
    screensystem
  ];

  # GPU
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

  # Sound
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  nixpkgs.config.pulseaudio = true;

  # Security
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

  # OpenSSH
  services.openssh.enable = true;

  # ZeroTier
  services.zerotierone = {
    enable = true;
    joinNetworks = [ZERO_TIER_NETWORK];
  };

  # Cage
  services.cage = {
    enable = true;
    user = "kiosk";
    program = "${screensystem}/bin/screensystem";
  };

  # Prometheus Node Exporter
  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = true;
    extraFlags = [ "--collector.filesystem.ignored-mount-points='^/(sys|proc|dev|host|etc|snap|var/lib/docker/.+)($$|/)'" "--collector.filesystem.ignored-fs-types='^(nfs.*|tmpfs|autofs|binfmt_misc|cgroup|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|mqueue|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|sysfs|tracefs)$'" ];
  };

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

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./discourse.nix
  ];

  # Basic system configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "discourse";
  networking.networkmanager.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
  ];

  # Enable services
  services.openssh.enable = true;

  # User configuration
  users.users.discourse = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.bash;
  };

  # System state version
  system.stateVersion = "23.11";
}

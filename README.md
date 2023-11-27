# InfosystemNixos

This is public repository with script starting up in Cage environment

## Please DO NOT include any private keys and secrets in this repo, it will be public for sake of easy pulling on kiosks!


# Installation Instruction
1. Install Nixos as a clean installation with internet
2. Type in ``nixos-shell -p git`` to open shell with git
3. ``git clone https://github.com/zgrate/InfosystemNixos.git``
4. ``exit``
5. ``cd InfosystemNixos``
6. ``chmod +x *.sh``
7. ``sudo ./install_repo.sh``
8. After installation open configuration.nix (``sudo nano /etc/nixos/configuration.nix``)
9. Fill up the data between the quotes
   - HOSTNAME -> What is the hostname of a device?
   - SCREEN_IP ->  IP Address of a ScreenSystemServer
   - SCREEN_PASSPHRASE -> Passphrase of a given screen
   - ZERO_TIER_NETWORK -> ID of a network in ZeroTier
   - KIOSK_HASHED_PASSWORD -> Hashed password to a user KIOS (Use command ``mkpasswd -m sha-512`` to hash a password)
   - NETWORK_CONFIGURATION -> Specify network and password of networks to connect, in a setup seen in an example
10. Save (CTRL+O -> Enter -> CTRL+X)
11. ``sudo nixos-rebuild reboot``
12. On restart you should get a black screen or automatic kiosk mode

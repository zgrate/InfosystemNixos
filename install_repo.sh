if [ "$EUID" -ne 0 ]; then
    echo "You are not root"
    exit
fi

git clone https://github.com/zgrate/InfosystemNixos.git
cp InfosystemNixos/clone_repo.sh .
chmod +x clone_repo.sh
./clone_repo.sh
cp /etc/nixos/configuration.nix backup.nix.old
cp InfosystemNixos/configuration.nix /etc/nixos/configuration.nix

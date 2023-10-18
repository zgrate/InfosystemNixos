# !/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
    echo "You are not root"
    exit
fi

FOLDER=./InfosystemNixos
REPO=https://github.com/zgrate/InfosystemNixos.git

if [ -d "$FOLDER" ]; then
    echo "EXISST"
else
    echo "NOT EXISTS"
    git clone "$REPO"
fi

cd $FOLDER
git checkout main
git pull

cp script.py /usr/script.py

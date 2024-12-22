#!/bin/bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install git-delta ruplacer ripgrep typos
brew install --HEAD utf8proc
brew install --HEAD neovim

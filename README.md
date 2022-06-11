# my dotfiles

A list of my dotfiles

Includes

- tmux with weather using wttr.in in statusline
- zsh
- neovim with vim-plug, built in lsp

If you take nothing else from this, try the weather statusline in .tmux.conf!
It's fun :)

Favorite vim keybindings:

- `ww` - save in vim (instead of :w)
- `qq` - quit vim (instead of :q)
- `<leader>gg` - file name search (fzf+git ls-files)
- `<leader>ff` - file content search (fzf+live grep)

leader for me is comma (,)

I have gotten repetitive strain injury from excessive keyboard shortcuts that
use the control key (left control, left pinky gets twinged, sometimes called
emacs pinky though I don't use emacs). Therefore I try to avoid keypresses that
use it. I also remap caps lock to left-control (screenshot
https://askubuntu.com/a/1044001/487959) which helps to reduce some left pinky
contortions.

## Install

Just copy or symlink these files to your home folder. It's not intricately
crazy so you don't need an installation process

## Details about my setup

- Computer - Dell laptop with 32gb RAM, 512GB SSD
- OS - Ubuntu 22.04
- Music player - foobar2000 snap (uses wine on linux)
- Text editor - neovim+build in lsp+treesitter+fzf
- Browser - Chromium
- Browser Add-ons - Dark Reader

I perform a lot of work in tmux+neovim where I split the screen vertically (two
halves side by side) with tmux and then do either tests on one side of the
screen or have two split screens. If needed I make a new tmux tab. I close and
re-open vim a lot which is kind of crazy in a way, but seems to work for me

Using fzf for quick file name searches or greps enabled me to become
much less reliant on a file browser like NERDTree, so I don't use any NERDTree
type sidebar

## Screenshot

![](img/1.png)

## Random other notes

### Music player setup

I am running foobar2000 under Wine (from the `snap install foobar2000` installation route)

My main customization goals of pretty much any music player are to have

- A list of albums in the form `Artist - Album name` (as opposed to an itunes
  style layout where it is a list of artists and then a separate list of
  albums)
- A recently added playlist
- A recently played playlist

![](img/3.png)

## Old stuff

[OLD.md](./OLD.md)

## References

https://github.com/manzt/dotfiles

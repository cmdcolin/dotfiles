# Text editors

## Vim setup iterations

- Used basically a zero config vim setup for a long time with no plugins
- Then got vim-plug and used w0rp/ale plugin for auto-lint-on-save
- Then tried to get Nerdtree to work with my setup
- Then tried to get vim-vinegar to display in a sidebar as an alternative
- Then got rid of sidebar preferring to auto-launch finding files using Fzf
- Then moved to coc.nvim and neovim for LSP support
- Was hard for me to understand native LSP, and the larger amount of boilerplate
  config still is tedious though the fine grained control is interestingly
- Used lsp-zero for a long time until it was discontinued. Tried briefly to use
  kickstart.nvim but just a lot of boilerplate to manage. Trying lazyvim now

# Music player history

## Old music player setups

### foobar2000

Running foobar2000 under Wine (from the `snap install foobar2000` installation
route)

My main customization goals of pretty much any music player are to have

- A list of albums in the form `Artist - Album name` (as opposed to an itunes
  style layout where it is a list of artists and then a separate list of albums)
- A recently added playlist
- A recently played playlist

![](../img/3.png)

### quod libet

I used quod libet for awhile but it stopped working entirely and also was not a
great user experience unfortunately. It was a bit slow, had to force rescan
library frequently, and I just spent most of my time listening on youtube
instead of in the player!

![](../img/2.png)

To get the list in the format `Artist - Album name`, and to add some support so
that "Various artists" compilations get merged into a single item in this list,
I use this config in quodlibet's paned browser

```
    <performer|<performer>|<albumartist|<albumartist>|<artist>>>  -  <album>
```

Then I also turn on "Last played" and "Added" columns in the playlist browser to
sort by last played and recently added

### cmus setup

I used to use cmus command line audio player. It worked well but I never felt
entirely comfy in it. Nevertheless here are some notes

#### Recently added playlist

I had a "Recently added" playlist in cmus generated by a crontab

```
* * * * * find ~/Music -type f -exec stat --printf "\%Z\t\%n\n" {} +|sort -rn|tail -n 5000|cut -f2|grep -v jpg|grep -v jpeg > ~/.config/cmus/recently_added.pl
```

Note the usage of stat with %Z which is "time of last status change", which
helps with files unpacked from zip files and is different from standard measures
of file time such as "created, last access, and last modification"

### Recently played playlist

I also used set_status_display_program to append the currently playing track to
text file, creating a "recently played playlist", see
[cmus_recently_played.sh](cmus_recently_played.sh)

### Playlist browser

I created a playlist browser by navigating to the folder containing these
recently added and recently played text files using the cmus file browser
(press 5)

### Wishlist for cmus

- File watcher
- Easier to use recently added/recently played
- GUI frontend

# My old dev environments

### High school

- Magic C++
- DevC++
- Code::Blocks
- Visual Studio Express/WTL

### College

- CodeLite (C++)
- Notepad++
- Manually pasting javascript snippets into the jsonlint web form
- Still bad at command line stuff

### Post-college

- Learning the ropes of command line at University of Missouri
- Vim on MacBook pro, spending a lot of time in SSH to web servers
- coc.nvim, very helpful
- until 2025, used lsp-zero and neovim, also very helpful

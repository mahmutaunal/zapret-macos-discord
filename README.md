# Zapret macOS Discord

One-command Zapret setup for Discord on macOS Apple Silicon.

This project provides a simple macOS installer for using Discord with Zapret on Apple Silicon Macs.

## Tested Setup

- macOS
- Apple Silicon (M1 / M2 / M3 / M4)
- Discord Desktop
- Discord Web
- Türk Telekom

## Features

- Clones the official Zapret repository
- Runs the official Zapret installer
- Applies a Discord-focused macOS config
- Installs a Discord host list
- Restarts Zapret automatically
- Enables macOS PF automatically

## Install

Recommended:

git clone https://github.com/mahmutaunal/zapret-macos-discord.git

cd zapret-macos-discord

./install.sh

## Restart Zapret

./restart.sh

## Uninstall

./uninstall.sh

## Tested Config

TPWS_OPT="

--filter-tcp=80 --hostspell=hoSt <HOSTLIST> --new

--filter-tcp=443 --split-pos=2 --oob <HOSTLIST>

"

## Discord Update Loop

Some users may experience an endless Discord update loop.

Example:

- Downloading update 6 of 8...
- Update failed
- Retrying...
- Starts over again

Workaround:

1. Let Discord reach the final update step.
2. Temporarily stop Zapret.
3. Let Discord finish applying the update.
4. If Discord still fails, restart Zapret.
5. Discord should recover automatically.

See:

docs/discord-update-loop.md

## Troubleshooting

See:

docs/troubleshooting.md

## PF Notes

See:

docs/macos-pf-notes.md

## Disclaimer

This project is only a helper/installer around the official Zapret project.

Official Zapret project:

https://github.com/bol-van/zapret

Use at your own risk.

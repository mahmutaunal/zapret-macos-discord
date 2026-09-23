# Zapret macOS Discord

One-command Zapret setup for Discord on macOS Apple Silicon.

This project provides a simple macOS installer for using Discord with Zapret on Apple Silicon Macs.

> [!WARNING]
> This project modifies macOS PF/network behavior.
> Use at your own risk.

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
- Optional native menu bar controller (macOS 13+)

## Menu Bar App

`Zapret Menu` is a small, Dock-free macOS app that controls the existing
installation without changing Zapret's files or installing another background
service.

- Start, stop, and restart Zapret from the menu bar
- See whether the `tpws` process is running
- Optionally open only the menu bar app at login
- Stop Zapret and quit, or quit the menu bar app without stopping Zapret
- Uses the standard macOS administrator prompt for service actions

The login option never starts Zapret automatically. The user starts the service
manually after login.

### Build the app

Requires Xcode and macOS 13 or later:

```sh
./scripts/build-app.sh
```

The app is created at `build/Zapret Menu.app`.

### Build the DMG

```sh
./scripts/create-dmg.sh
```

The DMG is created at `build/Zapret-Menu-1.4.0.dmg`. Local builds are ad-hoc
signed. Public releases should use a Developer ID certificate and Apple
notarization.

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

## Known Issues

- Discord Desktop updater may loop on some ISPs
- macOS updates may disable PF
- Upstream Zapret installer changes may break automated installation

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

## Why this exists

Many macOS Apple Silicon users struggle to use Discord reliably with Zapret.

This repository provides a tested setup focused on:
- Apple Silicon Macs
- Discord Desktop
- Discord Web
- Turkish ISPs

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

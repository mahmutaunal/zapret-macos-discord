# Discord Update Loop

Some users may experience an endless update loop on macOS Discord Desktop.

Example:

- Downloading update 6 of 8...
- Update failed
- Retrying...
- Starts over again

This can happen because Discord updater is sensitive to DPI bypass packet manipulation.

## Workaround

1. Let Discord reach the final update step.
2. Temporarily stop Zapret.
3. Let Discord finish applying the update.
4. If Discord still fails, restart Zapret.
5. Discord should recover automatically.

## Stop Zapret

sudo /opt/zapret/init.d/macos/zapret stop
sudo pfctl -d

## Restart Zapret

sudo /opt/zapret/init.d/macos/zapret restart
sudo pfctl -e

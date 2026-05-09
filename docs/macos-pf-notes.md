# macOS PF Notes

Zapret on macOS relies on PF (Packet Filter).

Sometimes macOS may disable PF after reboot or system updates.

## Check PF status

sudo pfctl -s info

## Enable PF

sudo pfctl -e

## Disable PF

sudo pfctl -d

## Restart Zapret

sudo /opt/zapret/init.d/macos/zapret restart

## Common issue

If Discord suddenly stops working after reboot:

1. Enable PF again
2. Restart Zapret

Example:

sudo pfctl -e
sudo /opt/zapret/init.d/macos/zapret restart

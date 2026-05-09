# Troubleshooting

## GitHub does not open

Try restarting Zapret:

sudo /opt/zapret/init.d/macos/zapret restart
sudo pfctl -e

If the issue continues:

sudo /opt/zapret/init.d/macos/zapret stop
sudo pfctl -d

Then test GitHub again.

---

## Discord Web works but Desktop does not

This is usually related to Discord updater behavior.

See:

docs/discord-update-loop.md

---

## Discord stuck at update loop

See:

docs/discord-update-loop.md

---

## PF is disabled after reboot

Re-enable PF:

sudo pfctl -e

Then restart Zapret:

sudo /opt/zapret/init.d/macos/zapret restart

---

## Restart helper

You can also use:

./restart.sh

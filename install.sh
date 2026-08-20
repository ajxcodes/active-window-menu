echo "Installing active-window-menu"
DEST=~/.local/share/plasma/plasmoids/com.ajxcodes.active-window-menu
rm -rf ~/.local/share/plasma/plasmoids/com.ajxcodes.macappmenu # clean up old version
rm -rf "$DEST"
mkdir -p "$DEST"
cp -r contents metadata.json "$DEST"
systemctl --user restart plasma-plasmashell.service
echo "Installed active-window-menu"

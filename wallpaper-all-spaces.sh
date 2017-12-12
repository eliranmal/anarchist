#!/usr/bin/env bash


function set_wallpaper {

	local IMAGE="$1"

	sqlite3 ~/Library/Application\ Support/Dock/desktoppicture.db "UPDATE data SET value = '$IMAGE'" && killall Dock
}

set_wallpaper $@

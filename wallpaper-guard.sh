#!/usr/bin/env bash


function wallpaper_update_trigger {

	local MY_IMAGE="$1"
	local CORP_IMAGE="$2"

	sqlite3 ~/Library/Application\ Support/Dock/desktoppicture.db "DROP TRIGGER IF EXISTS restore_desktop; CREATE TRIGGER IF NOT EXISTS restore_desktop AFTER UPDATE OF value ON data WHEN NEW.value LIKE '$CORP_IMAGE' BEGIN UPDATE data SET value = '$MY_IMAGE'; END;"

}

wallpaper_update_trigger "$@"

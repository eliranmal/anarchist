#!/usr/bin/env bash


function wallpaper_update_trigger {

	local MY_IMAGE="$1"
	local CORP_IMAGE="$2"
	
	

	sqlite3 ~/Library/Application\ Support/Dock/desktoppicture.db "DROP TRIGGER IF EXISTS restore_desktop; CREATE TRIGGER IF NOT EXISTS restore_desktop AFTER UPDATE OF value ON data FOR EACH ROW WHEN NEW.value LIKE '%$CORP_IMAGE' BEGIN UPDATE data SET value = '$MY_IMAGE'; END;"

	sqlite3 ~/Library/Application\ Support/Dock/desktoppicture.db "DROP TRIGGER IF EXISTS restore_desktop_on_delete; CREATE TRIGGER IF NOT EXISTS restore_desktop_on_delete AFTER DELETE ON data FOR EACH ROW WHEN OLD.value LIKE '%$MY_IMAGE' BEGIN UPDATE data SET value = '$MY_IMAGE'; END;"

	sqlite3 ~/Library/Application\ Support/Dock/desktoppicture.db "DROP TRIGGER IF EXISTS restore_desktop_on_insert; CREATE TRIGGER IF NOT EXISTS restore_desktop_on_insert AFTER INSERT ON data FOR EACH ROW WHEN NEW.value LIKE '%$CORP_IMAGE' BEGIN UPDATE data SET value = '$MY_IMAGE'; END;"
	
	
	
	

}

wallpaper_update_trigger "$@"

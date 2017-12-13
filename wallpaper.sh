#!/usr/bin/env bash


# ./wallpaper.sh set ~/Pictures/null.jpeg
# ./wallpaper.sh set ~/Pictures/seethecosmos.jpg
# ./wallpaper.sh set /Library/Caches/com.apple.desktop.admin.png
# ./wallpaper.sh guard ~/Pictures/null.jpeg /Library/Caches/com.apple.desktop.admin.png
# ./wallpaper.sh reject ~/Pictures/seethecosmos.jpg


function main {
	case "$1" in
		help|-h)
			usage
			;;
		set)
            validate_args 2 "$@"
			set_wallpaper "$2"
			;;
		guard)
            validate_args 2 "$@"
        	guard_wallpaper "$2"
			;;
		*)
			usage
			;;
	esac
}


function usage {
    log "usage:

    wallpaper.sh <help|set|guard> [arguments] [-h]


help
====

shows this usage guide.



set
===

sets a background image across all spaces.

arguments
---------

wallpaper-file
    the path of the background image to be set.



guard
=====

watches a file for changes, and set the background image when change triggers.

arguments
---------

wallpaper-file
    the path of the background image to be set on change.

watched-file
    the path of the file to watch for changes.

 "
}

function set_wallpaper {
	local image="$1"
	sqlite3 ~/Library/Application\ Support/Dock/desktoppicture.db "UPDATE data SET value = '$image'" && killall Dock
}

function guard_wallpaper {
	local corp_image="$1"
	local db_path
	local db_image
	local db_image_new
	db_path=~/Library/Application\ Support/Dock/desktoppicture.db
	db_image="$(sqlite3 ~/Library/Application\ Support/Dock/desktoppicture.db "SELECT value FROM data")"
	log "image to reject: $corp_image, current image: $db_image"

	ensure_fswatch
	log "watching DB in $db_path..."
	fswatch -o "$db_path" | while read num ;
	do
        db_image_new="$(sqlite3 ~/Library/Application\ Support/Dock/desktoppicture.db "SELECT value FROM data")"
		log "DB has changed, new wallpaper: $db_image_new"
        # todo - allow multiple corp_images
#        if [[ $@ =~ '-h' ]]; then
        if [[ $db_image_new == $corp_image ]]; then
            log "shananiganz! the evil corp attempted to set a new image! let's undo that."
            set_wallpaper "$db_image"
        else
            db_image="$db_image_new"
        fi
	done
}

function ensure_fswatch {
	if ! hash fswatch 2>/dev/null; then
		log "fswatch is not installed."
	    if [[ $OSTYPE = "linux-gnu" ]]; then # linux
			log "installing via apt..."
		    apt-get install fswatch
		elif [[ $OSTYPE = "darwin"* ]]; then # mac
			log "installing via brew..."
		    brew install fswatch
        elif [[ $OSTYPE = "msys" ]]; then # windows (mingw/git-bash)
			log "windows is not supported, sorry..."
			exit 1
		fi
	fi
}

function validate_args {
    local min=$1; shift
    if (($# < $min)); then
        usage
        exit 1
    fi
}

function log {
	local msg="$1"
	printf "\n%s\n" "$msg"
}

# this is here just in case we want to avoid calling the sqlite3 command and only refresh Dock on each DB file change..
#function wallpaper_update_trigger {
#	local my_image="$1"
#	local corp_image="$2"
#	sqlite3 ~/Library/Application\ Support/Dock/desktoppicture.db "DROP TRIGGER IF EXISTS restore_desktop; CREATE TRIGGER IF NOT EXISTS restore_desktop AFTER UPDATE OF value ON data FOR EACH ROW WHEN NEW.value LIKE '%$corp_image' BEGIN UPDATE data SET value = '$my_image'; END;"
#	sqlite3 ~/Library/Application\ Support/Dock/desktoppicture.db "DROP TRIGGER IF EXISTS restore_desktop_on_delete; CREATE TRIGGER IF NOT EXISTS restore_desktop_on_delete AFTER DELETE ON data FOR EACH ROW WHEN OLD.value LIKE '%$my_image' BEGIN UPDATE data SET value = '$my_image'; END;"
#	sqlite3 ~/Library/Application\ Support/Dock/desktoppicture.db "DROP TRIGGER IF EXISTS restore_desktop_on_insert; CREATE TRIGGER IF NOT EXISTS restore_desktop_on_insert AFTER INSERT ON data FOR EACH ROW WHEN NEW.value LIKE '%$corp_image' BEGIN UPDATE data SET value = '$my_image'; END;"
#}


main "$@"


#!/usr/bin/env bash


function main {
    echo
    validate_os
	case "$1" in
		help|-h)
			usage
			;;
		set)
            shift
            validate_args 1 "$@"
			set_wallpaper "$@"
			;;
		guard)
            shift
            validate_args 1 "$@"
        	guard_wallpaper "$@"
			;;
		*)
			usage
			;;
	esac
}


function usage {
    log "usage:

    wallpaper.sh <set|guard|help> [arguments] [-h]


help
====

shows this usage guide.



set
===

sets a background image across all spaces.

arguments
---------

image-file
    the path of the background image to be set.



guard
=====

watches the background image database for changes, and reverts to the old image when a forbidden image is set.

arguments
---------

forbidden-image
    the path of an image file that will be rejected if set as background. multiple files are supported as additional arguments.

 "
}

function set_wallpaper {
	local image="$1"
	local db_path=~/Library/Application\ Support/Dock/desktoppicture.db
	log "setting background image to $image..."
	sqlite3 "$db_path" "UPDATE data SET value = '$image'" && killall Dock
}

function guard_wallpaper {
	local forbidden_images="$@"
	local db_image
	local db_image_new
	local db_path=~/Library/Application\ Support/Dock/desktoppicture.db
	db_image="$(sqlite3 "$db_path" "SELECT value FROM data")"
    if [[ $forbidden_images =~ $db_image ]]; then
        log "current background image is in the forbidden images list. set another image as background first."
        exit 1
    fi

	ensure_fswatch
	log "watching background image database in $db_path..."
	fswatch -o "$db_path" | while read num ;
	do
        db_image_new="$(sqlite3 "$db_path" "SELECT value FROM data")"
		log "database has changed, new background image: $db_image_new"
        if [[ $forbidden_images =~ $db_image_new ]]; then
            log "shenanigans! the evil corp attempted to set a new background image! let's revert to the old image."
            set_wallpaper "$db_image"
        else
            db_image="$db_image_new"
        fi
	done
}

function ensure_fswatch {
	if ! hash fswatch 2>/dev/null; then
		log "fswatch is not installed. installing via brew..."
        brew install fswatch
	fi
}

function validate_args {
    local min=$1; shift
    if (($# < $min)); then
        usage
        exit 1
    fi
}

function validate_os {
		if [[ $OSTYPE = "darwin"* ]]; then # mac
		    return 0
	    elif [[ $OSTYPE = "linux-gnu" ]]; then # linux
			log "linux is not supported, sorry..."
	        exit 1
        elif [[ $OSTYPE = "msys" ]]; then # windows (mingw/git-bash)
			log "windows is not supported, sorry..."
			exit 1
		fi
}

function log {
	local msg="$1"
	printf "%s\n\n" "$msg"
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


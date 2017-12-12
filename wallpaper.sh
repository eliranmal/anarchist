#!/usr/bin/env bash


# ./wallpaper.sh set ~/Pictures/null.jpeg
# ./wallpaper.sh set /Library/Caches/com.apple.desktop.admin.png
# ./wallpaper.sh guard ~/Pictures/null.jpeg /Library/Caches/com.apple.desktop.admin.png

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

function guard_wallpaper {
	local image="$1"
	local path="$2"
	ensure_fswatch
	log "watching file $path..."
	fswatch -o "$path" | while read num ;
	do
		log "file $path has changed (event ${num})"
		set_wallpaper "$image"
	done
}

function set_wallpaper {
	local image="$1"
	sqlite3 ~/Library/Application\ Support/Dock/desktoppicture.db "UPDATE data SET value = '$image'" && killall Dock
}

function log {
	local msg="$1"
	printf "\n%s\n\n" "$msg"
}

function main {
	case "$1" in
		help|-h)
			usage
			;;
		set)
            if (($# < 2)); then
                usage
                return 1
            fi
			set_wallpaper "$2"
			;;
		guard)
            if (($# < 3)); then
                usage
                return 1
            fi
        	guard_wallpaper "$2" "$3"
			;;
		*)
			usage
			;;
	esac
}

main "$@"


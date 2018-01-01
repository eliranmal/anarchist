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

watches the background image database for changes, and reverts to your image when a forbidden image is set.

arguments
---------

image-file
    the path of the background image to be set.

 "
}

function set_wallpaper {
	local image="$1"
	local db_path=/Library/Desktop\ Pictures/LPDesktop.jpg
	log "setting background image to $image..."
	cp -f "$image" "$db_path"
	killall Dock
}

function guard_wallpaper {
	local image="$1"
	local db_path=/Library/Desktop\ Pictures/LPDesktop.jpg

	set_wallpaper "$image"

	ensure_fswatch
	log "watching background image database in $db_path..."
	fswatch -o "$db_path" | while read num ;
	do
	    log "identified wallpaper change"
	    guard_wallpaper "$image"
        break
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
	printf "> %s\n\n" "$msg"
}

main "$@"


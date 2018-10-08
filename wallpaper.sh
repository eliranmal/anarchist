#!/usr/bin/env bash


function usage {
	log "usage:

  [env SOURCE=fs|db] wallpaper.sh set|allow|deny|help [arguments] [-h]


environment
-----------

  SOURCE
    the background image file source. pass 'db' to listen for changes in the desktop database, or 'fs' to watch for filesystem changes.
    default value is 'fs'. try 'db' if 'fs' fails, it may work, depending on your IT department's choice of tools.

  IMAGE_NAME
    if SOURCE is set to 'fs', this sets the image name to be looked for in the default desktop pictures directory.
    default value is 'LPDesktop.jpg'. just for no reason at all.


commands
--------

  help
    shows this usage guide.

  set <image-file>
    sets a background image across all spaces. accepts the path of the background image to be set.

  deny <forbidden-image[...]>
    a blacklist approach; watches the background image database for changes, and reverts to the old image when a forbidden image is set.
    accepts the path of an image file that will be rejected if set as background. multiple files are supported as additional arguments.
    only works with the 'db' SOURCE.

  allow <permitted-image[...]>
    a whitelist approach: watches the background image database for changes, and reverts to the old image when an image that is outside the allowed images is set.
    accepts the path of an image file that will be permitted if set as background. multiple files are supported as additional arguments.
    only works with the 'db' SOURCE.

 "
}


function main {
	echo
	validate_os
	ensure_env
	validate_env
	case "$1" in
		help|-h)
			usage
			;;
		set)
			shift
			validate_args 1 "$@"
			set_wallpaper "$@"
			;;
		deny)
			shift
			validate_args 1 "$@"
			guard_wallpaper_blacklist "$@"
			;;
		allow)
			shift
			validate_args 1 "$@"
			guard_wallpaper_whitelist "$@"
			;;
		*)
			usage
			;;
	esac
}


function set_wallpaper {
	set_wallpaper_${SOURCE} "$@"
}

function set_wallpaper_fs {
	local image="$1"
	local image_target=/Library/Desktop\ Pictures/${IMAGE_NAME}
	log "setting background image to $image..."
	cp -f "$image" "$image_target"
	killall Dock
}

function set_wallpaper_db {
	local image="$1"
	local db_path=~/Library/Application\ Support/Dock/desktoppicture.db
	log "setting background image to $image..."
	sqlite3 "$db_path" 'UPDATE data SET value = '"'$image'"
	killall Dock
}

function guard_wallpaper_blacklist {
	if [[ ${SOURCE} != 'db' ]]; then
		usage
		exit 1
	fi
	local forbidden_images="$@"
	local current_image
	local new_image
	local db_path=~/Library/Application\ Support/Dock/desktoppicture.db
	current_image="$(sqlite3 "$db_path" 'SELECT * FROM data ORDER BY value DESC LIMIT 1')"
	if [[ $forbidden_images =~ $current_image ]]; then
		log "current background image is in the forbidden images list. set another image as background first."
		exit 1
	fi

	ensure_fswatch
	log "watching background image database in $db_path..."
	fswatch -o "$db_path" | while read num ;
	do
		new_image="$(sqlite3 "$db_path" 'SELECT * FROM data ORDER BY value DESC LIMIT 1')"
		log "database has changed, new background image: $new_image"
		# for a fuzzy lookup, we could do [[ $new_image =~ $forbidden_images ]]. just saying.
		if [[ $forbidden_images =~ $new_image ]]; then
			log "shenanigans! the evil corp attempted to set a new background image! let's revert to the old image."
			set_wallpaper "$current_image"
		else
			current_image="$new_image"
		fi
	done
}

function guard_wallpaper_whitelist {
	if [[ ${SOURCE} != 'db' ]]; then
		usage
		exit 1
	fi
	log "not implemented yet..."
}

function ensure_fswatch {
	if ! hash fswatch 2>/dev/null; then
		log "fswatch is not installed. installing via brew..."
		brew install fswatch
	fi
}

function ensure_env {
	SOURCE="${SOURCE:-fs}"
	IMAGE_NAME="${IMAGE_NAME:-LPDesktop.jpg}"
}

function validate_env {
	if ! [[ "$SOURCE" =~ db|fs ]]; then
		usage
		exit 1
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


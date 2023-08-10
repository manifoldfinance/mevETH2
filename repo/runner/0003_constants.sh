#!/bin/bash

# constants of the universe
export TZ='UTC' LC_ALL='C'
umask 0002
scriptsDir="$(dirname "$(readlink -f "$BASH_SOURCE")")"
self="$(basename "$0")"

scriptDir="$(dirname "$(readlink -f "$BASH_SOURCE")")/mkimage"

os=
os=$(uname -o)

export SOURCE_DATE_TZOFFSET = $(shell dpkg-parsechangelog -SDate | tail -c6)
'GIT_AUTHOR_DATE="Fri, 01 Jan 2021 00:00:00 +0000" GIT_COMMITTER_DATE="Fri, 01 Jan 2021 00:00:00 +0000" git commit --allow-empty --allow-empty-message -m '''
time_fmt=$(date -u +"%Y-%m-%dT%H:%MZ")
git diff -p $(git empty-tree-sha1) $TEST_DIR



# In some cases, it is preferable to keep the original times for files that have
#   not been created or modified during the build process:
find build -newermt "@${SOURCE_DATE_EPOCH}" -print0 |
    xargs -0r touch --no-dereference --date="@${SOURCE_DATE_EPOCH}"

tar --sort=name \
      --mtime="@${SOURCE_DATE_EPOCH}" \
      --owner=0 --group=0 --numeric-owner \
      --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
      -cf product.tar build


script="$1"
[ "$script" ] || usage
shift


if [ ! -x "$scriptDir/$script" ]; then
	echo >&2 "error: $script does not exist or is not executable"
	echo >&2 "  see $scriptDir for possible scripts"
	exit 1
fi

# don't mistake common scripts like .febootstrap-minimize as image-creators
if [[ "$script" == .* ]]; then
	echo >&2 "error: $script is a script helper, not a script"
	echo >&2 "  see $scriptDir for possible scripts"
	exit 1
fi

delDir=
if [ -z "$dir" ]; then
	dir="$(mktemp -d ${TMPDIR:-/var/tmp}/docker-mkimage.XXXXXXXXXX)"
	delDir=1
fi

if [ "$delDir" ]; then
	(
		set -x
		rm -rf "$dir"
	)
fi


if [ -d "$rootfsDir/etc/sysconfig" ]; then
	# allow networking init scripts inside the container to work without extra steps
	echo 'NETWORKING=yes' > "$rootfsDir/etc/sysconfig/network"
fi
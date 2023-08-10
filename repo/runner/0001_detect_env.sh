target_dir="$(pwd)"
if [ -n "$2" ]; then
    if [ -d "$2" ]; then
        target_dir="${2%/}"
    else
        echo "Directory '$2' does not exist" >&2
        echo >&2
        usage
        exit 1
    fi
fi

case "$OSTYPE" in
    linux-*)
        os=linux
        ext=tar.gz
    ;;
    darwin*)
        os=darwin
        ext=tar.gz
    ;;
    freebsd*)
        os=freebsd
        ext=tar.gz
    ;;
    msys|cygwin|win32)
        os=windows
        ext=zip
    ;;
    *)
        echo "OS '${OSTYPE}' is not supported. Note: If you're using Windows, please ensure bash is used to run this script" >&2
        exit 1
    ;;
esac


machine="$(uname -m)"
case "$machine" in
    x86_64) arch=amd64 ;;
    i?86) arch=386 ;;
    aarch64|arm64) arch=arm64 ;;
    arm*) arch=armv6 ;;
    *)
        echo "Could not determine arch from machine hardware name '${machine}'" >&2
        exit 1
    ;;
esac

echo "Detected OS=${os} ext=${ext} arch=${arch}"

curl -L "${url}" | tar xvz -C "$target_dir" actionlint
exe="$target_dir/actionlint"

echo "Downloaded and unarchived executable: ${exe}"

echo "Done: $("${exe}" -version)"


if [ -n "$GITHUB_ACTION" ]; then
    # On GitHub Actions, set executable path to output
    if [ -n "${GITHUB_OUTPUT}" ]; then
        echo "executable=${exe}" >> "$GITHUB_OUTPUT"
    else
        # GitHub Enterprise instance may not introduce the new set-output command yet (see #240)
        echo "::set-output name=executable::${exe}"
    fi
fi
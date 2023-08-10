#!/bin/bash

if [[ $# -ne 2 ]] ; then 
    echo "The $0 utility requires two input arguments:"
    echo "- Arch for compilers to download. See https://github.com/ethereum/solc-bin for available archs."
    echo "- Target directory to store the downloaded compilers."
    echo ""
    echo "Note that to use custom compiler cache path, the env variable SOLC_COMPILER_CACHE should be set."
    echo ""
    echo "Example:"
    echo ""
    echo "export SOLC_COMPILER_CACHE=.github/compiler_cache"
    echo ""

    exit 1;
fi

ARCH="${1}"
CACHE_DIR="${2}"
TARGET_DIR="$CACHE_DIR/$ARCH"

echo "Pre-downloading compilers to $TARGET_DIR"

mkdir -p $TARGET_DIR

curl -s https://binaries.soliditylang.org/$ARCH/list.json --output $TARGET_DIR/list.json

FILES=( $(cat $TARGET_DIR/list.json | jq -r '.releases[]') )

for i in "${FILES[@]}"
do
    echo Downloading "https://binaries.soliditylang.org/$ARCH/$i"
    curl -s https://binaries.soliditylang.org/$ARCH/$i --output $TARGET_DIR/$i && chmod a+x $TARGET_DIR/$i
done
#!/usr/bin/env sh

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <image.ppm> [more.ppm ...]"
    exit 1
fi

for input in "$@"; do
    output="${input%.*}.png"
    magick "$input" "$output"
done

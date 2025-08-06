#!/usr/bin/env bash
mkdir -p out/
cp -r site/* out/
find site -iname '*.html' -not -name _.html -type f -exec bash -c 'cat site/_.html {} > out/$(basename {})' \;
echo "Built new version"

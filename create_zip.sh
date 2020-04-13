#!/usr/bin/env sh
VERSION=5
mkdir -p zips

if [ -f zips/sony-dualsim-patcher-v${VERSION}.zip ]
then
    rm zips/sony-dualsim-patcher-v${VERSION}.zip
fi

zip -r zips/sony-dualsim-patcher-v${VERSION}.zip META-INF tmp

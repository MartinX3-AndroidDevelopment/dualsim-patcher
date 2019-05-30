#!/usr/bin/env sh
VERSION=3
mkdir -p zips
rm zips/sony-dualsim-patcher-v$VERSION.zip
zip zips/sony-dualsim-patcher-v$VERSION.zip tmp/* META-INF/com/google/android/update-binary META-INF/com/google/android/updater-script

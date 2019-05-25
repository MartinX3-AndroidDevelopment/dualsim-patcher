#!/usr/bin/env sh
mkdir -p zips
rm zips/sony-dualsim-patcher.zip
zip zips/sony-dualsim-patcher.zip tmp/* META-INF/com/google/android/update-binary META-INF/com/google/android/updater-script

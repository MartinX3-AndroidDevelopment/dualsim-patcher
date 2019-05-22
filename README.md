# Dual-SIM patcher for Sony phones

`META-INF/com/google/android/updater-script` mounts `/system` and, if needed,
`/vendor`, then runs `tmp/patch_dualsim.sh`.

## Tasks

- Read model from `LTALabel` partition
- Set `ro.telephony.default_network` based on model detected from `LTALabel`
- Set `persist.vendor.radio.multisim.config=dsds`
- Change `ro.product.vendor.model` to `<Devicename> Dual (AOSP)`
- Change all references of the single-SIM model name to the dual-SIM one
- Patch `/vendor/etc/vintf/manifest.xml` to add a second instance of
  telephony-related HALs

## How-to
Simple create a `.zip` file with the `META-INF` and `tmp` folders included, then
flash via TWRP.

For reference, a copy of the kagura dual-SIM `manifest.xml` is included in
[vintf/ds_manifest.xml](vintf/ds_manifest.xml).

## License
MIT license.

Credits to @gouster4 for the inital version of the DS patcher and to @oshmoun
for writing the regex.

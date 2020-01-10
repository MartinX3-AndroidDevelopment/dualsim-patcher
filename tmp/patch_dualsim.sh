#!/sbin/sh

vendor_path=/vendor
device_variant=
default_network=

# If we have system-as-root the system is mounted at /system/system in twrp
function check_vendor_on_system() {
    echo "Checking whether /vendor is on /system (Pre-Treble)"
    # On Android 10, system-as-root means system.img will contain ./system and
    # ./vendor.
    # /vendor will never be in /system/system/vendor
    if [ -f /system/vendor/etc/vintf/manifest.xml ]
    then
        vendor_path=/system/vendor
    fi
}

function check_oem_as_vendor() {
    echo "Checking whether /oem is used as /vendor (Fake Treble)"
    if [ -f /oem/etc/vintf/manifest.xml ]
    then
        vendor_path=/oem
    fi
}

# Sanity check - was this patch already flashed?
function check_already_patched() {
    echo "Checking if already patched"
    if [ ! -z "$(cat ${vendor_path}/etc/vintf/manifest.xml | grep slot2)" ]
    then
        echo "Already patched"
        exit 0
    fi
}

# Detect the exact model from the LTALabel partition
# This looks something like:
# 1284-8432_5-elabel-f8332-row.html
# Output will be e.g. f8332
# (Not 100% sure about the lowercase f8332 though,
#  so use tr to convert to all-lowercase to make sure)
function get_lta_label() {
    echo "Mounting LTALabel partition"
    mkdir /lta-label
    mount -t ext4 /dev/block/bootdevice/by-name/LTALabel /lta-label
    device_variant=$(\
        ls /lta-label/*.html | \
        sed 's/.*-elabel-//' | \
        sed 's/-.*.html//' | \
        tr -d '\n\r' | \
        tr '[:upper:]' '[:lower:]' \
    );
    umount /lta-label
    rm /lta-label
    echo "Device variant is ${device_variant}"
}

function get_default_network_from_device_variant() {
    case ${device_variant} in
        # voyager, pioneer, discovery, kirin(2x), mermaid(2x)
        h4413|h4113|h4213|i4113|i4193|i4213|i4293)
            default_network="9,0"
            ;;
        # suzu, kagura, dora, keyaki, maple, poplar
        f5122|f8332|f8132|g8232|g8142|g8342)
            default_network="9,1"
            ;;
        # apollo, akatsuki(2x), akari(2x)
        h8324|h9436|h9493|h8266|h8296)
            default_network="9,9"
            ;;
        # griffin, bahamut
        j9110|j9210)
            default_network="9,9"
            block_allow_data=0
            ;;
    esac
    echo "Setting default_network to $default_network"
}

function set_build_prop_dual_sim_values() {
    rm -f /tmp/build.prop
    echo "persist.vendor.radio.multisim.config=dsds" >> /tmp/build.prop
    echo "ro.telephony.default_network=$default_network" >> /tmp/build.prop
    if [ ! -z $block_allow_data ]
    # kumano devices
    then
        echo "persist.vendor.radio.block_allow_data=$block_allow_data" >> /tmp/build.prop
    fi

    model=$(\
        cat ${vendor_path}/build.prop | \
        grep "ro.product.vendor.model" | \
        head -n 1 \
    )
    model=$(echo ${model} | sed 's/(AOSP)/Dual (AOSP)/')
    echo "$model" >> /tmp/build.prop

    echo "Substituting props in $vendor_path/build.prop"

    # Prevent prop names with spaces in them being split into multiple fields
    IFS=$'\n'
    for prop in `cat /tmp/build.prop`
    do
        propname=$(echo "$prop" | cut -d '=' -f 1)

        sed -i "/$propname/d" ${vendor_path}/build.prop
        echo "$prop" >> ${vendor_path}/build.prop
    done
}

function set_build_prop_device_model_values() {
    sed -i "s/$1/$2/g" ${vendor_path}/build.prop
}

# VINTF manifest patching
# Add a second instance of every needed HAL
function patch_vintf_manifest() {
    echo "Patching VINTF manifest"
    sed -i -r 's/( +<(fqname|instance)>[^<>]*(slot)[^<>]*)1(<\/[^<>]+>)/\11\4\n\12\4/i' ${vendor_path}/etc/vintf/manifest.xml
    sed -i -r 's/( +<(fqname|instance)>[^<>]*(hook|radio|ril|uim)[^<>]*)0(<\/[^<>]+>)/\10\4\n\11\4/i' ${vendor_path}/etc/vintf/manifest.xml
}

check_vendor_on_system;
check_oem_as_vendor;
check_already_patched;
get_lta_label;
get_default_network_from_device_variant;
set_build_prop_dual_sim_values;

# griffin
set_build_prop_device_model_values j8110 j9110;
set_build_prop_device_model_values J8110 J9110;
# bahamut
set_build_prop_device_model_values j8210 j9210;
set_build_prop_device_model_values J8210 J9210;

# kirin
set_build_prop_device_model_values i3113 i4113;
set_build_prop_device_model_values I3113 I4113;
# mermaid
set_build_prop_device_model_values i3213 i4213;
set_build_prop_device_model_values I3213 I4213;

# akari
set_build_prop_device_model_values h8216 h8266;
set_build_prop_device_model_values H8216 H8266;
# apollo
set_build_prop_device_model_values h8314 h8324;
set_build_prop_device_model_values H8314 H8324;
# akatsuki
set_build_prop_device_model_values h8416 h9436;
set_build_prop_device_model_values H8416 H9436;

# pioneer
set_build_prop_device_model_values h3113 h4113;
set_build_prop_device_model_values H3113 H4113;
# discovery
set_build_prop_device_model_values h3213 h4213;
set_build_prop_device_model_values H3213 H4213;
# voyager
set_build_prop_device_model_values h3413 h4413;
set_build_prop_device_model_values H3413 H4413;

# maple
set_build_prop_device_model_values g8131 g8142;
set_build_prop_device_model_values G8131 G8142;
# poplar
set_build_prop_device_model_values g8341 g8342;
set_build_prop_device_model_values G8341 G8342;

# dora
set_build_prop_device_model_values f8131 f8132;
set_build_prop_device_model_values F8131 F8132;
# kagura
set_build_prop_device_model_values f8331 f8332;
set_build_prop_device_model_values F8331 F8332;
# keyaki
set_build_prop_device_model_values g8231 g8232;
set_build_prop_device_model_values G8231 G8232;

# suzu
set_build_prop_device_model_values f5121 f5122;
set_build_prop_device_model_values F5121 F5122;

patch_vintf_manifest;

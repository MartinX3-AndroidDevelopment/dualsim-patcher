#!/sbin/sh

# Get file descriptor for output
OUTFD=$(ps | grep -v "grep" | grep -o -E "update-binary(.*)" | cut -d " " -f 3);
# Try looking for a differently named updater binary
if [ -z $OUTFD ]; then
  OUTFD=$(ps | grep -v "grep" | grep -o -E "updater(.*)" | cut -d " " -f 3);
fi

# same as ui_print command in updater_script, for example:
#
# ui_print "hello world!"
#
# will output "hello world!" to recovery, while
#
# ui_print
#
# outputs an empty line
ui_print() {
  if [ $OUTFD != "" ]; then
    echo "ui_print ${1} " 1>&$OUTFD;
    echo "ui_print " 1>&$OUTFD;
  else
    echo "${1}";
  fi;
}

system_mount=/mnt/system
vendor_path=/vendor
device_variant=
device_supported=false
default_network=
block_allow_data=

# If we have system-as-root the system is mounted at /system/system in twrp
check_vendor_on_system() {
    ui_print "Checking whether /vendor is on /system (Pre-Treble)"
    if [ -f ${system_mount}/vendor/etc/vintf/manifest.xml ]
    then
        vendor_path=${system_mount}/vendor
    elif [ -f ${system_mount}/system/vendor/etc/vintf/manifest.xml ]
    then
        vendor_path=${system_mount}/system/vendor
    fi
}

check_oem_as_vendor() {
    ui_print "Checking whether /oem is used as /vendor (Fake Treble)"
    if [ -f /oem/etc/vintf/manifest.xml ]
    then
        vendor_path=/oem
    fi
}

# Sanity check - was this patch already flashed?
check_already_patched() {
    ui_print "Checking if already patched"
    if [ ! -z "$(cat ${vendor_path}/etc/vintf/manifest.xml | grep slot2)" ]
    then
        ui_print "Already patched"
        exit 0
    else
        ui_print "Not yet patched"
    fi
}

# Detect the exact model from the LTALabel partition
# This looks something like:
# 1284-8432_5-elabel-f8332-row.html
# Output will be e.g. f8332
# (Not 100% sure about the lowercase f8332 though,
#  so use tr to convert to all-lowercase to make sure)
get_lta_label() {
    ui_print "Mounting LTALabel partition"
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
    rm -r /lta-label
    ui_print "Device variant is ${device_variant}"
}

assign_props() {
    case ${device_variant} in
        # voyager, pioneer, discovery, kirin(2x), mermaid(2x)
        h4413|h4113|h4213|i4113|i4193|i4213|i4293)
            default_network="9,0"
            device_supported=true
            ;;
        # suzu, kagura, dora, keyaki, maple, poplar
        f5122|f8332|f8132|g8232|g8142|g8342)
            default_network="9,1"
            device_supported=true
            ;;
        # apollo, akatsuki(2x), akari(2x)
        h8324|h9436|h9493|h8266|h8296)
            default_network="9,9"
            device_supported=true
            ;;
        # griffin, bahamut
        j9110|j9210)
            default_network="9,9"
            block_allow_data=0
            device_supported=true
            ;;
    esac
}

set_build_prop_dual_sim_values() {
    rm -f /tmp/build.prop
    ui_print "Setting multisim config to dsds"
    echo "persist.vendor.radio.multisim.config=dsds" >> /tmp/build.prop
    ui_print "Setting default_network to $default_network"
    echo "ro.telephony.default_network=$default_network" >> /tmp/build.prop
    if [ ! -z $block_allow_data ]
    # kumano devices
    then
        ui_print "Setting block_allow_data to $block_allow_data"
        echo "persist.vendor.radio.block_allow_data=$block_allow_data" >> /tmp/build.prop
    fi

    model=$(\
        cat ${vendor_path}/build.prop | \
        grep "ro.product.vendor.model" | \
        head -n 1 \
    )
    model=$(echo ${model} | sed 's/(AOSP)/Dual (AOSP)/')
    echo "$model" >> /tmp/build.prop

    ui_print "Substituting props in $vendor_path/build.prop"

    # Prevent prop names with spaces in them being split into multiple fields
    IFS=$'\n'
    for prop in `cat /tmp/build.prop`
    do
        propname=$(echo "$prop" | cut -d '=' -f 1)

        sed -i "/$propname/d" ${vendor_path}/build.prop
        echo "$prop" >> ${vendor_path}/build.prop
    done
}

substitute_in_build_prop() {
    sed -i "s/$1/$2/g" ${vendor_path}/build.prop
}

# VINTF manifest patching
# Add a second instance of every needed HAL
patch_vintf_manifest() {
    ui_print "Patching VINTF manifest"
    sed -i -r 's/( +<(fqname|instance)>[^<>]*(slot)[^<>]*)1(<\/[^<>]+>)/\11\4\n\12\4/i' ${vendor_path}/etc/vintf/manifest.xml
    sed -i -r 's/( +<(fqname|instance)>[^<>]*(hook|radio|ril|uim)[^<>]*)0(<\/[^<>]+>)/\10\4\n\11\4/i' ${vendor_path}/etc/vintf/manifest.xml
}

ui_print ""

check_vendor_on_system;
check_oem_as_vendor;
ui_print "/vendor located at $vendor_path"

get_lta_label;
check_already_patched;
assign_props;

if [ $device_supported = false ]
then
    ui_print ""
    ui_print "############################################"
    ui_print "FAIL: Device $device_variant not supported"
    ui_print "Are you trying to flash a single-sim device?"
    ui_print "############################################"
    ui_print ""
    exit 1
fi

set_build_prop_dual_sim_values;


# griffin
substitute_in_build_prop j8110 j9110;
substitute_in_build_prop J8110 J9110;
# bahamut
substitute_in_build_prop j8210 j9210;
substitute_in_build_prop J8210 J9210;

# kirin
substitute_in_build_prop i3113 i4113;
substitute_in_build_prop I3113 I4113;
# mermaid
substitute_in_build_prop i3213 i4213;
substitute_in_build_prop I3213 I4213;

# akari
substitute_in_build_prop h8216 h8266;
substitute_in_build_prop H8216 H8266;
# apollo
substitute_in_build_prop h8314 h8324;
substitute_in_build_prop H8314 H8324;
# akatsuki
substitute_in_build_prop h8416 h9436;
substitute_in_build_prop H8416 H9436;

# pioneer
substitute_in_build_prop h3113 h4113;
substitute_in_build_prop H3113 H4113;
# discovery
substitute_in_build_prop h3213 h4213;
substitute_in_build_prop H3213 H4213;
# voyager
substitute_in_build_prop h3413 h4413;
substitute_in_build_prop H3413 H4413;

# maple
substitute_in_build_prop g8131 g8142;
substitute_in_build_prop G8131 G8142;
# poplar
substitute_in_build_prop g8341 g8342;
substitute_in_build_prop G8341 G8342;

# dora
substitute_in_build_prop f8131 f8132;
substitute_in_build_prop F8131 F8132;
# kagura
substitute_in_build_prop f8331 f8332;
substitute_in_build_prop F8331 F8332;
# keyaki
substitute_in_build_prop g8231 g8232;
substitute_in_build_prop G8231 G8232;

# suzu
substitute_in_build_prop f5121 f5122;
substitute_in_build_prop F5121 F5122;

patch_vintf_manifest;

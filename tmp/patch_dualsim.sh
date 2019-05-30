#!/sbin/sh

# If we have system-as-root the system is mounted at /system/system in twrp
system_path=/system
if [ -d ${system_path}/system ]
then
    system_path=${system_path}/system
fi

# Sanity check - was this patch already flashed?
if $vendor_on_system
then
    if $(cat /system/vendor/etc/vintf/manifest.xml | grep slot2)
    then
        echo "Already patched"
        exit 0
    fi
else
    if $(cat /vendor/etc/vintf/manifest.xml | grep slot2)
    then
        echo "Already patched"
        exit 0
    fi
fi

echo "Mounting LTALabel partition"

mkdir /lta-label
mount -t ext4 /dev/block/bootdevice/by-name/LTALabel /lta-label
# Detect the exact model from the LTALabel partition
# This looks something like:
# 1284-8432_5-elabel-D5303-row.html
# Output will be e.g. F8332
variant_lower=$(\
    ls /lta-label/*.html | \
    sed 's/.*-elabel-//' | \
    sed 's/-.*.html//' | \
    tr -d '\n\r' \
);
variant_upper=$(\
    echo ${variant_lower} | \
    tr '[a-z]' '[A-Z]' \
);
umount /lta-label

echo "Model variant is ${variant_upper}"

case ${variant_lower} in
    # voyager, pioneer, discovery, kirin, mermaid
    h4413|h4113|h4213|i4113|i4213)
        default_network="9,0"
        echo "Setting default_network to 9,0"
        ;;
    # suzu, kagura, dora, keyaki, maple, poplar
    f5122|f8332|f8132|g8232|g8142|g8342)
        default_network="9,1"
        echo "Setting default_network to 9,1"
        ;;
    # apollo, akatsuki(2x), akari(2x)
    h8324|h9436|h9493|h8266|h8296)
        default_network="9,9"
        echo "Setting default_network to 9,9"
        ;;
esac

rm -f /tmp/build.prop
echo "persist.vendor.radio.multisim.config=dsds" >> /tmp/build.prop
echo "ro.telephony.default_network=${default_network}" >> /tmp/build.prop

model=$(\
    cat ${system_path}/build.prop ${system_path}/vendor/build.prop /vendor/build.prop | \
    grep "ro.product.vendor.model" | \
    head -n 1 \
)
model=$(echo ${model} | sed 's/(AOSP)/Dual (AOSP)/')
echo "$model" >> /tmp/build.prop

echo "Substituting props in ${system_path}/build.prop"
echo "Substituting props in ${system_path}/vendor/build.prop"

_ifs_backup="$IFS"
# Prevent prop names with spaces in them being split into multiple fields
IFS=$'\n'
for prop in `cat /tmp/build.prop`
do
    propname=$(echo "$prop" | cut -d '=' -f 1)

    sed -i "/$propname/d" ${system_path}/build.prop
    echo "$prop" >> ${system_path}/build.prop
    sed -i "/$propname/d" ${system_path}/vendor/build.prop
    echo "$prop" >> ${system_path}/vendor/build.prop
done
IFS="$_ifs_backup"

# kirin
sed -i "s/i3113/i4113/g" ${system_path}/build.prop
sed -i "s/I3113/I4113/g" ${system_path}/build.prop
sed -i "s/i3113/i4113/g" ${system_path}/vendor/build.prop
sed -i "s/I3113/I4113/g" ${system_path}/vendor/build.prop
# mermaid
sed -i "s/i3213/i4213/g" ${system_path}/build.prop
sed -i "s/I3213/I4213/g" ${system_path}/build.prop
sed -i "s/i3213/i4213/g" ${system_path}/vendor/build.prop
sed -i "s/I3213/I4213/g" ${system_path}/vendor/build.prop

# akari
sed -i "s/h8216/h8266/g" ${system_path}/build.prop
sed -i "s/H8216/H8266/g" ${system_path}/build.prop
sed -i "s/h8216/h8266/g" ${system_path}/vendor/build.prop
sed -i "s/H8216/H8266/g" ${system_path}/vendor/build.prop
# apollo
sed -i "s/h8314/h8324/g" ${system_path}/build.prop
sed -i "s/H8314/H8324/g" ${system_path}/build.prop
sed -i "s/h8314/h8324/g" ${system_path}/vendor/build.prop
sed -i "s/h8314/h8324/g" ${system_path}/vendor/build.prop
# akatsuki
sed -i "s/h8416/h9436/g" ${system_path}/build.prop
sed -i "s/H8416/H9436/g" ${system_path}/build.prop
sed -i "s/h8416/h9436/g" ${system_path}/vendor/build.prop
sed -i "s/h8416/h9436/g" ${system_path}/vendor/build.prop

# pioneer
sed -i "s/h3113/h4113/g" ${system_path}/build.prop
sed -i "s/H3113/H4113/g" ${system_path}/build.prop
sed -i "s/h3113/h4113/g" ${system_path}/vendor/build.prop
sed -i "s/H3113/H4113/g" ${system_path}/vendor/build.prop
# discovery
sed -i "s/h3213/h4213/g" ${system_path}/build.prop
sed -i "s/H3213/H4213/g" ${system_path}/build.prop
sed -i "s/h3213/h4213/g" ${system_path}/vendor/build.prop
sed -i "s/H3213/H4213/g" ${system_path}/vendor/build.prop
# voyager
sed -i "s/h3413/h4413/g" ${system_path}/build.prop
sed -i "s/H3413/H4413/g" ${system_path}/build.prop
sed -i "s/h3413/h4413/g" ${system_path}/vendor/build.prop
sed -i "s/H3413/H4413/g" ${system_path}/vendor/build.prop

# maple
sed -i "s/g8131/g8142/g" ${system_path}/build.prop
sed -i "s/G8131/G8142/g" ${system_path}/build.prop
sed -i "s/g8131/g8142/g" ${system_path}/vendor/build.prop
sed -i "s/G8131/G8142/g" ${system_path}/vendor/build.prop
# poplar
sed -i "s/g8341/g8342/g" ${system_path}/build.prop
sed -i "s/G8341/G8342/g" ${system_path}/build.prop
sed -i "s/g8341/g8342/g" ${system_path}/vendor/build.prop
sed -i "s/G8341/G8342/g" ${system_path}/vendor/build.prop

# dora
sed -i "s/f8131/f8132/g" ${system_path}/build.prop
sed -i "s/F8131/F8132/g" ${system_path}/build.prop
sed -i "s/f8131/f8132/g" ${system_path}/vendor/build.prop
sed -i "s/f8131/f8132/g" ${system_path}/vendor/build.prop
# kagura
sed -i "s/f8331/f8332/g" ${system_path}/build.prop
sed -i "s/F8331/F8332/g" ${system_path}/build.prop
sed -i "s/f8331/f8332/g" ${system_path}/vendor/build.prop
sed -i "s/F8331/F8332/g" ${system_path}/vendor/build.prop
# keyaki
sed -i "s/g8231/g8232/g" ${system_path}/build.prop
sed -i "s/G8231/G8232/g" ${system_path}/build.prop
sed -i "s/g8231/g8232/g" ${system_path}/vendor/build.prop
sed -i "s/G8231/G8232/g" ${system_path}/vendor/build.prop

# suzu
sed -i "s/f5121/f5122/g" ${system_path}/build.prop
sed -i "s/F5121/F5122/g" ${system_path}/build.prop
sed -i "s/f5121/f5122/g" ${system_path}/vendor/build.prop
sed -i "s/F5121/F5122/g" ${system_path}/vendor/build.prop

# VINTF manifest patching
# Add a second instance of every needed HAL
echo "Patching VINTF manifest"
sed -i -r 's/( +<(fqname|instance)>[^<>]*(slot)[^<>]*)1(<\/[^<>]+>)/\11\4\n\12\4/i' ${system_path}/vendor/etc/vintf/manifest.xml
sed -i -r 's/( +<(fqname|instance)>[^<>]*(hook|radio|ril|uim)[^<>]*)0(<\/[^<>]+>)/\10\4\n\11\4/i' ${system_path}/vendor/etc/vintf/manifest.xml


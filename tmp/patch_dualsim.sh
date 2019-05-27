#!/sbin/sh

sbp="/system/build.prop"
vbp="/vendor/build.prop"
svbp="/system/vendor/build.prop"

# Check whether the vendor parts lie in /system/vendor
# If /system/vendor points at vendor, we have a real /vendor partition
[[ $(readlink /system/vendor) == "/vendor" ]] && vendor_on_system=false || vendor_on_system=true

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
    echo $variant_lower | \
    tr '[a-z]' '[A-Z]' \
);
umount /lta-label

echo "Model variant is ${variant_upper}"

# Will be overriden later anyway
#sed -i -r "s/(ro.product.board=).+/\1${variant_upper}/" $sbp
#sed -i -r "s/(ro.product.board=).+/\1${variant_upper}/" $vbp
#sed -i -r "s/(ro.product.board=).+/\1${variant_upper}/" $svbp

case $variant_lower in
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
    # apollo, akatsuki(2x), akari
    h8324|h9436|h9493|h8266)
        default_network="9,9"
        echo "Setting default_network to 9,9"
        ;;
esac

rm -f /tmp/build.prop
echo "persist.vendor.radio.multisim.config=dsds" >> /tmp/build.prop
echo "ro.telephony.default_network=${default_network}" >> /tmp/build.prop

model=$(\
    cat /system/build.prop /system/vendor/build.prop /vendor/build.prop | \
    grep "ro.product.vendor.model" | \
    head -n 1 \
)
model=$(echo $model | sed 's/(AOSP)/Dual (AOSP)/')
echo "$model" >> /tmp/build.prop

echo "Substituting props in /system/build.prop"
if $vendor_on_system
then
    echo "Substituting props in /system/vendor/build.prop"
else
    echo "Substituting props in /vendor/build.prop"
fi

_ifs_backup="$IFS"
# Prevent prop names with spaces in them being split into multiple fields
IFS=$'\n'
for prop in `cat /tmp/build.prop`
do
    propname=$(echo "$prop" | cut -d '=' -f 1)

    sed -i "/$propname/d" $sbp
    echo "$prop" >> $sbp
    if $vendor_on_system
    then
        sed -i "/$propname/d" $svbp
        echo "$prop" >> $svbp
    else
        sed -i "/$propname/d" $vbp
        echo "$prop" >> $vbp
    fi
done
IFS="$_ifs_backup"

# kirin
sed -i "s/i3113/i4113/g" /system/build.prop
sed -i "s/I3113/I4113/g" /system/build.prop
sed -i "s/i3113/i4113/g" /vendor/build.prop
sed -i "s/I3113/I4113/g" /vendor/build.prop
# mermaid
sed -i "s/i3213/i4213/g" /system/build.prop
sed -i "s/I3213/I4213/g" /system/build.prop
sed -i "s/i3213/i4213/g" /vendor/build.prop
sed -i "s/I3213/I4213/g" /vendor/build.prop

# akari
sed -i "s/h8216/h8266/g" /system/build.prop
sed -i "s/H8216/H8266/g" /system/build.prop
sed -i "s/h8216/h8266/g" /vendor/build.prop
sed -i "s/H8216/H8266/g" /vendor/build.prop
# apollo
sed -i "s/h8314/h8324/g" /system/build.prop
sed -i "s/H8314/H8324/g" /system/build.prop
sed -i "s/h8314/h8324/g" /vendor/build.prop
sed -i "s/h8314/h8324/g" /vendor/build.prop
# akatsuki
sed -i "s/h8416/h9436/g" /system/build.prop
sed -i "s/H8416/H9436/g" /system/build.prop
sed -i "s/h8416/h9436/g" /vendor/build.prop
sed -i "s/h8416/h9436/g" /vendor/build.prop

# pioneer
sed -i "s/h3113/h4113/g" /system/build.prop
sed -i "s/H3113/H4113/g" /system/build.prop
sed -i "s/h3113/h4113/g" /vendor/build.prop
sed -i "s/H3113/H4113/g" /vendor/build.prop
# discovery
sed -i "s/h3213/h4213/g" /system/build.prop
sed -i "s/H3213/H4213/g" /system/build.prop
sed -i "s/h3213/h4213/g" /vendor/build.prop
sed -i "s/H3213/H4213/g" /vendor/build.prop
# voyager
sed -i "s/h3413/h4413/g" /system/build.prop
sed -i "s/H3413/H4413/g" /system/build.prop
sed -i "s/h3413/h4413/g" /vendor/build.prop
sed -i "s/H3413/H4413/g" /vendor/build.prop

# maple
sed -i "s/g8131/g8142/g" /system/build.prop
sed -i "s/G8131/G8142/g" /system/build.prop
sed -i "s/g8131/g8142/g" /system/vendor/build.prop
sed -i "s/G8131/G8142/g" /system/vendor/build.prop
sed -i "s/g8131/g8142/g" /vendor/build.prop
sed -i "s/G8131/G8142/g" /vendor/build.prop
# poplar
sed -i "s/g8341/g8342/g" /system/build.prop
sed -i "s/G8341/G8342/g" /system/build.prop
sed -i "s/g8341/g8342/g" /vendor/build.prop
sed -i "s/G8341/G8342/g" /vendor/build.prop

# dora
sed -i "s/f8131/f8132/g" /system/build.prop
sed -i "s/F8131/F8132/g" /system/build.prop
sed -i "s/f8131/f8132/g" /system/vendor/build.prop
sed -i "s/f8131/f8132/g" /system/vendor/build.prop
sed -i "s/f8131/f8132/g" /vendor/build.prop
sed -i "s/f8131/f8132/g" /vendor/build.prop
# kagura
sed -i "s/f8331/f8332/g" /system/build.prop
sed -i "s/F8331/F8332/g" /system/build.prop
sed -i "s/f8331/f8332/g" /system/vendor/build.prop
sed -i "s/F8331/F8332/g" /system/vendor/build.prop
sed -i "s/f8331/f8332/g" /vendor/build.prop
sed -i "s/F8331/F8332/g" /vendor/build.prop
# keyaki
sed -i "s/g8231/g8232/g" /system/build.prop
sed -i "s/G8231/G8232/g" /system/build.prop
sed -i "s/g8231/g8232/g" /system/vendor/build.prop
sed -i "s/G8231/G8232/g" /system/vendor/build.prop
sed -i "s/g8231/g8232/g" /vendor/build.prop
sed -i "s/G8231/G8232/g" /vendor/build.prop

# suzu
sed -i "s/f5121/f5122/g" /system/build.prop
sed -i "s/F5121/F5122/g" /system/build.prop
sed -i "s/f5121/f5122/g" /system/vendor/build.prop
sed -i "s/F5121/F5122/g" /system/vendor/build.prop
sed -i "s/f5121/f5122/g" /vendor/build.prop
sed -i "s/F5121/F5122/g" /vendor/build.prop

# VINTF manifest patching
# Add a second instance of every needed HAL
echo "Patching VINTF manifest"
if $vendor_on_system
then
    sed -i -r 's/( +<(fqname|instance)>[^<>]*(slot)[^<>]*)1(<\/[^<>]+>)/\11\4\n\12\4/i' /system/vendor/etc/vintf/manifest.xml
    sed -i -r 's/( +<(fqname|instance)>[^<>]*(hook|radio|ril|uim)[^<>]*)0(<\/[^<>]+>)/\10\4\n\11\4/i' /system/vendor/etc/vintf/manifest.xml
else
    sed -i -r 's/( +<(fqname|instance)>[^<>]*(slot)[^<>]*)1(<\/[^<>]+>)/\11\4\n\12\4/i' /vendor/etc/vintf/manifest.xml
    sed -i -r 's/( +<(fqname|instance)>[^<>]*(hook|radio|ril|uim)[^<>]*)0(<\/[^<>]+>)/\10\4\n\11\4/i' /vendor/etc/vintf/manifest.xml
fi

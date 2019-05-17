#!/sbin/sh

sbp="/system/build.prop"
vbp="/vendor/build.prop"
svbp="/system/vendor/build.prop"

# If system build.prop backup exists, restore it
if [ -f /system/build.prop.bak ];
then
    rm -rf $sbp
    cp $sbp.bak $sbp
else
    cp $sbp $sbp.bak
fi
# If vendor build.prop backup exists, restore it
if [ -f /vendor/build.prop.bak ];
then
    rm -rf $sbp
    cp $vbp.bak $vbp
else
    cp $vbp $vbp.bak
fi
# If system/vendor build.prop backup exists, restore it
if [ -f /system/vendor/build.prop.bak ];
then
    rm -rf $svbp
    cp $svbp.bak $svbp
else
    cp $svbp $svbp.bak
fi

mkdir /lta-label
mount -t ext4 /dev/block/bootdevice/by-name/LTALabel /lta-label
# Detect the exact model from the LTALabel partition
# This looks something like:
# 1284-8432_5-elabel-D5303-row.html
variant=$(\
    ls /lta-label/*.html | \
    sed s/.*-elabel-// | \
    sed s/-.*.html// | \
    tr -d '\n\r' | \
    tr '[a-z]' '[A-Z]' \
);
umount /lta-label
sed -i -r "s/(ro.product.board=).+/\1${variant}/" $sbp
sed -i -r "s/(ro.product.board=).+/\1${variant}/" $vbp
sed -i -r "s/(ro.product.board=).+/\1${variant}/" $svbp

echo " " >> /tmp/build.prop
echo "persist.vendor.radio.multisim.config=dsds" >> /tmp/build.prop
case $variant in
    f8331|f5122|g8232|g8142|f8132|g8342)
        default_network="9,1"
        ;;
    h8324|h9436|h8266)
        default_network="9,9"
        ;;
    h4413|h4113|h4213)
        default_network="9,0"
        ;;
    # TODO: Yoshino, ganges
esac
echo "ro.telephony.default_network=${default_network}" >> /tmp/build.prop

for prop in `cat /tmp/build.prop`;do
  export newprop=$(echo ${prop} | cut -d '=' -f1)

  sed -i "/${newprop}/d" $sbp
  echo $prop >> $sbp
  sed -i "/${newprop}/d" $vbp
  echo $prop >> $vbp
  sed -i "/${newprop}/d" $svbp
  echo $prop >> $svbp
done

# TODO: Match table: f8331->f8332 for all devices
sed -i "s/f8331/f8332/g" /system/build.prop
sed -i "s/F8331/F8332/g" /system/build.prop

sed -i "s/f8331/f8332/g" /system/vendor/build.prop
sed -i "s/F8331/F8332/g" /system/vendor/build.prop

sed -i -r 's/( +<(fqname|instance)>[^<>]*(slot)[^<>]*)1(<\/[^<>]+>)/\11\4\n\12\4/i' /system/vendor/etc/vintf/manifest.xml
sed -i -r 's/( +<(fqname|instance)>[^<>]*(hook|radio|ril|uim)[^<>]*)0(<\/[^<>]+>)/\10\4\n\11\4/i' /system/vendor/etc/vintf/manifest.xml

sed -i -r 's/( +<(fqname|instance)>[^<>]*(slot)[^<>]*)1(<\/[^<>]+>)/\11\4\n\12\4/i' /vendor/etc/vintf/manifest.xml
sed -i -r 's/( +<(fqname|instance)>[^<>]*(hook|radio|ril|uim)[^<>]*)0(<\/[^<>]+>)/\10\4\n\11\4/i' /vendor/etc/vintf/manifest.xml

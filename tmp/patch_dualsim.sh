#!/sbin/sh

sbp="/system/build.prop"
vbp="/system/vendor/build.prop"

# If system build.prop backup exists, restore it
if [ -f /system/build.prop.bak ];
then
    rm -rf $sbp
    cp $sbp.bak $sbp
else
    cp $sbp $sbp.bak
fi
# If vendor build.prop backup exists, restore it
if [ -f /system/vendor/build.prop.bak ];
then
    rm -rf $vbp
    cp $vbp.bak $vbp
else
    cp $vbp $vbp.bak
fi

echo " " >> $bp
cat > /tmp/build.prop <<DELIM
persist.vendor.radio.multisim.config=dsds
ro.telephony.default_network=9,1
DELIM

for prop in `cat /tmp/build.prop`;do
  export newprop=$(echo ${prop} | cut -d '=' -f1)

  sed -i "/${newprop}/d" /system/build.prop
  echo $prop >> /system/build.prop
done

sed -i 's/f8331/f8332/g' /system/build.prop
sed -i 's/F8331/F8332/g' /system/build.prop

sed -i 's/f8331/f8332/g' /system/vendor/build.prop
sed -i 's/F8331/F8332/g' /system/vendor/build.prop

cp /tmp/manifest.xml /system/vendor/etc/vintf/manifest.xml
chcon u:object_r:vendor_configs_file:s0 /system/vendor/etc/vintf/manifest.xml

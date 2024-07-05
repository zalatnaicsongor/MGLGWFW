curl -s -k -L -o /tmp/firmware.gbl https://github.com/Nerivec/silabs-firmware-builder/releases/download/v8.0.0-pre/easyiot_zb-gw04-1v1_ncp-uart-sw_115200_8.0.0.0.gbl
zigbee_isp.sh 0 && usleep 20000 && zigbee_reset.sh 1 && usleep 20000 && zigbee_reset.sh 0 && usleep 20000
echo -e '1' > /dev/ttyS1
sx -X /tmp/firmware.gbl </dev/ttyS1 >/dev/ttyS1

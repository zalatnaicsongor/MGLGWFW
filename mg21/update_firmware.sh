curl -s -k -L -o /tmp/firmware.gbl https://raw.githubusercontent.com/zalatnaicsongor/MGLGWFW/main/mg21/ncp-uart-hw-8000-noflowcontrol-115200.gbl
zigbee_isp.sh 0 && usleep 20000 && zigbee_reset.sh 1 && usleep 20000 && zigbee_reset.sh 0 && usleep 20000
echo -e '1' > /dev/ttyS1
sx -X /tmp/firmware.gbl </dev/ttyS1 >/dev/ttyS1

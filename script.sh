#!/bin/sh

BOOTSTRAP_BASE_URL="http://192.168.1.195:1180/"
BASE_URL="http://192.168.1.195:1180/"
ZIGBEE_SERIAL_PORT=""

run_script() {
    kill_process_by_name "openmiio_agent"
    (/data/openmiio_agent zigbee) &

    kill_process_by_name "Lumi_Z3GatewayHost_MQTT"
    spawn_placeholder "Lumi_Z3GatewayHost_MQTT"

    kill_process_by_name "zigbee_agent"
    spawn_placeholder "zigbee_agent"

    kill_process_by_name "zigbee_gw"
    spawn_placeholder "zigbee_gw"

    ZIGBEE_SERIAL_PORT="/dev/ttyS2"

    upload_firmware
    echo "now you can start ser2net with 'ser2net -d -C '7000:raw:0:/dev/ttyS2:115200 8DATABITS NONE 1STOPBIT''"
}

upload_firmware() {
    get_bootstrap_bins
    get_rcp_firmware
    echo "uploading firmware to efr32"
    start_rcp_upload
    echo "uploaded firmware, rebooting efr32"
    sleep 1
    zigbee_inter_bootloader.sh 1 && usleep 10000 && zigbee_reset.sh 0 && usleep 10000 && zigbee_reset.sh 1
    sleep 1
    echo "rebooted efr32"
}

get_bootstrap_bins() {
    /bin/wget -O /data/curl 'http://master.dl.sourceforge.net/project/mgl03/bin/curl?viasf=1'
    /bin/wget -O /data/sz "$BASE_URL/mips/sz"
    /bin/wget -O /data/ser2net "$BASE_URL/mips/ser2net"

    chmod +x /data/curl
    chmod +x /data/sz
    chmod +x /data/ser2net
}

get_rcp_firmware() {
    /data/curl -o /tmp/rcp.gbl "$BASE_URL/mg1b/rcpmg1b.gbl"
}

start_rcp_upload() {
    zigbee_inter_bootloader.sh 0 && usleep 10000 && zigbee_reset.sh 0 && usleep 10000 && zigbee_reset.sh 1
    sleep 1
    echo -e '1' > $ZIGBEE_SERIAL_PORT
    sleep 1
    /data/sz -X /tmp/rcp.gbl < $ZIGBEE_SERIAL_PORT > $ZIGBEE_SERIAL_PORT
}

kill_process_by_name() {
    NAME="$1"

    if [ -z "$NAME" ]; then
        echo "no name provided - kill_process_by_name"
        return 1
    fi

    PROCESSES=$(ps ww)

    PID=$(echo "$PROCESSES" | grep "$NAME" | head -n1 | awk '{print $1}')

    if [ -z "$PID" ]; then
        echo "no PID found for process name $NAME  - kill_process_by_name"
        return 1
    fi

    echo "killing $PID"
    kill "$PID"

    return 0
}

spawn_placeholder() {
    NAME="$1"

    if [ -z "$NAME" ]; then
        echo "no name provided - spawn_placeholder"
        return 1
    fi

    (tail "$NAME" -f /dev/null) &

    return 0
}

run_script
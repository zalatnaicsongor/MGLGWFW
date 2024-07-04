#!/bin/sh
#/data/scripts/post_init.sh

export PATH=$PATH:/data/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/data/lib

# Enable tty
/bin/riu_w 101e 53 3012

mount --bind /bin/echo /bin/mZ3GatewayHost_MQTT > /dev/null 2>&1
stty -F /dev/ttyS1 115200 > /dev/null 2>&1
/data/bin/ser2net -C '7000:raw:0:/dev/ttyS1:115200 8DATABITS NONE 1STOPBIT'

# Stock post init
fw_manager.sh -r

# Enable tty and start telnet
/bin/riu_w 101e 53 3012
telnetd

CHECK_FILES="/data/bin/dropbear /data/bin/htop /data/bin/socat /data/bin/ser2net /data/bin/zigbee_flash.sh"
for FILE in $CHECK_FILES; do
    if [ ! -f $FILE ]; then
        sleep 20
        /data/bin/mod_update.sh -y >> /tmp/log.log 2>&1
        break
    fi
done

CLOUD=$(agetprop persist.sys.cloud)

# Replace /etc/profile (for PATH and LD_LIBRARY_PATH)
if [ -f /data/profile ]; then
    mount --bind /data/profile /etc/profile > /dev/null 2>&1
fi

if [ -f /data/enable_mosquitto ]; then
    /data/bin/sed 's/\x31\x32\x37\x2e\x30\x2e\x30\x2e\x31\x0\x0\x0\x6c\x6f/\x30\x30\x30\x2e\x30\x2e\x30\x2e\x30\x0\x0\x0\x0\x0/' /bin/mosquitto > /tmp/mosquitto
    chmod +x /tmp/mosquitto
    pkill -9 -f mosquitto
    /tmp/mosquitto -d 
fi

if [ -f /data/enable_socat ]; then
    pkill -9 -f Z3GatewayHost_MQTT
    if [ "$CLOUD" == "miot" ]; then
        sh -c 'sleep 999d' 'dummy:mZ3GatewayHost_MQTT' &
    else
        sh -c 'sleep 999d' 'dummy:Z3GatewayHost_MQTT' &
    fi
    sleep 0.5
    socat tcp-l:8888,reuseaddr,fork /dev/ttyS1 &
fi

if [ -f /data/enable_ser2net ]; then
    pkill -9 -f Z3GatewayHost_MQTT
    if [ "$CLOUD" == "miot" ]; then
        sh -c 'sleep 999d' 'dummy:mZ3GatewayHost_MQTT' &
    else
        sh -c 'sleep 999d' 'dummy:Z3GatewayHost_MQTT' &
    fi
    sleep 0.5                                       
    ser2net -C '8888:raw:0:/dev/ttyS1:115200 8DATABITS NONE 1STOPBIT'
fi

if [ -f /data/enable_ftp ]; then
    tcpsvd -vE 0.0.0.0 21 ftpd -w > /dev/null 2>&1 &
fi

if [ -f /data/enable_dropbear ]; then
    mkdir -p /data/etc
    dropbear -R -B
fi

# Custom startup script
if [ -x /data/run.sh ]; then
   /data/run.sh &
fi  

exit

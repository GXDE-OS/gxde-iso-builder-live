#!/bin/bash
source /etc/profile
dbus-daemon --system --fork 
export USER=root
export HOME=/root
export $(dbus-launch)
echo -e "123456" | vncpasswd -f > ~/.vnc/passwd
chmod 0600 ~/.vnc/passwd
vncserver :0
export $(dbus-launch)
export DISPLAY=:0
export DDE_SESSION_PROCESS_COOKIE_ID=1
gxde-terminal &
startdde &
/usr/share/novnc/utils/novnc_proxy --vnc localhost:5900
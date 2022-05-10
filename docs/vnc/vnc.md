# Abstract
About how to use VNC to connect to linux station through mac machine.

# Config at linux station

## Set password
~~~
  $ x11vnc -storepasswd
~~~

## Start x11vnc
~~~
  $ sudo x11vnc -auth guess -forever -loop -noxdamage -repeat -rfbauth /home/guding/.vnc/passwd -rfbport 5900 -shared
~~~

# Connect to linux station at mac machine
Use VNC to connect to remote desktop.Input the required password in the prompt window.
~~~
  $ vnc://guding@30.19.109.22
~~~

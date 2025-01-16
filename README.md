

sudo apt install avahi-daemon avahi-utils

sudo systemctl start avahi-daemon
sudo systemctl enable avahi-daemon


sudo apt install libavahi-compat-libdnssd



cat /etc/nsswitch.conf

Look for a line like this:
hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4


If mdns4_minimal or mdns4 is missing, update the file:
sudo nano /etc/nsswitch.conf

Add or modify the line to:
hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4



--copy this to nodevars.lua and edit to suit

-- wifi.PHYMODE_B 802.11b, More range, Low Transfer rate, More current draw
-- wifi.PHYMODE_G 802.11g, Medium range, Medium transfer rate, Medium current draw
-- wifi.PHYMODE_N 802.11n, Least range, Fast transfer rate, Least current draw 
wifi_signal_mode = wifi.PHYMODE_G
-- If the settings below are filled out then the module connects 
-- using a static ip address which is faster than DHCP and 
-- better for battery life. Blank "" will use DHCP.
-- My own tests show around 1-2 seconds with static ip
-- and 4+ seconds for DHCP
--client_ip="192.168.0.17"
--client_netmask="255.255.255.0"
--client_gateway="192.168.0.20"
client_ip=""
client_netmask=""
client_gateway=""

invert_display=false

--pin mapping
RCK=3
SER=4
SRCLK=2

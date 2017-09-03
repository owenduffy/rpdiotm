-- Remember to connect GPIO16 (D0) and RST for deep sleep function,
-- better though a SB diode anode to RST cathode to GPIO16 (D0).

--# Settings #
dofile("nodevars.lua")
--# END settings #

--pin mapping
latchPin=3
dataPin=4
clockPin=2

function to_binary(value)
  -- Formats an incoming integer value into a 32 bit binary string
  convert={["0"]="0000",["1"]="0001",["2"]="0010",["3"]="0011",
    ["4"]="0100",["5"]="0101",["6"]="0110",["7"]="0111",
    ["8"]="1000",["9"]="1001",["a"]="1010",["b"]="1011",
    ["c"]="1100",["d"]="1101",["e"]="1110",["f"]="1111"}
  -- Convert them to hex, because hex to binary is easy!
  sval=string.format("%08x",value)
print(sval)
-- Look up binary equivalent of each hex digit
  local out=""
  for c=1,8 do
    local vx=string.sub(sval,c,c)
    out=out..convert[vx]
  end
  return out
end

ssencode={[" "]=0x00;["0"]=0xfc;["1"]=0x60;["2"]=0xda;["3"]=0xf2;["4"]=0x66;
  ["5"]=0xb6;["6"]=0xbe;["7"]=0xe0;["8"]=0xfe;["9"]=0xf6;["."]=0x01;["a"]=0xee;
  ["b"]=0x3e;["c"]=0x1a;["d"]=0x7a;["e"]=0x9e;["f"]=0x8e}

function swf()
--  print("wifi_SSID: "..wifi_SSID)
--  print("wifi_password: "..wifi_password)
  wifi.eventmon.register(wifi.eventmon.STA_GOT_IP,smq)
  wifi.setmode(wifi.STATION) 
  wifi.setphymode(wifi_signal_mode)
  if client_ip ~= "" then
    wifi.sta.setip({ip=client_ip,netmask=client_netmask,gateway=client_gateway})
  end
  wifi.sta.config({ssid=wifi_SSID,pwd=wifi_password})
  print("swf done...")
end

function smq()
print(tmr.now())
  print("wifi.sta.status()",wifi.sta.status())
  if wifi.sta.status() ~= 5 then
    print("No Wifi connection...")
  else
    m=mqtt.Client(client_id,120,username,password)
    print("  IP: ".. mqtt_broker_ip)
    print("  Port: ".. mqtt_broker_port)
    print("WiFi connected...")
    m:on("offline",slp)
--m:on("connect", function(client) print ("connected") end)
--m:on("offline", function(client) print ("offline") end)
    m:connect(mqtt_broker_ip,mqtt_broker_port,0,0,
      function(conn)
        print("Connected to MQTT")
        print("  IP: ".. mqtt_broker_ip)
        print("  Port: ".. mqtt_broker_port)
        print("  Client ID: ".. mqtt_client_id)
        print("  Username: ".. mqtt_username)
        topic=mqreq()
        --setup callback for message
        m:on("message",writedisplay)
        -- subscribe topic with qos = 0
        m:subscribe(topic,0,function(conn) print("subscribe success") end)
 --       end)
      end,
      function(conn,reason)
        print("MQTT connect failed",reason)
      end)
  end
  print("smq done...")
end

function writedisplay(client,mtopic,data)
  if(mtopic==topic) then
    if data ~= nil then
      --convert to hundredths of kW
      data=data+5
      ckw=string.format("%2d",data/1000)..string.format("%02d",(data%1000)/10)
      print("Power: "..ckw)
      bb=0
      for i=1,4 do
        bb=bb*256+ssencode[string.sub(ckw,i,i)]
        if(i==2) then
          bb=bb+ssencode["."]
        end
      end
    bb=bit.bnot(bb) --invert for common anode display
  sval=string.format("%08x",bb)
  sval=string.gsub(sval,"(..)(..)(..)(..)","%1 %2 %3 %4")
print(sval)
--      print (to_binary(bb))
      sout(bb)
    end
  end
end

function slp()
  print(tmr.now())
  node.dsleep(meas_period*1000000-tmr.now()+8100,2)             
end

print("pwrdisp starting...")
--init pins
gpio.write(latchPin,gpio.HIGH)
gpio.write(dataPin,gpio.HIGH)
gpio.write(clockPin,gpio.HIGH)
gpio.mode(latchPin,gpio.OUTPUT)
gpio.mode(dataPin,gpio.OUTPUT)
gpio.mode(clockPin,gpio.OUTPUT)

--start WiFi
swf()

function sout(bb)
  --write LED display
  gpio.write(latchPin,gpio.LOW)
  for i=0,31 do
    gpio.write(clockPin,gpio.LOW)
    if(bit.isset(bb,i)) then
      gpio.write(dataPin,gpio.LOW)
    else
      gpio.write(dataPin,gpio.HIGH)
    end
    gpio.write(clockPin,gpio.HIGH)
  end
  gpio.write(latchPin,gpio.HIGH)
  --all done
  gpio.write(latchPin,gpio.HIGH)
  gpio.write(dataPin,gpio.HIGH)
  gpio.write(clockPin,gpio.HIGH)
end
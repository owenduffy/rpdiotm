-- Remember to connect GPIO16 (D0) and RST for deep sleep function,
-- better though a SB diode anode to RST cathode to GPIO16 (D0).

--# Settings #
dofile("nodevars.lua")
--# END settings #

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

ssencoder={[" "]=0x00;["."]=0x80;["0"]=0x3f;["1"]=0x06;["2"]=0x5b;["3"]=0x4f;
  ["4"]=0x66;["5"]=0x6d;["6"]=0x7d;["7"]=0x07;["8"]=0x7f;["9"]=0x6f;["a"]=0x77;
  ["b"]=0x7c;["c"]=0x58;["d"]=0x5e;["e"]=0x79;["f"]=0x71;}

function swf()
--  print("wifi_SSID: "..wifi_SSID)
--  print("wifi_password: "..wifi_password)
  wifi.eventmon.register(wifi.eventmon.STA_GOT_IP,cbsmq)
  wifi.setmode(wifi.STATION) 
  wifi.setphymode(wifi_signal_mode)
  if client_ip ~= "" then
    wifi.sta.setip({ip=client_ip,netmask=client_netmask,gateway=client_gateway})
  end
  wifi.sta.config({ssid=wifi_SSID,pwd=wifi_password})
  print("swf done...")
end

function cbsmq()
print(tmr.now())
  print("wifi.sta.status()",wifi.sta.status())
  if wifi.sta.status() ~= 5 then
    print("No Wifi connection...")
  else
    m=mqtt.Client(client_id,120,username,password)
    print("  IP: ".. mqtt_broker_ip)
    print("  Port: ".. mqtt_broker_port)
    print("WiFi connected...")
    m:on("offline",cbslp)
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
        m:on("message",cbwritedisplay)
        -- subscribe topic with qos = 0
        m:subscribe(topic,0,function(conn) print("subscribe success") end)
      end,
      function(conn,reason)
        print("MQTT connect failed",reason)
      end)
  end
  print("cbsmq done...")
end

function cbwritedisplay(client,mtopic,data)
  if(mtopic==topic) then
    if data ~= nil then
      --convert to hundredths of kW
      if((data/1)>9999) then
        data=data+5
          ckw=string.format("%2d",data/1000)..string.format("%02d",(data%1000)/10)
          dpp=2
        else
          ckw=string.format("%1d",data/1000)..string.format("%03d",(data%1000)/1)
          dpp=1
        end
      print("Power: "..ckw)
      bb=0
      for i=4,1,-1 do
        bb=bb*256+ssencoder[string.sub(ckw,i,i)]
        if(i==dpp) then
          bb=bb+ssencoder["."]
        end
      end
      if(invert_display) then
        bb=bit.bnot(bb) --invert for common anode display
      end
      sval=string.format("%08x",bb)
      sval=string.gsub(sval,"(..)(..)(..)(..)","%1 %2 %3 %4")
      print(sval)
--      print (to_binary(bb))
      sout(bb)
    end
  end
end

function cbslp()
  print(tmr.now())
  node.dsleep(meas_period*1000000-tmr.now()+8100,2)             
end

function sout(bb)
  --write LED display
  wrote=spi.send(1,bb)
end

print("app starting...")
spi.setup(1,spi.MASTER,spi.CPOL_HIGH,spi.CPHA_HIGH,32,80)
--Signal 	IO index 	ESP8266 pin
--HSPI CLK 	5 	GPIO14
--HSPI /CS 	8 	GPIO15
--HSPI MOSI 	7 	GPIO13
--HSPI MISO 	6 	GPIO12

if(invert_display) then
  sout(0xffffffff)
else
  sout(0)
end
--start WiFi
swf()


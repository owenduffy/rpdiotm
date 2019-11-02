--declare cfgvars in init.lua

print("Get available APs...")
available_aps = ""
apdatalist=""
wifi.setmode(wifi.STATION)
wifi.sta.getap(function(t)
   if t then
      for k,v in pairs(t) do
         ap = string.format("%-10s",k)
         ap = trim(ap)
         print(ap)
         available_aps = available_aps .. ap .." "
         apdatalist=apdatalist .. "<option value='" .. ap .. "'>"
      end
      print(available_aps)
      wsutmr=tmr.create()
      wsutmr:alarm(5000,tmr.ALARM_SINGLE, function() setup_server(available_aps) end )
   end
end)

local unescape = function (s)
   s = string.gsub(s, "+", " ")
   s = string.gsub(s, "%%(%x%x)", function (h)
         return string.char(tonumber(h, 16))
      end)
   return s
end

function setup_server(aps)
   print("Setting up Wifi AP")
   wifi.setmode(wifi.SOFTAP)
   wifi.ap.config({ssid="ESP8266"})  
   wifi.ap.setip({ip="192.168.1.1",netmask="255.255.255.0",gateway="192.168.1.1"})
   print("Setting up webserver")

--dhcp server
dhcp_config={}
dhcp_config.start = "192.168.1.100"
wifi.ap.dhcp.config(dhcp_config)
wifi.ap.dhcp.start()

--web server
srv = nil
srv=net.createServer(net.TCP)
srv:listen(80,function(conn)
  conn:on("receive", function(socket,request)
    local buf = ""
    local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
    if(method == nil)then
      _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP")
      end
    if (vars ~= nil)then
      socket:send("Saving data...")
      file.open("config.lua", "w")
      for key,val in string.gmatch(vars,"([%w_]+)=([^%&]*)&*") do
        file.writeline(key .. '="' .. unescape(val) .. '"')
        end
      file.close()
--      node.compile("config.lua")
--      file.remove("config.lua")
      socket:send("restarting...")
      socket:on("sent",function(skt) skt:close();collectgarbage();node.restart() end)
    else
      buf = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<html><body>"
      buf = buf .. "<h3>Configure WiFi</h3><br>"
      buf = buf .. "<form method='get' action='http://" .. wifi.ap.getip() .."'>"
      buf = buf .. "Available APs: "..aps.."<br><br>"
      buf = buf .. cfgvars[1]..": <input list='apdatalist' name='"..cfgvars[1].."'><datalist id='apdatalist'>" .. apdatalist .. "</datalist><br><br>"
      i=2 
      while cfgvars[i] do
        if(type(cfgdefs[i])=="string") then
          buf=buf .. cfgvars[i] .. ": <input type='text' name='" .. cfgvars[i] .. "' value='" .. cfgdefs[i] .. "'></input><br><br>"
        elseif(type(cfgdefs[i])=="boolean") then
          if(cfgdefs[i]) then
            buf=buf .. cfgvars[i] .. ": <input name='" .. cfgvars[i] .. "' value='true' type='checkbox' checked></input><br><br>"
          else
            buf=buf .. cfgvars[i] .. ": <input name='" .. cfgvars[i] .. "' value='true' type='checkbox'></input><br><br>"
            end
          end
        i=i+1 
        end
      buf = buf .. "<br><button type='submit'>Save</button>"                   
      buf = buf .. "</form></body></html>"
      socket:send(buf)
      socket:on("sent",function(skt) skt:close();collectgarbage() end)
      end
    end)
  end)
  
  print("Please connect to: " .. wifi.ap.getip())
  wsutmr:stop()
end

function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

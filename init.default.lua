--copy to init.lua and edit cfgdefs below
--the values correspond to cfgvars
cfgdefs={
"",
"",
"",
"mqtt.lan",
"1883",
"",
"",
"",
false
}
--no need for changes below here
cfgvars={
"wifi_SSID",
"wifi_password",
"meas_topic",
"mqtt_broker_ip",
"mqtt_broker_port",
"mqtt_username",
"mqtt_password",
"mqtt_client_id",
"invert_display"
}

function mqreq()
  topic=meas_topic
  print("req:"..topic)
  return topic
end

print("\n\nHold Pin00 low for 1s to stop boot.")
print("\n\nHold Pin00 low for 5s for config mode.")
tmr.delay(1000000)
if gpio.read(3) == 0 then
  print("Release to stop boot...")
  tmr.delay(4000000)
  if gpio.read(3) == 0 then
    print("Release now (wifit cfg)...")
    print("Starting wifi config mode...")
    dofile("wifi_setup.lua")
    return
  else
    print("...boot stopped")
    return
    end
  end

print("Starting...")
if pcall(function ()
    print("Open config")
--    dofile("config.lc")
    dofile("config.lua")
    end) then
  dofile("app.lua")
else
  print("Starting wifi config mode...")
  dofile("wifi_setup.lua")
end

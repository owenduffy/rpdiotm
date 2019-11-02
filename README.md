# A simple IoT power meter display for NodeMCU / Lua subscribed to measurements by [MQTT API](https://en.wikipedia.org/wiki/MQTT).

To use the code, copy init.default.lua to init.lua, and nodevars.default.lua to nodevars.lua and customise the latter to suit your needs.

![alt text](rpdiotm01.png "Flow chart")

See project described at [ESP8266 remote power display for energy monitor – EV3 – 5V display](http://owenduffy.net/blog/?p=11227) .

Tested on:
NodeMCU 3.0.0.0 built on nodemcu-build.com provided by frightanic.com
    branch: master
    commit: 310faf7fcc9130a296f7f17021d48c6d717f5fb6
    release: 3.0-master_20190907
    release DTS: 201909070945
    SSL: true
    build type: float
    LFS: 0x0
    modules: adc,bit,bme280,dht,encoder,file,gpio,http,i2c,mdns,mqtt,net,node,ow,sntp,spi,tmr,uart,wifi,tls
 build 2019-11-01 23:27 powered by Lua 5.1.4 on SDK 3.0.1-dev(fce080e)


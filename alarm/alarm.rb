#!/usr/bin/ruby1.9.3
require 'packetfu'

#stream = PacketFu::Capture.new(:start => true, :iface => 'eth0')
#stream.show_live()

cap = PacketFu::Capture.new(:iface => 'eth0', :promisc => true)
cap.start
sleep 10
cap.save



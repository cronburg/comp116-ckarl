require 'csv'
require 'ip2location_ruby'

class I2L < Ip2location
	
	# Convert from integer format to 4-tuple IP format:
	def int2ip(i)
		w = (i / 16777216) % 256
		x = (i / 65536) % 256
		y = (i / 256) % 256
		z = i % 256
		return [w,x,y,z]
	end

	# This is (should be) the same as ip.unpack("N")[0]
	# Convert from 4-octet binary string to integer format
	#def ip2int(ip)
	#	return (ip[0].ord)*16777216 + (ip[1].ord)*65536 + (ip[2].ord)*256 + ip[3].ord

	# Overrides get_all(ip) in 'lib/ip2location_ruby.rb:27'
	# Takes a string containing a 4-octet binary string rather than e.g. "192.168.8.101"
	def get_all(ip)
		self.v4 = ip.length == 4 && self.ip_version == 4
		ipnum = ip.unpack("N")[0] + 0
		mid = self.count/2
		col_length = columns * 4
		low = 0
		high = count
		return self.record = bsearch(low, high, ipnum, self.base_addr, col_length)
	end

	# Returns [long,lat] corresponding to the given 
	def get_geoloc(ip)
		rec = self.get_all ip
		return [rec.longitude,rec.latitude]
	end
end

#@@i2l = Ip2location.new.open('db11/IP2LOCATION-LITE-DB11.BIN')
#@@fields = %w{ ip country region city lat long zip timezone }
	
#I2L.ip2int("\xC0\xA8\xEF\x81")

#i2l = Ip2location.new.open(ARGV[0])
#rec = i2l.get_all('8.8.8.8')
#rec = i2l.get_all('130.64.23.105')

#(open(ARGV[0]).read.split ',').each { |ip|
#	rec = i2l.get_all(ip)
	#puts rec.inspect
#	puts rec.latitude.to_s + "," + rec.longitude.to_s
	#puts rec.latitude
	#puts rec.longitude
#}


require './libi2l'
require 'haversine'

class Rectangle
	def initialize(x1,y1,x2,y2)
		@x1 = x1 # left edge on the map
		@y1 = y1 # bottom edge on the map
		@x2 = x2 # right edge on the map
		@y2 = y2 # top edge on the map
		@xc = [x1,x2].min + (x2 - x1).abs / 2.0
		@yc = [y1,y2].min + (y2 - y1).abs / 2.0
		dw = (x2 - x1).abs / 2.0
		dh = (y2 - y1).abs / 2.0
		@w = Haversine.distance([@yc,@xc],[@yc,@xc+dw]).to_km
		@h = Haversine.distance([@yc,@xc],[@yc+dh,@xc]).to_km
	end
	
	# TODO: Returns true if the point (x,y) is contained in this rectangle
	def contains?(x,y)
		dx = Haversine.distance([@yc,@xc],[@yc,x]).to_km
		dy = Haversine.distance([@yc,@xc],[y,@xc]).to_km
		#puts dx
		#puts dy
		return (dx < @w and dy < @h)
	end

end

class Filter
	@@i2l = I2L.new.open('db11/IP2LOCATION-LITE-DB11.BIN')
	def self.i2l
		return @@i2l
	end
end

class RectangleFilter < Filter
	
	def initialize()
		@squares = []
	end

	# Add a new square to the list of squares
	def add(rect)
		@squares.push(rect)
	end

	# Removes the square with the specified coordinates from the list of squares
	def remove(rect)
		@squares.delete(rect)
	end
	
	# Returns true if the given 4-octet binary string IP address
	# is to be blocked based on the squares currently on the map (in @squares)
	def block?(ip)
		rec = @@i2l.get_all(ip)
		lat = rec.latitude
		lng = rec.longitude
		return @squares.each.map { |s| s.contains?(lat,lng) }.any?
	end
end

#rf = RectangleFilter.new
#r = Rectangle.new(0,0,2,2)
#rf.add(r)
#puts rf.block?("\xD1\x06\x59\xF0")

#puts false == r.contains?(-1,-1)
#puts true  == r.contains?(0,0)
#puts true  == r.contains?(1,1)
#puts true  == r.contains?(2,2)
#puts false == r.contains?(3,3)

#r2 = Rectangle.new(42.0, -72.0, 43.0, -70.0)
#rf.add(r2)
#puts rf.block?("\xD1\x06\x59\xF0")




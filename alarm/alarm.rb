require 'packetfu'
include PacketFu
include Kernel
require 'socket'
require 'webrick'
require 'stringio'

#stream = PacketFu::Capture.new(:start => true, :iface => 'eth0', :promisc => true)
#stream.show_live()

# Converts the string to hex
def binary(str)
	return str.each_byte.map { |b| sprintf(" 0x%02X ",b) }.join
end

# Checks to see if this TCP packet has flags indicating an Xmas scan:
def xmas_scan?(pkt, type)
	return false if type != 'tcp'
	flags = pkt.tcp_flags
	flag_info = [(flags.send 'fin'), (flags.send 'urg'), (flags.send 'psh')]
	return flag_info.all? { |e| e == 1 }
end

# Checks to see if this TCP packet has flags indicating a NULL scan:
def null_scan?(pkt, type)
	return false if type != 'tcp'
	return pkt.tcp_flags_dotmap == '......'
end

# Returns true if SYN bit is on, otherwise false
def syn?(pkt, type)
	return false if type != 'tcp'
	return pkt.tcp_flags.syn == 1
end

# Returns true of RST bit is on, otherwise false
def rst?(pkt, type)
	return false if type != 'tcp'
	return pkt.tcp_flags.rst == 1
end

# Returns true if plain-text POP3 password is in this pkt, otherwise false
def pop3?(pkt, type)
	#puts '--' + pkt.tcp_header.body.downcase + '--'
	hdr = pkt.send (type+'_header')
	port = hdr.send (type+'_dst')
	return (port == 110 and hdr.body.downcase.start_with? "pass")
end

# Returns true if plain-text IMAP password is in this pkt, otherwise false
def imap?(pkt, type)
	hdr = pkt.send (type+'_header')
	port = hdr.send (type+'_dst')
	return (port == 143 and /\w* login \S* \S*\r\n/.match(hdr.body.downcase) != nil)
end

# Returns true if a credit card number is detected in the body of the header
# NOTE: Regular expressions taken from the following URL and adapted for use in ruby:
#       http://www.sans.org/security-resources/idfaq/snort-detect-credit-card-numbers.php
# Assumptions:
#		--> CC #s can be in one of three formats:
#			--> ?xxx-xxxx-xxxx-xxxx
#			--> ?xxx xxxx xxxx xxxx
#			--> ?xxxxxxxxxxxxxxx
#			where the '?' can be one of 3,4,5 for amex, visa, and mastercard respectively
#			(discover has first four digits of 6011)
#		--> The content of a page containing a 16 digit number in one of these formats should
#       also contain the string 'visa', 'mastercard', 'discover', or 'amex' for each of
#       the respective formats. This should significantly reduce the number of false positives.
def credit_card?(pkt,type)
	body = (pkt.send (type+'_header')).body
	visa   = ((/4\d{3}(\s|-)?\d{4}(\s|-)?\d{4}(\s|-)?\d{4}/.match(body) != nil) and (body.downcase.include? 'visa'))
	master = ((/5\d{3}(\s|-)?\d{4}(\s|-)?\d{4}(\s|-)?\d{4}/.match(body) != nil) and (body.downcase.include? 'mastercard'))
	disc   = ((/6011(\s|-)?\d{4}(\s|-)?\d{4}(\s|-)?\d{4}/.match(body) != nil) and (body.downcase.include? 'discover'))
	amex   = ((/3\d{3}(\s|-)?\d{6}(\s|-)?\d{5}/.match(body) != nil) and (body.downcase.include? 'amex'))
	ret = (visa or master or disc or amex)
	#puts "%s-%s-%s-%s" % [visa, master, disc, amex] if ret
	#puts "%s-%s" % [(/3\d{3}(\s|-)?\d{6}(\s|-)?\d{5}/.match(body) != nil), (body.downcase.include? 'amex')] if ret
	#puts body
	return ret
end

# Returns true if an HTTP GET request containing XSS is detected in the body of a TCP or UDP packet
def get_xss?(pkt,type)
	body = (pkt.send (type+'_header')).body
	#puts body
	get = /\AGET\s+(?<get_request>\S+)\s+(HTTP)/.match(body)
	#puts get.inspect
	if get != nil
		path = get["get_request"]
		#puts path
		ret = /((\%3C)|<)((\%2F)|\/)*[a-z0-9\%]+((\%3E)|>)/ix.match(path)
		#puts ret.inspect
		return ret
	end
	return false
end

# Returns true if an HTTP POST request containing XSS is detected in the body of a TCP or UDP packet
def post_xss?(pkt,type)
	body = (pkt.send (type+'_header')).body
	post = /\APOST\s+(?<post_request>\S+)\s+(HTTP)/.match(body)
	if post != nil
		#puts body
		req = WEBrick::HTTPRequest.new(WEBrick::Config::HTTP)
		req.parse(StringIO.new(body))
		#puts req.body
		ret = /((\%3C)|<)((\%2F)|\/)*[a-z0-9\%]+((\%3E)|>)/ix.match(req.body)
		return ret
	end
	return false
end

# Dictionaries for keeping track of number of SYNs and RSTs by IP to IP:
$syn_dict = Hash.new
$syn_dict.default = 0
$rst_dict = Hash.new
$rst_dict.default = 0
Suspicious = 10 # number of SYN/RST packets to consider suspicious

# Determines if a RST packet is suspicious based on # of previous SYNs and RSTs
def syn_scan?(pkt, type)
	path = pkt.ip_daddr + "-" + pkt.ip_saddr
	ret = ($syn_dict[path] > Suspicious and $rst_dict[path] > Suspicious)
	$syn_dict[path] = 0 if ret
	$rst_dict[path] = 0 if ret
end

# Keeps track of the number of SYNs sent from each SRC->DST pair seen so far
def update_syn(pkt)
	path = pkt.ip_saddr + "-" + pkt.ip_daddr
	$syn_dict[path] += 1
end

# Keeps track of the number of RSTs sent from each DST->SRC pair seen so far
def update_rst(pkt)
	path = pkt.ip_daddr + "-" + pkt.ip_saddr
	$rst_dict[path] += 1
end	

# Keeps track of who sends how many packets to who - 1000 packets sent in a
# short period of time is indicative of an nmap scan
Suspicious_Count = 400
$count_dict = Hash.new
$count_dict.default = 0
def nmap_scan?(pkt, type)
	path = pkt.ip_saddr + "-" + pkt.ip_daddr
	$count_dict[path] += 1
	ret = ($count_dict[path] > Suspicious_Count)
	$count_dict[path] = 0 if ret
	body = (pkt.send (type+'_header')).body
	ret = (ret or (body.include? 'Nmap'))
	return ret
end

# Start the capture in another process, buffering the packet data to the
# parent so that packets don't get dropped:
$read, $write = IO.pipe
#$read, $write = Socket.pair(:UNIX, :DGRAM, 0)
def start_capture
	pid = fork do
		$read.close
		#cap = Capture.new(:start => true, :iface => 'eth0', :promisc => true)
		cap = Capture.new(:start => true, :iface => 'vmnet8', :promisc => true)
		cap.stream.each do |p|
			dump = Marshal.dump(p)
			#$write.send(Marshal.dump(p), 0)
			$write.write Marshal.dump(p)
			$write.write "x-x-x-x"
			#puts cap.stream.stats
		end
	end
	$write.close
	return pid
end

pkt_num = 0
count = 0
child_pid = start_capture()
$read.each_line("x-x-x-x") { |p|
#while true do
	#p = $read.recv(1e6)
	#puts p
	p = Marshal.load(p)
	#puts p
	pkt_num += 1
	pkt = Packet.parse p
	next if pkt == nil
	#if pkt.is_tcp? and pkt.tcp_dst != 22
	#	puts "(%d) %s %s %d %s %d" % [pkt_num, (syn? pkt), (rst? pkt), pkt.tcp_flags.syn, pkt.ip_saddr, pkt.tcp_dst]
	#	end
	#puts "(%d) %s %s %s" % [pkt_num, pkt.is_tcp?, pkt.is_udp?, pkt.is_ip?]
	type = nil
	type = "tcp" if pkt.is_tcp?
	type = "udp" if pkt.is_udp?

	if pkt.is_ip? and type != nil
		if xmas_scan? pkt,type
			puts "%d. ALERT: Xmas scan is detected from %s (%s)" % [count+=1, pkt.ip_saddr, type.upcase]
		elsif null_scan? pkt,type
			puts "%d. ALERT: NULL scan is detected from %s (%s)" % [count+=1, pkt.ip_saddr, type.upcase]
		end
		
		update_syn pkt if syn? pkt,type
		
		if rst? pkt,type
			update_rst pkt
			if syn_scan? pkt,type
				puts "%d. ALERT: SYN/TCP scan is detected from %s (%s)" % [count+=1, pkt.ip_daddr, type.upcase]
			end
		end
		
		if nmap_scan? pkt,type
			puts "%d. ALERT: Nmap scan is detected from %s (%s)" % [count+=1, pkt.ip_daddr, type.upcase]
		end

		#puts pkt
		if pop3? pkt,type #pkt.tcp_dst pkt.tcp_header.body
			puts "%d. ALERT: POP3 password leaked in the clear from %s (%s)" % [count+=1, pkt.ip_saddr, type.upcase]
		elsif imap? pkt,type #pkt.tcp_dst pkt.tcp_header.body
			puts "%d. ALERT: IMAP password leaked in the clear from %s (%s)" % [count+=1, pkt.ip_saddr, type.upcase]
		end
		
		if credit_card? pkt,type
			puts "%d. ALERT: Credit card leaked in the clear from %s (%s)" % [count+=1, pkt.ip_saddr, type.upcase]
		end
		
		if ((get_xss? pkt,type) or (post_xss? pkt,type))
			puts "%d. ALERT: XSS is detected from %s (%s)" % [count+=1, pkt.ip_saddr, type.upcase]
		end

	end
}


require 'nfqueue'
require 'packetfu'
require './packetfilter'
require 'mkfifo'

NFQUEUE_FIFO = "/var/www/nfqueue.fifo"
NFQUEUE_LOCK = "./nfqueue.rb.lock"

def exitme()
	puts "nfqueue.rb is already running. Try:"
	puts "$ ps -e | grep ruby | awk '{print $1}' | xargs sudo kill -s INT"
	puts "to safely kill the running process. If you're positive nothing"
	puts "is running then do:"
	puts "$ sudo rm #{NFQUEUE_FIFO} #{NFQUEUE_LOCK}"
	exit
end

# Only one instance of nfqueue.rb
f = File.open(NFQUEUE_LOCK, File::RDWR|File::CREAT, 0644)
exitme unless f.flock( File::LOCK_NB | File::LOCK_EX )

# Blocking loop for getting fifo input:
pid2 = fork do
	# FIFO queue for sending whitelist / blacklist filtering rules to this program
	pipe = nil
	trap("INT") {
		pipe.close if pipe != nil
		File.unlink(NFQUEUE_FIFO)
		exit
	}
	while true
		fifo = File.mkfifo(NFQUEUE_FIFO)
		`chown www-data:www-data #{NFQUEUE_FIFO}`
		pipe = open(NFQUEUE_FIFO, 'r')
		pipe.each_line do |line|
			puts "--#{line}--"
		end
		pipe.close
		File.unlink(NFQUEUE_FIFO)
	end
end

# Client which runs forever
#pid1 = fork do
#	client = open(NFQUEUE_FIFO, 'w')
#	trap("INT") { client.close; exit }
#	while true
#		sleep 300
#	end
#end

# Cleans up on SIGINT / Ctrl-C
trap("INT") {
	#puts "Cleaning up iptables and shutting down...";
	`./fw.stop`;
	f.flock( File::LOCK_UN )
	File.unlink(NFQUEUE_LOCK);
	exit
}

# TODO: Remove this (debugging)
#while true
#	sleep 300
#end

# Returns tcp/udp type for the given PacketFu::IPHeader
def get_type(pkt)
	type = nil
	type = "tcp" if pkt.is_tcp?
	type = "udp" if pkt.is_udp?
	return type
end

# Only monitor incoming port 80 packets for now. In a more robust
# implementation we should filter packets on all ports to help
# prevent DoS attacks. For now this rule acts as a way to block
# only web traffic coming from certain countries or regions.
`./fw.stop`
`iptables -A INPUT -p tcp --dport 80 -j NFQUEUE --queue-num 0`

# Call-back for packets put into the queue
pkt = PacketFu::IPHeader.new
Netfilter::Queue.create(0) do |packet|
	puts "Inspecting packet ##{packet.id}"
	
	#p packet.data
	#line = packet.data.each_byte.map { |b| sprintf(" %02X",b) }.join
	#p line

	# Parse the binary data into a PacketFu::IPHeader
	pkt.read packet.data

	puts "Source = '%s'" % [pkt.ip_saddr]
	puts "Dest   = '%s'" % [pkt.ip_daddr]
	puts "Body   = '%s'" % [pkt.body]

	# Accept the packet
	Netfilter::Packet::ACCEPT
end


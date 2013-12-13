
all: data

data: rb/db11/IP2LOCATION-LITE-DB11.BIN

rb/db11/IP2LOCATION-LITE-DB11.BIN:
	wget http://www.eecs.tufts.edu/~karl/comp116/README_LITE.TXT
	wget http://www.eecs.tufts.edu/~karl/comp116/LICENSE_LITE.TXT
	wget http://www.eecs.tufts.edu/~karl/comp116/IP2LOCATION-LITE-DB11.BIN
	mv *.TXT *.BIN rb/db11/

clean:
	rm -f ./nfqueue.rb.lock /var/www/nfqueue.fifo ./rb/db11/*
 

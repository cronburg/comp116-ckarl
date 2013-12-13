Repository for Karl Cronburg
Comp 116 - Intro to Computer Security

This directory contains:
  - www : the web front-end which can be installed in /var/www like:
      $ cp -r www/* /var/www/
    - www/map.{css,html,js} : files served to the client / content provider. These
      make use of the Google Maps API and AJAX Jquery API.
    - www/get_data.php : a PHP script which currently returns a list of static
      longitude / latitude data, but should ultimately parse and return a list of
      this data based on the most recent entries in /var/log/apache2/*.log
    - www/submit_list.php : a PHP script for communicating the geolocation filtering
      rules to the ruby script. The script makes use of named FIFOs in Linux, however
      it does not presently send actual filtering rules to ruby (it is just a
      proof-of-concept that filtering rules can be transmitted to ruby in this manner).
  - nfqueue : the back-end code and database for the packet filtering
    - fw.stop : bash script for resetting all iptables chains to default ACCEPT
    - libi2l.rb : ruby module containing a class for accessing the IP database
    - packetfilter.rb : ruby module with a class for containing filter rules and the
      operations / methods performed on them (such as determining whether or not to
      filter a particular IP address).
    - nfqueue.rb : ruby daemon for capturing network traffic entering the machine
      on port 80 and sending verdicts back to the network stack whether or not to
      drop the packet.

Running the scripts:
  NOTE: At present, there is a bug in the nfqueue ruby gem which causes ruby and
  the apache server to seg fault after receiving about 200 packets. As such I have
  submitted a bug report, but was unable to get the issue resolved in time for
  submitting this project. It is recommended that one use an Ubuntu
  Virtual Machine when using this source code, since the segmentation fault requires
  rebooting the machine to get apache to work again.

  To install the necessary ruby gems do:
  rvmsudo gem install ip2location_ruby
  rvmsudo gem install packetfu
  rvmsudo gem install mkfifo

  To install a LAMP server in ubuntu, do:
  sudo apt-get install tasksel
  sudo tasksel install lamp-server

  After this you can copy www into the proper place:
  cp -r www/* /var/www/

  Then go into the nfqueue (back-end code directory) and retrieve the 55MB IP database:
  make data # see Makefile for where the database is downloaded from

  Now one should be able run the ruby daemon:
  rvmsudo ruby nfqueue.rb

  And then one can navigate a web browser to localhost/map.html and interact
  with the front end. When requesting web pages, you should see the ruby daemon
  printing out packet data (source IP, destination IP, and content of the packet).
  If you click on the "Submit Blacklist" or "Submit Whitelist" buttons, you should
  also see the daemon print out "--data\n--\n--data2\n--\n" which is a hold-over
  for where filter rules will be transmitted to the daemon.


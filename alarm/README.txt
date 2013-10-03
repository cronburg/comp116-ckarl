Karl Cronburg (karl@cs.tufts.edu)
Oct-1-2013
Comp 116: Intro to Computer Security

IMPORTANT NOTE: A network interface of 'eth0' is hardcoded into the script. Go to
the line containing 'eth0' and change it to the desired interface.

------------------------------------------------------------------------------------------------
NMAP DETECTION:
---------------

Explicitly Detectable:
----------------------
My IDS is capable of explicitly detecting the following nmap scans:
	--> NULL scan (-sN)
	--> Xmas scan (-sX)
	--> SYN/TCP scans (-sS and -sT)

Implicitly Detectable:
----------------------
The following scans are also detectable, though are as of now indistinguishable
by my IDS because they are detected based on the number of packets being sent
to / from certain IP addresses:
	--> FIN scan (-sF), though this one would be easy to detect explicitly if requested
	--> TCP ACK scan (-sA)
	--> TCP Window scan (-sW)
	--> TCP Maimon scan (-sM)
	--> Service/Version Detection scan (-sV), which shows up as multiple SYN/TCP
			and Nmap scanning incidents.
	--> OS Detection scan (-O), which shows up as multiple SYN/TCP, Xmas, NULL, and
			nmap scans.
	--> UDP scan (-sU), though it takes 10+ minutes since the scan itself can take that long.

Presently Undetectable:
-----------------------
The following scans go undetected, as they are much harder to identify in a
straightforward / general manner:
	--> SCTP INIT scans (-sY), because PacketFu does not have SCTP built-in
	--> SCTP COOKIE ECHO scan (-sZ), again no built-in SCTP support
	--> Zombie scans (-sI), which will instead show up as scans by the zombie host
	--> Ping scan (-sP), because it is indistinguishable from normal ping traffic
	--> Fast scans (-F), may go undetected because I use a traffic threshold,
			but fast scans (which scan fewer ports) may not meet the threshold

IDS Shortcomings:
-----------------
The current implementation does not take into account short bursts of packets
coming from a particular host as opposed to packets sent over the course a long
period of time. The former is indicative of a real incident having occurred
whereas the latter can occur through regular usage of a network. As such, the IDS
presently detects all the standard Nmap scans, but could produce a lot of false
positives if sniffing on a high-volume network for an extended period of time.

------------------------------------------------------------------------------------------------
PASSWORD DETECTION:
-------------------

Detectable:
-----------
My IDS currently detects the following forms of plaintext password leakage:
	--> POP3, by watching for a "PASS" command for packets destined for port #110
	--> IMAP, using a regular expression for the syntax of the "LOGIN" command

Presently Undetectable:
-----------------------
	--> Passwords entered into interactive sessions (eg telnet)
	--> Passwords for logging into websites (same idea as interactive sessions,
			since each website will have a different login procedure)

IDS Shortcomings:
-----------------
For capturing email address passwords configured using plain-text POP3 and IMAP,
the current detection scheme works perfectly. Given more time we could analyze
how similar plain-text protocols involving passwords work, and implement ways
to detect / extract them.

------------------------------------------------------------------------------------------------
CREDIT CARD DETECTION:
----------------------

Detectable:
-----------
The following credit cards are detected by my IDS:
	--> VISA (4xxx-xxxx-xxxx-xxxx)
	--> MASTERCARD (5xxx-xxxx-xxxx-xxxx)
	--> DISCOVER (6011-xxxx-xxxx-xxxx)
	--> AMEX (3xxx-xxxx-xxxx-xxxx)
All of the above can be detected in each of these three formats:
	--> xxxx-xxxx-xxxx-xxxx
	--> xxxx xxxx xxxx xxxx
	--> xxxxxxxxxxxxxxxx
To reduce the number of false positives, the Credit Card code/string for each
Credit Card company is also searched for in the body of the packets. Ignoring
case, these are "VISA", "MASTERCARD", "DISCOVER", and "AMEX".

Presently Undetectable:
-----------------------
	--> Credit cards not from one of the four main companies listed above
			because way too many false positives would be produced just looking
			for a 16 digit number in every packet seen on the wire.

IDS Shortcomings:
-----------------
To better detect credit card numbers it would be good to look for things like HTTP
fields pertaining to the CCV2, Expiration Date, and similar fields usually found
on websites requesting credit card information. This would require much more in-depth
analysis of current practices used by major companies, in addition to an implementation
tailored to the specific patterns used in transmission of credit card information.

------------------------------------------------------------------------------------------------
XSS DETECTION:
----------------------

Detectable:
-----------
The primary vector by which an attacker executes an XSS attack is making an HTTP request
to a vulnerable website. As such, my IDS detects the following two vectors:
	--> GET requests containing <script> tags
	--> POST requests containing <script> tags
Although it is plausible a legitimate user might be uploading a script to a website,
it is still highly suspicious to see <script> tags in an HTTP request. Additionally,
the the entire body of *any* HTML request is not searched because this results in
far too many false positives (namely when a website presents a user with a legitimate
script).

Presently Undetectable:
-----------------------
	--> Persistent XSS attacks for which we did not have access to the attacker's original
			payload - it is infeasible / difficult to detect malicious scripts which are served to users
			by a trusted website which has been compromised by an XSS exploit.

IDS Shortcomings:
-----------------
The main problems with detecting XSS attacks are dealing with false-positives and
scanning javascript code for indications of tampering. This is in part an unsolved
problem in Machine Learning.

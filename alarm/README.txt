Karl Cronburg (karl@cs.tufts.edu)
Oct-1-2013
Comp 116: Intro to Computer Security

My IDS is capable of explicitly detecting the following nmap scans:
	--> NULL scan (-sN)
	--> Xmas scan (-sX)
	--> SYN/TCP scans (-sS and -sT)

The following scans are also detectable, though are as of now indistinguishable
by my IDS:
	--> FIN scan (-sF), though this one would be easy to detect explicitly if requested

(-sU)???

The following scans go undetected, as they are much harder to identify in a
straightforward / general manner:
	--> SCTP INIT scans (-sY), because PacketFu does not have SCTP built-in


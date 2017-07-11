from __future__ import print_function
from scapy.all import *
import os

## Source IP Counter
counter = 0
veth = sys.argv[1]

if(os.path.isfile("host.log")):
	os.remove("host.log")

def getSrcIP(packet):
	global counter
	counter += 1
	fileLog = open("host.log", "a")
	fileLog.write('[{}]: {}\n'.format(counter, packet[0][1].src))
	return '[{}]: {}'.format(counter, packet[0][1].src)

sniff(iface = veth, prn=getSrcIP, filter="ip")

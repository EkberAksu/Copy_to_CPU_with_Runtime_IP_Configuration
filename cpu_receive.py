from __future__ import print_function
from scapy.all import *
import os

## Source IP Counter
counter = 0

if(os.path.isfile("cpu.log")):
	os.remove("cpu.log")

def getSrcIP(packet):
	global counter
	counter += 1
	fileLog = open("cpu.log", "a")
	fileLog.write('[{}]: {}\n'.format(counter, packet[0][1].src))
	return '[{}]: {}'.format(counter, packet[0][1].src)

#sniff(iface = "veth6", prn=lambda x : ls(x))
sniff(iface = "veth0", prn=getSrcIP, filter="ip")

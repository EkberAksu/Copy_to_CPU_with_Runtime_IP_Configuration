from scapy.all import *

p = Ether(src="00:00:00:00:01:00")/ IP(src="10.0.1.0", dst="10.0.0.1") / TCP(flags='A') / "P1 10.0.1.0 --> 10.0.0.1"
p.show()
#hexdump(p)
#ls(p)
sendp(p, iface = "veth8")

p = Ether(src="00:00:00:00:02:00")/ IP(src="10.0.2.0", dst="10.0.0.1") / TCP(flags='A') / "P2 10.0.2.0 --> 10.0.0.1"
p.show()
#hexdump(p)
#ls(p)
sendp(p, iface = "veth8")

p = Ether(src="00:00:00:00:03:00")/ IP(src="10.0.3.0", dst="10.0.0.1") / TCP(flags='A') / "P3 10.0.3.0 --> 10.0.0.1"
p.show()
#hexdump(p)
#ls(p)
sendp(p, iface = "veth8")

p = Ether(src="00:00:00:00:04:00")/ IP(src="10.0.4.0", dst="10.0.0.1") / TCP(flags='A') / "P4 10.0.4.0 --> 10.0.0.1"
p.show()
#hexdump(p)
#ls(p)
sendp(p, iface = "veth8")

p = Ether(src="00:00:00:00:05:00")/ IP(src="10.0.5.0", dst="10.0.0.1") / TCP(flags='A') / "P4 10.0.5.0 --> 10.0.0.1"
p.show()
#hexdump(p)
#ls(p)
sendp(p, iface = "veth8")
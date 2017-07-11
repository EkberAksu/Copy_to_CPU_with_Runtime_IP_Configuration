# Copy_to_CPU_with_Runtime_IP_Configuration
P4 project 

## Description
This program shows how we can mirror the incoming packets to the CPU port for desired IP addresses. The program acts as simple switch if no packets should be mirrored to the CPU.

The P4 program does the following:
- incoming packets are mirrored to the CPU port in the ingress pipeline if the destination IP address is in the copy_to_cpu table. This table can be modified from the [commands](commands.txt). The current table contains 2 IP addresses: `10.0.1.0` and `10.0.3.0`;
- next hop is obtained from the ipv4_lpm table in the ingress pipeline;
- the packet's destination is obtained from the forward table in the ingress pipeline;
- the original packet is sent to it's original destination in the egress pipeline;

### Before running the program
You will need to clone 2 repositories and install their dependencies. 
To clonde the repositories:

- `git clone https://github.com/p4lang/behavioral-model.git bmv2`.
This repository is the behavioral model. It is a C++ software switch that will behave according to the P4 program. Since `bmv2` is a C++ repository it has more external dependencies. Click [here](https://github.com/p4lang/behavioral-model/blob/master/README.md) to see the dependencies of `bmv2`.

- `git clone https://github.com/p4lang/p4c-bm.git p4c-bmv2`
This repository is the compiler for the behavioral model. It takes P4 program and output a JSON file which can be loaded
by the behavioral model. Click [here](https://github.com/p4lang/p4c-bm/blob/master/README.rst) to see the dependencies of `p4c-bmv2`.

Do not forget to update the values of the shell variables BMV2_PATH and P4C_BM_PATH in the env.sh file - located in the root directory of this repository.

You will also need to run `sudo ./veth_setup.sh` command to setup the veth interfaces needed by the switch.

### Running the program
This repository contains 4 scripts:
- [run_switch.sh](run_switch.sh): compiles the P4 program and starts the switch, 
  also configures the data plane by running the CLI [commands](commands.txt);
- [host_receive.py](host_receive.py): sniffes packets on the port passed as command line argument. Pass veth2 or veth3 in our case;
- [cpu_receive.py](cpu_receive.py): sniffes packets on cpu port(port 0);
- [send_one.py](send_one.py): sends one simple IPv4 packet on port 4 (veth8);

If you take a look at [commands](commands.txt), you'll notice the following command: `mirroring_add 250 0`. This means that all the cloned packets with mirror id `250` will be sent to port 0, which is our default *CPU port*. This is the reason why [cpu_receive.py](cpu_receive.py) should sniff for incoming packets on port 0(veth0/veth1). You can change the cpu port from the `commands.txt`, make sure you change the [cpu_receive.py](cpu_receive.py) with corresponding veth number.

To start the demo run the following scripts, each in a different console:
- `./run_switch.sh` - start the switch and configure the tables and the mirroring session;
- `sudo python host_receive.py veth2` - start the host port listener(which is port 1(veth2/veth3) in our case);
- `sudo python cpu_receive.py` - start the cpu port listener(which is port 0(veth0/veth1) in our case);
- `sudo python send_one.py` - send one packet on port 4(veth8); 

Every time you send packets, their sorce ip addresses should be displayed by the host port listener, and sorce ip's of the packets copied to cpu are displayed by the cpu port listener.


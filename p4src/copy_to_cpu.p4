/*
Copyright 2013-present Barefoot Networks, Inc. 
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/

/*
 * cpu header 
 */
header_type cpu_header_t {
    fields {
        device: 8;
        reason: 8;
    }
}

/*
 * Standard ethernet header 
 */
header_type ethernet_t {
    fields {
        dstAddr     : 48;
        srcAddr     : 48;
        etherType   : 16;
    }
}

/*
 * Standard ipv4 header 
 */
header_type ipv4_t {
    fields {
        version     : 4;
        ihl         : 4;
        diffserv    : 8;
        ipv4_length : 16;
        id          : 16;
        flags       : 3;
        offset      : 13;
        ttl         : 8;
        protocol    : 8;
        checksum    : 16;
        srcAddr     : 32;
        dstAddr     : 32;
    }
}

/*
 * Standard tcp header 
 */
header_type tcp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        seqNo : 32;
        ackNo : 32;
        dataOffset : 4;
        res : 4;
        flags : 8;
        window : 16;
        checksum : 16;
        urgentPtr : 16;
    }
}

/*************************************************************************
 ***********************  M E T A D A T A  *******************************
 *************************************************************************/

header_type custom_metadata_t {
    fields {
        nhop_ipv4: 32;
        // TODO: Add the metadata for hash indices and count values
        hash_val1: 16;
        hash_val2: 16;
        count_val1: 16;
        count_val2: 16;
    }
}


header cpu_header_t cpu_header;
header ethernet_t ethernet;
header ipv4_t ipv4;
header tcp_t tcp;

/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/

parser start {
    return select(current(0, 64)) {
        0 : parse_cpu_header;
        default: parse_ethernet;
    }
}

parser parse_cpu_header {
    extract(cpu_header);
    return parse_ethernet;
}

#define ETHERTYPE_IPV4 0x0800

parser parse_ethernet {
    extract(ethernet);
    return select(ethernet.etherType){
        ETHERTYPE_IPV4  : parse_ipv4;
        default         : ingress;
    }
}

#define IP_PROT_TCP 0x06

parser parse_ipv4 {
    extract(ipv4);
    return select(ipv4.protocol){
        IP_PROT_TCP : parse_tcp;
        default     : ingress;
    }
}

parser parse_tcp {
    extract(tcp);
    return ingress;
}


#define CPU_MIRROR_SESSION_ID                  250

/*************************************************************************
 ************   C H E C K S U M    V E R I F I C A T I O N   *************
 *************************************************************************/

field_list ipv4_checksum_list {
        ipv4.version;
        ipv4.ihl;
        ipv4.diffserv;
        ipv4.ipv4_length;
        ipv4.id;
        ipv4.flags;
        ipv4.offset;
        ipv4.ttl;
        ipv4.protocol;
        ipv4.srcAddr;
        ipv4.dstAddr;
}

field_list_calculation ipv4_checksum {
    input {
        ipv4_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

field_list tcp_checksum_list {
        ipv4.srcAddr;
        ipv4.dstAddr;
        8'0;
        ipv4.protocol;
        tcp.srcPort;
        tcp.dstPort;
        tcp.seqNo;
        tcp.ackNo;
        tcp.dataOffset;
        tcp.res;
        tcp.flags;
        tcp.window;
        tcp.urgentPtr;
        payload;
}

field_list_calculation tcp_checksum {
    input {
        tcp_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field tcp.checksum {
    verify tcp_checksum if(valid(tcp));
    update tcp_checksum if(valid(tcp));
}

calculated_field ipv4.checksum  {
    verify ipv4_checksum;
    update ipv4_checksum;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

field_list copy_to_cpu_fields {
    standard_metadata;
}

action _drop() {
    drop();
}

action do_copy_to_cpu() {
    clone_ingress_pkt_to_egress(CPU_MIRROR_SESSION_ID, copy_to_cpu_fields);  
}

table copy_to_cpu {
    reads {
        ipv4.srcAddr : exact;
    }
    actions {
        do_copy_to_cpu;
        _drop;
    }
    size : 512;
}


metadata custom_metadata_t custom_metadata;

action set_nhop(nhop_ipv4, port) {
    modify_field(custom_metadata.nhop_ipv4, nhop_ipv4);
    modify_field(standard_metadata.egress_spec, port);
    add_to_field(ipv4.ttl, -1);
}

action set_dmac(dmac) {
    modify_field(ethernet.dstAddr, dmac);
}

table ipv4_lpm {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
        set_nhop;
        _drop;
    }
    size: 1024;
}

table forward {
    reads {
        custom_metadata.nhop_ipv4 : exact;
    }
    actions {
        set_dmac;
        _drop;
    }
    size: 512;
}


control ingress {
    apply(copy_to_cpu);
    apply(ipv4_lpm);
    apply(forward);
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/


action rewrite_mac(smac) {
    modify_field(ethernet.srcAddr, smac);
}

table send_frame {
    reads {
        standard_metadata.egress_port: exact;
    }
    actions {
        rewrite_mac;
        _drop;
    }
    size: 256;
}

control egress {
    if (standard_metadata.instance_type == 0) {
        apply(send_frame);   
    }

}
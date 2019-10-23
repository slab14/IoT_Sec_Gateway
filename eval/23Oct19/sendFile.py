#!/usr/bin/python

import socket
from time import sleep, time
import threading
import sys, signal
import argparse
import resource

# sample data taken from pcap
header_Ultimaker=['POST /cluster-api/v1/print_jobs/ HTTP/1.1\x0d\x0aHost: 128.2.59.58\x0d\x0aUser-Agent: cura/3.6.0 \x0d\x0aContent-Type: multipart/form-data; boundary="boundary_.oOo._BbaiOpsxyy6L1VZgaq3ithlDSsR0lhG6"\x0d\x0aMIME-Version: 1.0\x0d\x0aContent-Length: 1861148\x0d\x0aConnection: Keep-Alive\x0d\x0aAccept-Language: en-US,*\x0d\x0a\x0d\x0a','--boundary_.oOo._BbaiOpsxyy6L1VZgaq3ithlDSsR0lhG6\x0d\x0aContent-Disposition: form_data; name=require_printer_name\x0d\x0aContent-Type: text/plain\x0d\x0a\x0d\x0aultimakersystem-ccbdd3003622\x0d\x0a--boundary_.oOo._Bbai0psxyy6L1VZgaq3ithlDSsR0lhG6\x0d\x0aContent-Disposition: form_data; name=owner\x0d\x0aContent-Type: text/plain\x0d\x0a\x0d\x0amattmcc\x0d\x0a--boundary_.oOo._Bbai0psxyy6L1VZgaq3ithlDSsR0lhG6\x0d\x0aContent-Disposition: form_data; name="file"; filename=" UM3E_3DBenchy.gcode.gz"\x0d\x0a\x0d\x0a']

closer_Ultimaker=['\x0d\x0a--boundary_.oOo._Bbai0psxyy6L1VZgaq3ithlDSsR0lhG6\x0d\x0a']


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--ipaddr', '-i', required=False, type=str)
    parser.add_argument('--port', '-p', required=False, type=int)
    parser.add_argument('--num', '-n', required=False, type=int)
    parser.add_argument('--Finder', default=False, action='store_true')
    parser.add_argument('--Form2', default=False, action='store_true')
    parser.add_argument('--Ultimaker', default=False, action='store_true')
    parser.add_argument('--F170', default=False, action='store_true')
    parser.add_argument('--EOS', default=False, action='store_true')
    parser.add_argument('--Dremel', default=False, action='store_true')
    parser.add_argument('--RCBI_Dim', default=False, action='store_true')
    parser.add_argument('--RCBI_Maker', default=False, action='store_true')
    parser.add_argument('--RCBI_zPrint', default=False, action='store_true')
    parser.add_argument('--RCBI_Fortus', default=False, action='store_true')
    args=parser.parse_args()

    if args.num==None:
        num_connections=1
    else:
        num_connections = args.num

    if not args.Finder and not args.Form2 and not args.Ultimaker and not args.F170 and not args.EOS and not args.RCBI_Dim and not args.RCBI_Maker and not args.RCBI_Fortus and not args.RCBI_zPrint:
        if args.ipaddr==None or args.port==None:
            print("Error: Must specify an IP and port")
            sys.exit

    if args.Finder:
        ip='192.168.0.222'
        port=8899
    elif args.Form2:
        ip='169.254.250.175'
        port=35
    elif args.Ultimaker:
        ip='128.2.59.58'
        port=80
    elif args.F170:
        ip='172.22.23.177'
        port=53742
    elif args.Dremel:
        ip='10.1.1.36'
        port=80
    elif args.RCBI_Dim:
        ip='10.6.10.219'
        port=53742
        data=sample_RCBI_Dim
    elif args.RCBI_Maker:
        ip='10.6.10.134'
        port=9999
    elif args.RCBI_zPrint:
        ip='10.6.10.148'
        port=35001
    elif args.RCBI_Fortus:
        ip='10.6.30.85'
        port=53742
    elif args.DEMO:
        ip='169.254.118.62'
        port=80
    else:
        ip=args.ipaddr
        port=args.port

    boat_data=[]
    with open('/Users/mattmcc/Code/NextManufacturingCenter/Defense/plots/data/testCase/boat.gz', 'r') as f:
        for line in f:
            boat_data.append(line)

    print "starting..."
    start_time=time()
    print(start_time)

    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((args.ip, args.port))
    print "Connection Setup" 
    s.send(header_Ultimaker[0])
    response=s.recv(8192)
    s.send(header_Ultimaker[1]+goad_data+closer_Ultimaker)
    response=s.recv(8192)
    s.close()

    end_time=time()
    total_time=end_time-start_time
    print "All Threads Done!"
    print(total_time)

if __name__=='__main__':
    main()

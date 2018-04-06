import argparse
import ipaddress
import shlex
import subprocess

IP_BASE='10.1.1.2'
INTERFACE='enp6s0f0'

def bind_interface(interface, ip):
    cmd='/usr/bin/sudo /sbin/ip addr add {}/16 dev {}'
    cmd=cmd.format(ip, interface)
    subprocess.call(shlex.split(cmd))

def main():
    parser=argparse.ArgumentParser(description='bind additional IP addresses')
    parser.add_argument('--number', '-n', required=True, type=int)
    args = parser.parse_args()
    try:
        base_ip=ipaddress.ip_address(unicode(IP_BASE))
    except:
        print("Invalid ip address: {}".format(IP_BASE))
        sys.exit
    ip_list=[base_ip + i for i in range(args.number)]
    for ip in ip_list:
        bind_interface(INTERFACE, ip)


if __name__=='__main__':
    main()

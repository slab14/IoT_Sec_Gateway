#!/usr/bin/env python                          

import argparse
import shlex
import subprocess
import ipaddress
import re
import random

import threading

BASE_IP='10.1.1.2'
NUM_PINGS=3200

def get_ip_range(base_ip, num):
    try:
        base_ip = ipaddress.ip_address(unicode(base_ip))
    except:
        print('Invalid ip address: {}'.format(base_ip))
    ips = [base_ip + i for i in range(num)]
    return ips

def first_and_last(input_list, value):
    result=[input_list[0], input_list[(value-1)]]
    return result

def setup_output_files(file, ip):
    ip_string=str(ip)
    sub_ip=ip_string.split('.')
    o_str='{}/out{}.txt'.format(file, sub_ip[3])
    return o_str

def calc_count(num):
    c_param=NUM_PINGS//num
    return c_param

def determine_args(ip_list, num):
    begin_end=first_and_last(ip_list, num)
    c_param=calc_count(num)
    result=[c_param]+begin_end
    return result

def format_test_cmd(folder, ip_list, num):
    variables=determine_args(ip_list, num)
    cmd='/usr/bin/fping -R -p 20 -b 20 -s -C {} -g {} {} >> {}'
    cmd=cmd.format(variables[0], variables[1], variables[2], folder)
    return cmd

def main():
    parser=argparse.ArgumentParser(description='Run N simultaneous ping tests/requrests')
    parser.add_argument('--number', '-n', required=True, type=int)
    parser.add_argument('--output', '-o', required=True, type=str)
    args=parser.parse_args()
    test_ips = get_ip_range(BASE_IP, int(args.number))
    test_arg=format_test_cmd(args.output, test_ips, args.number)
    subprocess.check_output(test_arg, shell=True)


if __name__=='__main__':
    main()



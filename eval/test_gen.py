#!/usr/bin/env python

import argparse
import shlex
import subprocess

#CON_NUMS=[1, 2, 4, 8, 16, 32, 64, 128, 200, 250]
CON_NUMS=[1,2,4,8,16,32,64,128,200]

def run_test(number,output):
    cmd='python multi_ping3.py -n {} -o {}'
    cmd=cmd.format(number, output)
    subprocess.check_call(shlex.split(cmd))

def name_gen(output):
    new_out=[]
    for i in CON_NUMS:
        temp_str='{}/test{}'.format(output, i)
        new_out.append(temp_str)
    return new_out
        
def main():
    parser=argparse.ArgumentParser(description='Run a sequence of multi-ping ttests to generate latency data')
    parser.add_argument('--output', '-o', required=True, type=str)
    args=parser.parse_args()
    #labels=name_gen(args.output)
    for i in range(0,len(CON_NUMS)):
        #run_test(CON_NUMS[i], labels[i])
        run_test(CON_NUMS[i], args.output)

if __name__=='__main__':
    main()


#!/usr/bin/env python
from __future__ import division
import argparse
import shlex
import subprocess
import csv

CON_NUMS=[1,2,4,8,16,32,64,128,200]

def mean(a):
    return sum(a) / len(a)

def name_gen(output):
    new_out=[]
    for i in CON_NUMS:
        temp_str='{}/raw{}.txt'.format(output, i)
        new_out.append(temp_str)
    return new_out

def get_ping_val(fname):
    cmd="grep '(avg ' {}".format(fname)
    cmd=cmd+"| awk '{ print $1 }'"
    avg=subprocess.check_output(cmd, shell=True)
    avg_result=avg.encode('utf-8')
    avg_result=avg_result.split("\n")
    avg_result=avg_result[0]
    cmd="grep '(min ' {}".format(fname)
    cmd=cmd+"| awk '{ print $1 }'"
    min_rtt=subprocess.check_output(cmd, shell=True)
    min_result=min_rtt.encode('utf-8')
    min_result=min_result.split("\n")
    min_result=min_result[0]
    cmd="grep '(max ' {}".format(fname)
    cmd=cmd+"| awk '{ print $1 }'"
    max_rtt=subprocess.check_output(cmd, shell=True)
    max_result=max_rtt.encode('utf-8')
    max_result=max_result.split("\n")
    max_result=max_result[0]
    result = [avg_result, min_result, max_result]
    return result

def parse_return(val):
    val=val[:-3]
    result=val.split('/')
    return result

def gen_output(fname):
    fname2=fname[:-4]
    temp_str=fname2.split('/')
    ping_val=get_ping_val(fname)
    if ping_val == None:
        return None
    result=temp_str+ping_val
    return result
    
def header():
    result=["folder", "# of cont", "average", "min", "max"]
    return result

def main():
    parser=argparse.ArgumentParser(description='Gather output from tests')
    parser.add_argument('--folder','-f',required=True,type=str)
    parser.add_argument('--output','-o',required=True,type=str)
    args=parser.parse_args()
    labels=name_gen(args.folder)
    with open(args.output, 'wb') as f:
        writer=csv.writer(f)
        writer.writerow(header())
        for i in labels:
            writer.writerow(gen_output(i))

            
if __name__=='__main__':
    main()


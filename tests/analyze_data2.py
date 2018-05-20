#!/usr/bin/env python
from __future__ import division
import argparse
import shlex
import subprocess
import csv
#import numpy


#CON_NUMS=[1,2,4,8,16,32,64,128,200,250]
CON_NUMS=[1,2,4,8,16,32,64]

def mean(a):
    return sum(a) / len(a)

def name_gen(output):
    new_out=[]
    for i in CON_NUMS:
        for j in range(0,i):
            temp_str='{}/test{}/out{}.txt'.format(output, i, (j+2))
            new_out.append(temp_str)
    return new_out

def get_ping_val(fname):
    cmd="grep 'avg' {}".format(fname)
    cmd=cmd+"| awk -F '= ' '{ print $2 }'"
    val=subprocess.check_output(cmd, shell=True)
    result=val.decode()
    result=result.split("\n")
    agg=[]
    for i in result:
        agg.append(parse_return(i))
    agg=agg[:-1]
    for i in range(0,len(agg)):
        agg[i]=list(map(float,agg[i]))
    #avg=numpy.array(agg)
    #numpy.mean(avg,axis=0)
    avg=list(map(mean,zip(*agg)))
    ['{:.4f}'.format(x) for x in avg]
    return avg

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
    
def header(fname):
    fname2=fname[:-4]
    temp_str=fname2.split('/')
    for i in range(0,len(temp_str)):
        temp_str[i]=temp_str[i][:-1]
        if i>0:
            temp_str[i]=temp_str[i]+'#'
    cmd="grep 'avg' {}".format(fname)
    cmd=cmd+"| awk -F ' = ' '{ print $1 }'"
    val=subprocess.check_output(cmd, shell=True)
    headers=val.decode()
    headers=headers.split("\n")
    headers=headers[0]
    headers=headers[4:]
    headers=headers[:-1]
    headers2=headers.split('/')
    result=temp_str+headers2
    return result

def main():
    parser=argparse.ArgumentParser(description='Gather output from tests')
    parser.add_argument('--folder','-f',required=True,type=str)
    parser.add_argument('--output','-o',required=True,type=str)
    args=parser.parse_args()
    labels=name_gen(args.folder)
    with open(args.output, 'w', newline='') as f:
        writer=csv.writer(f)
        writer.writerow(header(labels[0]))
        for i in labels:
            writer.writerow(gen_output(i))

            
if __name__=='__main__':
    main()


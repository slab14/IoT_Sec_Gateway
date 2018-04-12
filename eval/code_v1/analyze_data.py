#!/usr/bin/env python

import argparse
import shlex
import subprocess
import csv

CON_NUMS=[1,2,4,8,16,32,64,128,250]
#CON_NUMS=[1,2,4,8,16,32,64,128,200]

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
    return result

def parse_return(val):
    val=val[:-3]
    result=val.split('/')
    return result

def gen_output(fname):
    fname2=fname[:-4]
    temp_str=fname2.split('/')
    ping_val=parse_return(str(get_ping_val(fname)))
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
    with open(args.output, 'wb') as f:
        writer=csv.writer(f)
        writer.writerow(header(labels[0]))
        for i in labels:
            writer.writerow(gen_output(i))

    

if __name__=='__main__':
    main()


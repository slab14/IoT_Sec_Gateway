#!/usr/bin/python

import argparse
import re
from os import listdir
from os.path import isfile, join

def getData(fileDir, name=None):
    dataFiles=[]
    onlyfiles = [f for f in listdir(fileDir) if isfile(join(fileDir, f))]
    for fileName in onlyfiles:
        if re.search(name, fileName):
            dataFiles.append(fileName)
    data=[]
    for dataFile in dataFiles:
        with open((fileDir+'/'+dataFile), 'r') as f:
            for line in f:
                if re.match('-',line):
                    break
                if re.search('onnect', line):
                    continue
                elif re.search('Interval', line):
                    continue
                temp=line.split('sec ')[1].split('Bytes')[1].split(' Mbits')[0]
                data.append(float(temp))
    return data

def getAverage(data):
    return sum(data)/len(data)

def getMedian(lst):
    n = len(lst)
    s = sorted(lst)
    return (sum(s[n//2-1:n//2+1])/2.0, s[n//2])[n % 2] if n else None

def getStdDev(data):
    mean=getAverage(data)
    variance = sum([((x - mean) ** 2) for x in data]) / len(data)
    return variance ** 0.5

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--path', '-P', required=True, type=str, help='path to where files are located')
    parser.add_argument('--name', '-N', required=True, type=str, help='Name identifire in file name for group to be conslidated')

    args=parser.parse_args()

    data=getData(args.path, args.name)
    print("Average (Mbps), Standard Deviation, Median (Mbps)")
    print(getAverage(data), getStdDev(data), getMedian(data))
    
    
if __name__=='__main__':
    main()

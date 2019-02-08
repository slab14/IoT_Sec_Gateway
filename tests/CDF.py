import argparse
import re
import numpy as np
import matplotlib.pyplot as plt
from itertools import cycle

def calc_sum(data):
    numTests=0
    for line in data:
        if (re.match("----",line)):
            numTests+=1
    count=0
    tmp=0
    i=0
    total=numTests*[None]
    for line in data:
        if line[0]!="-":
            line=line.split(" ")
            tmp+=float(line[-4])
        else:
            total[i]=tmp
            tmp=0
            i+=1
#    return total
    print(total)


    
def calc_med(data):
    numTests=0
    for line in data:
        if (re.match("----", line)):
            numTests+=1
    count=0
    tmp=[None]
    i=0
    latency=numTests*[None]
    for line in data:
        if (re.match("----",line)):
            latency[i]=median(tmp)
            tmp=[None]
            i+=1
        elif re.match('connected', line):
            line=line.split(" ")
            val = line[-3].split('=')[-1]
            if(val!=None):
                tmp.append(float(line[-3].split('=')[-1]))
#    return(median50, median90, median99)
    print(latency)

def calc_cdf(data):
    numTests=0
    for line in data:
        if (re.match("----", line)):
            numTests+=1
    count=0
    tmp=[]
    i=0
    tests=numTests*[None]
    for line in data:
        if (re.match("----",line)):
            tests[i]=tmp
            tmp=[]
            i+=1
        elif re.match('connected', line):
            line=line.split(" ")
            val = line[-3].split('=')[-1]
            if(val!=None):
                tmp.append(float(line[-3].split('=')[-1]))
    ## Merge data
    usefulData = []
    for i in tests:
        usefulData+=i
    sortedData = sorted(usefulData)
    yvals = range(0, len(sortedData))
    for y in range(0,len(yvals)):
        yvals[y] = float(y)/len(sortedData)
    plt.plot(sortedData,yvals)
    plt.show()


def get_useful(data):
    numTests=0
    for line in data:
        if (re.match("----", line)):
            numTests+=1
    count=0
    tmp=[]
    i=0
    tests=numTests*[None]
    for line in data:
        if (re.match("----",line)):
            tests[i]=tmp
            tmp=[]
            i+=1
        elif re.match('connected', line):
            line=line.split(" ")
            val = line[-3].split('=')[-1]
            if(val!=None):
                tmp.append(float(line[-3].split('=')[-1]))
    ## Merge data
    usefulData = []
    for i in tests:
        usefulData+=i
    sortedData = sorted(usefulData)
    yvals = range(0, len(sortedData))
    for y in range(0,len(yvals)):
        yvals[y] = float(y)/len(sortedData)
    return (sortedData, yvals)

def print_cdf(sortedDataList, yvalsList, labels=None):
    plt.clf()
    lines = ["-","--","-.",":"]
    linecycler = cycle(lines)
    plt.figure()
    if all(isinstance(elem, list) for elem in sortedDataList):
        for i in range(0,len(sortedDataList)):
            sortedData=sortedDataList[i]
            yvals=yvalsList[i]
            if labels[i] != None:
                labelVal = labels[i]
                plt.plot(sortedData,yvals,next(linecycler),label=labelVal)
            else:
                plt.plot(sortedData,yvals)
    else:
        plt.plot(sortedDataList, yvalsList)
    plt.legend()
    plt.xlabel("Latency (ms)")
    plt.ylabel("Fraction of Data")
    plt.show()

    
def median(lst):
    n = len(lst)
    if n < 1:
            return None
    if n % 2 == 1:
            return sorted(lst)[n//2]
    else:
            return sum(sorted(lst)[n//2-1:n//2+1])/2.0

def read_file(filename):
    with open(filename) as f:
        data = []
        for line in f:
            data.append(line)
    return data


def get_cdf_data(folder, filenameList):
    newFilenameList=[]
    for i in filenameList:
        newFilenameList.append(i.rstrip())
    newFolder=""
    if(len(folder) > 1):
        for i in range(0,len(folder)-1):
            newFolder+=folder[i]+"/"
    numFiles = len(filenameList)
    xsList = [None]*numFiles
    ysList = [None]*numFiles
    
    for i in range(0, numFiles):
        filename=newFolder+"/"+newFilenameList[i]
        data = read_file(filename)
        xs, ys = get_useful(data)
        xsList[i] = xs
        ysList[i] = ys
    return (xsList, ysList)
        
def get_folder(str):
    return str.split("/")

def get_labels(labelFile):
    labels = read_file(labelFile)
    newLabels=[]
    for i in range(0, len(labels)):
        labels[i]=labels[i].rstrip()
        labels[i]=labels[i].split(".")[0]
        #labels[i]=labels[i].split("_")[0]
    return labels


def main():
    parser = argparse.ArgumentParser(description='process test data')
    parser.add_argument('--file', '-f', required=True, type=str)
    args = parser.parse_args()
    folder = get_folder(args.file)
    fileList=read_file(args.file)
    xs, ys = get_cdf_data(folder, fileList)
    plotLabels = get_labels(args.file)
    print_cdf(xs, ys, plotLabels)
    
#    data = read_file(args.file)
#    xs, ys = get_useful(data)
#    print_cdf(xs, ys)

#        calc_med(data)
#        out = calc_med(data)

#    print(out)

if __name__=='__main__':
    main()

                

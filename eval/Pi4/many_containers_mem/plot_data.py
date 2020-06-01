import numpy as np
import matplotlib.pyplot as plt
import re
import argparse

def getData(fileName):
    with open(fileName, 'r') as f:
        data=f.readlines()
    f.close()
    cleanData=[x.strip() for x in data]
    return cleanData

def parseData(dataIn):
    catData=[]
    dataOut=[]
    for line in dataIn:
        if re.search('-----', line):
            num=line.split(' ')[1]
        else:
            catData.append(num + ' ' + line)
    for line in catData:
        dataOut.append(line.split(' '))
    return dataOut

def genPlotData(data, xPos, yPos):
    ## Data positions
    # 0 - num containers,
    xVals=[]
    yVals=[]
    for line in data:
        xVals.append(int(line[xPos]))
        yVals.append(int(line[yPos]))
    X=np.asarray(xVals)
    Y=np.asarray(yVals)
    return (X,Y)

def calcSlope(X,Y):
    ##Assumes linear
    slope, intercept = np.polyfit(X, Y, 1)
    return (slope, intercept)
    

def main():
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('--inputFile', '-i', required=True, type=str, help='path to file')
    args=parser.parse_args()
    rawData=getData(args.inputFile)
    parsedData=parseData(rawData)
    (X,Y)=genPlotData(parsedData, 0, 13)
    slope,intercept=calcSlope(X,Y)
    print(slope, intercept)
    plt.plot(X, Y)
    xAxis=X[0::10]
    yAxis=Y[0::10]
    plt.xticks(xAxis)
    plt.yticks(yAxis)
    plt.show()
    


if __name__=='__main__':
    main()

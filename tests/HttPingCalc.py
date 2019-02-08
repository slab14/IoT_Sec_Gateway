import argparse
import re

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
    tmp=[]
    total=[]
    i=0
    latency=numTests*[None]
    for line in data:
        if (re.match("----",line)):
            total+=tmp
            latency[i]=median(tmp)
            tmp=[]
            i+=1
        elif re.match('connected', line):
            line=line.split(" ")
            val = line[-3].split('=')[-1]
            if(val!=None):
                tmp.append(float(line[-3].split('=')[-1]))
    print(median(total))
    print(latency)

def median(lst):
    n = len(lst)
    if n < 1:
            return None
    if n % 2 == 1:
            return sorted(lst)[n//2]
    else:
            return sum(sorted(lst)[n//2-1:n//2+1])/2.0
    
def main():
    parser = argparse.ArgumentParser(description='process test data')
    parser.add_argument('--file', '-f', required=True, type=str)
    args = parser.parse_args()
    with open(args.file) as f:
        data = []
        for line in f:
           data.append(line)
        calc_med(data)
#        out = calc_med(data)

#    print(out)

if __name__=='__main__':
    main()

                

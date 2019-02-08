import argparse

def calc_sum(data):
    numTests=0
    for line in data:
        if (line[0]=="-"):
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
        if (line[0]=="-"):
            numTests+=1
    count=0
    tmp50=[None]
    tmp90=[None]
    tmp99=[None]   
    i=0
    median50=numTests*[None]
    median90=numTests*[None]
    median99=numTests*[None]    
    for line in data:
        if line[0]!="-":
            line=line.split(",")
            tmp50.append(float(line[0]))
            tmp90.append(float(line[1]))
            tmp99.append(float(line[2]))
        else:
            median50[i]=median(tmp50)
            median90[i]=median(tmp90)
            median99[i]=median(tmp99)            
            tmp50=[None]
            tmp90=[None]
            tmp99=[None]            
            i+=1
#    return(median50, median90, median99)
    print(median50, median90, median99)

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
    parser.add_argument('--type', '-t', required=True, type=str)
    args = parser.parse_args()
    with open(args.file) as f:
        data = []
        for line in f:
            data.append(line)
    if (args.type=="bandwidth"):
        out = calc_sum(data)
    elif (args.type=="latency"):
        out = calc_med(data)
#    print(out)

if __name__=='__main__':
    main()

                

# -*- coding: utf-8 -*-

import argparse
import re

class FSM():
    """This class represents the FSM read from model. It contains the states, initial state and transition matrix."""
    def __init__(self, states, transMatrix, initial, protofile):
        self.states = states
        self.transMatrix = transMatrix
        self.initial = initial
        self.proto = {}
        self.out = {}
        self.inLen = {}
        self.outLen = {}
        # need for snort rule IDs
        self.rule_id = 1000000
        #check if initial state is in states
        if self.initial not in self.states:
            print("WARNING: Initial state not found.")
        else:
            self.init_id = self.states.index(initial)
        #check if matrix has correct dimensions
        if len(self.transMatrix) != len(self.states):
            print("WARNING: Invalid matrix size (# rows).")
        for i, row in enumerate(self.transMatrix):
            if len(row) != len(self.states):
                print(f"WARNING: Invalid matrix size (# cols in row {i}).")
        self.protofile=protofile
        self.readContent()
        self.SERVER_PORT=''
        self.GROUPNAME=''
        self.tranState=0
        
    def __repr__(self):
        v = "\n".join(str(r) for r in self.transMatrix)
        return f'''\
States: {" ".join(self.states)}
Transitions:
{v}
Initial state: {self.initial}
'''

    def getNewRuleID(self):
        out = self.rule_id
        self.rule_id+=1
        return out
    
    def resetTranState(self):
        self.tranState=0

    def getAndIncTranState(self):
        out = self.tranState
        self.tranState+=1
        return out

    def setGroupName(self, name):
        self.GROUPNAME=name

    def getIndex(self, sid, tid):
        return self.transMatrix[sid][tid]
    
    def readContent(self):
        """This function reads the protocol specifications and fill self.proto"""
        with open(self.protofile, "r") as f:
            inP = False
            outP = False
            while True:
                line = f.readline()
                if (len(line) == 0):
                    break
                elif (line[0]=='#'):
                    if re.search("input", line):
                        inP=True
                        outP = False
                    elif re.search("output", line):
                        outP = True
                        inP = False
                    continue
                line = line.rstrip('\n')
                contents = line.split(' - ')
                if (len(contents) < 3):
                    print("WARNING: Protocol specification in the wrong format.")
                    break
                if inP:
                    self.proto[contents[0]] = contents[1]
                    self.inLen[contents[0]] = int(contents[2])
                elif outP:
                    self.out[contents[0]] = contents[1]
                    lenRange=contents[2].split(',')
                    if (int(lenRange[0]) == int(lenRange[1])):
                        self.outLen[contents[0]] = [int(lenRange[0])]
                    else:
                        self.outLen[contents[0]] = [int(lenRange[0]),int(lenRange[1])]

    def generateStateFlowbitsOptions(self, sid, tid, transit=False, final=False):
        #initial transition from state S -> T
        out=''
        if ((not transit) and (not final)):
            # Generate the flowbits rule to check if in state S
            if sid == self.init_id:
                s_bits = f'isnotset,any,{self.GROUPNAME}'
            else:
                s_bits = f'isset,{self.states[sid]}'
            # Generate the flowbits rule to set state T
            if tid == self.init_id:
                t_bits = f'unset,all,{self.GROUPNAME}'
            else:
                t_bits = f'setx,{self.states[sid]}.xfer,{self.GROUPNAME}'
            out = f'flowbits:{s_bits};flowbits:{t_bits};'
        # Part-way through transition from S->T
        elif transit:
            s_bits = f'isset,{self.states[sid]}.xfer'
            out = f'flowbits:{s_bits};'
        # Final step before transition is complete to T
        elif final:
            s_bits = f'isset,{self.states[sid]}.xfer'
            t_bits = f'setx,{self.states[tid]},{self.GROUPNAME}'
            out = f'flowbits:{s_bits};flowbits:{t_bits};'
        return out

    def generateTransitFlowbits(self, init=False, mult=False):
        out=''
        if init:
            self.resetTranState()
            out = f'flowbits:setx,t{self.getAndIncTranState()},delta;'
        else:
            state = self.getAndIncTranState()
            priorState=state-1
            out = f'flowbits:isset,t{priorState};'
            if mult:
                out += f'flowbits:set,t{state},delta;'
            else:
                out+= f'flowbits:setx,t{state},delta;'
        return out
    
    def generateContent(self, sid, tid): 
        return self.proto[self.getIndex(sid,tid)]

    def generateResponseContent(self, sid, tid): 
        return self.out[self.getIndex(sid,tid)]    

    def generateHeader(self, read, tcp=False):
        server = f'any {self.SERVER_PORT}'
        client = f'any any'
        msgType = f'ip'
        if tcp:
            msgType = f'tcp'
        if read:
            return f'pass {msgType} {client} -> {server}'
        else:
            return f'pass {msgType} {server} -> {client}'

    def generateRule(self, sid, tid, input=True):
        rule_id = f'sid:{self.getNewRuleID()};'
        addPkt=False
        if (self.inLen[self.getIndex(sid,tid)]!=0):
            addPkt=True
        # Initial rule for starting state transitions (request)
        content = self.generateContent(sid, tid)
        stateFlowbits = self.generateStateFlowbitsOptions(sid, tid)
        transFlowbits = self.generateTransitFlowbits(True)
        header = self.generateHeader(True)
        rules = f'{header} ({content}{stateFlowbits}{transFlowbits}{rule_id})\n'
        # check if additional packets are expected in request
        if (addPkt):
            if (self.inLen[self.getIndex(sid,tid)]>1460):
                size = f'dsize:>0;'
                transFlowbits = self.generateTransitFlowbits(mult=True)
            else:
                size = f'dsize:{self.inLen[self.getIndex(sid,tid)]};'
                transFlowbits = self.generateTransitFlowbits()
            rule_id = f'sid:{self.getNewRuleID()};'                
            stateFlowbits = self.generateStateFlowbitsOptions(sid, tid, transit=True)
            rules += f'{header} ({size}{stateFlowbits}{transFlowbits}{rule_id})\n'
        # Handle reply
        content = self.generateResponseContent(sid, tid)
        if (addPkt):        
            stateFlowbits = self.generateStateFlowbitsOptions(sid, tid, transit=True)
        else:
            stateFlowbits = self.generateStateFlowbitsOptions(sid, tid, final=True)            
        transFlowbits = self.generateTransitFlowbits()
        header = self.generateHeader(False)
        rule_id = f'sid:{self.getNewRuleID()};'        
        rules += f'{header} ({content}{stateFlowbits}{transFlowbits}{rule_id})\n'
        # additional reply packets
        if (addPkt):
            size=''
            limit=self.outLen[self.getIndex(sid,tid)]
            if len(limit)>1:
                limit[0]=int(round(limit[0]*.8))
                limit[1]=int(round(limit[1]*1.2))                
                size = f'dsize:{limit[0]}<>{limit[1]};'
            else:
                size = f'dsize:{limit[0]};'
            stateFlowbits = self.generateStateFlowbitsOptions(sid, tid, final=True)            
            transFlowbits = self.generateTransitFlowbits()
            header = self.generateHeader(False)
            rule_id = f'sid:{self.getNewRuleID()};'            
            rules += f'{header} ({size}{stateFlowbits}{transFlowbits}{rule_id})'
        return rules

    
    def allowSYN(self):
        #allow client to send SYN packets to server
        rule_id = f'sid:{self.rule_id};'
        self.rule_id += 1
        header = self.generateHeader(True, True)
        return f'{header} (flags:S,CE; dsize:0; {rule_id})' 

    def allowSYNACK(self):
        #allow server to send SYN ACK to client
        rule_id = f'sid:{self.rule_id};'        
        self.rule_id += 1        
        header = self.generateHeader(False, True)
        return f'{header} (flags:SA,CE; dsize:0; {rule_id})'    

    def allowACKs(self):
        #allow client and server to send ACK
        rule_id = f'sid:{self.rule_id};'        
        self.rule_id += 1
        header = 'pass tcp any any <> any any'        
        return f'{header} (flags:A; dsize:0; {rule_id})' 

    def allowFIN(self):
        #allow client/server to send FIN
        rule_id = f'sid:{self.rule_id};'        
        self.rule_id += 1
        header = 'pass tcp any any <> any any'        
        return f'{header} (flags:FA; dsize:0; {rule_id})'     

    def dropAll(self):
        #add drop all traffic not allowed
        rule_id = f'sid:{self.rule_id};'        
        self.rule_id += 1
        header = 'drop ip any any <> any any'
        return f'{header} (msg:\"drop all\";{rule_id})'

    def addOut(self):
        rule_id = f'sid:{self.rule_id};'        
        self.rule_id += 1        
        header = self.generateHeader(False)
        content = self.out
        rule1 = f'{header} ({content} flowbits:set,o1,{self.GROUPNAME}; {rule_id})'
        rule_id2 = f'sid:{self.rule_id};'        
        self.rule_id += 1
        rule2 = f'{header} (flowbits:isset,o1; {rule_id2})'
        return f'{rule1}\n{rule2}'
    
    def generateAllRules(self, outfile):
        #generate rules based on FSM
        rules=[]
        for sid, row in enumerate(self.transMatrix):
            for tid, v in enumerate(row):
                if v:
                    newRules = self.generateRule(sid, tid).split("\n")
                    for newRule in newRules:
                        if outfile==None:
                            print(newRule)
                        else:
                            rules.append(newRule)
        #allow client to send SYN to server to enable connection
        if outfile==None:
            print(self.allowSYN())
            print(self.allowSYNACK())
            print(self.allowACKs())
            print(self.allowFIN())            
            #print(self.addOut())
            print(self.dropAll())
        else:
            rules.append(self.allowSYN())
            rules.append(self.allowSYNACK())
            rules.append(self.allowACKs())
            rules.append(self.allowFIN())            
            #rules.append(self.addOut())
            rules.append(self.dropAll())
        #check for duplicates
        reducedRules=[]
        rules2Check=[]
        for rule in rules:
            checkRule=rule.split("sid:")
            if checkRule[0] not in rules2Check:
                rules2Check.append(checkRule[0])
                reducedRules.append(rule)
        with open(outfile, 'w') as f:
            for rule in reducedRules:
                f.write(rule+"\n")
            

    def setServerPort(self, port):
        self.SERVER_PORT=port


def readModel(fModel, protofile):
    """This function reads the model file and generate a FSM class out of it.""" 
    states = []
    transMatrix = []
    initstate=''
    with open(fModel, 'r') as f:
        while True:
            line = f.readline()
            if len(line) == 0:
                break
            line = line.rstrip('\n')
            if line == "states":
                nextline = f.readline()
                nextline = nextline.rstrip('\n')
                states = nextline.split(",")
                m = len(states)
                for i in range(m):
                    transMatrix.append([""] * m)
            if line == "#initial":
                nextline = f.readline()
                nextline = nextline.rstrip('\n')
                initstate = nextline
            if line == "#transitions":
                nextline = f.readline()
                nextline = nextline.rstrip('\n')
                transitions = nextline.split(",")
                for text in transitions:	
                    transition = text.split(">")
                    s = transition[0]
                    v = transition[1]
                    t = transition[2]
                    sid = states.index(s)
                    tid = states.index(t)
                    transMatrix[sid][tid] = v
    return FSM(states, transMatrix, initstate, protofile)



    
def main():
    parser=argparse.ArgumentParser(description='Connect container to vswitch')
    parser.add_argument('--model', '-M', required=True, type=str)
    parser.add_argument('--proto', '-P', required=True, type=str)
    parser.add_argument('--port', '-s', required=True, type=str)
    parser.add_argument('--name', '-n', required=True, type=str)        
    parser.add_argument('--rules', '-R', required=False, type=str)        
    args=parser.parse_args()

    F = readModel(args.model, args.proto)
    print(F)
    F.setServerPort(args.port)
    F.setGroupName(args.name)    
    F.generateAllRules(args.rules)


    

if __name__=='__main__':
    main()


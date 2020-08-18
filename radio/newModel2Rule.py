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
        self.out = ''
        
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
        
    def __repr__(self):
        v = "\n".join(str(r) for r in self.transMatrix)
        return f'''\
States: {" ".join(self.states)}
Transitions:
{v}
Initial state: {self.initial}
'''


    def setGroupName(self, name):
        self.GROUPNAME=name
    
    def generateFlowbitsOptions(self, sid, tid):
        # Generate the flowbits rule to check if in state S
        if sid == self.init_id:
            s_bits = f'isnotset,any,{self.GROUPNAME}'
        else:
            s_bits = f'isset,{self.states[sid]},{self.GROUPNAME}'
        
        # Generate the flowbits rule to set state T
        if tid == self.init_id:
            t_bits = f'unset,all,{self.GROUPNAME}'
        else:
            t_bits = f'setx,{self.states[tid]},{self.GROUPNAME}'
        
        return f'flowbits:{s_bits};flowbits:{t_bits};'
        
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
                if inP:
                    contents = line.split(' - ')
                    if (len(contents) < 2):
                        print("WARNING: Protocol specification in the wrong format.")
                        break
                    self.proto[contents[0]] = contents[1]
                elif outP:
                    self.out = line

    def generateContent(self, sid, tid): 
        content = ''
        for entry in self.proto:
            if entry in self.transMatrix[sid][tid]:
                content += self.proto[entry]
        return content

    def generateHeader(self, read):
        server = f'any {self.SERVER_PORT}'
        client = f'any any'
        if read:
            return f'pass tcp {client} -> {server}'
        else:
            return f'pass tcp {server} -> {client}'

    def generateRule(self, sid, tid, input=True):
        content = self.generateContent(sid, tid)
        flowbits = self.generateFlowbitsOptions(sid, tid)
        rule_id = f'sid:{self.rule_id};'
        
        self.rule_id += 1

        header = self.generateHeader(True)
        return f'{header} (flow:established;{content}{flowbits}tag:session,exclusive;{rule_id})' 
        '''
        #Assume transitions that contains read is query from client to server, transition that contains
        #response is from server to client
        if "Query" in self.transMatrix[sid][tid]:
            header = self.generateHeader(True)
            return f'{header} (flow:established;{content}{flowbits}tag:session,exclusive;{rule_id})' 
        elif "Response" in self.transMatrix[sid][tid]:
            header = self.generateHeader(False)
            return f'{header} (flow:established;{content}{flowbits}tag:session,exclusive;{rule_id})' 
        else:
            print("WARNING: Protocal specification in wrong format, cannot decide direction of flow.")
            return ''
        '''
    
    def allowSYN(self):
        #allow client to send SYN packets to server
        rule_id = f'sid:{self.rule_id};'
        self.rule_id += 1
        header = self.generateHeader(True)
        return f'{header} (flags:S;{rule_id})' 

    def allowFIN(self):
        #allow client to send FIN to client
        rule_id = f'sid:{self.rule_id};'        
        self.rule_id += 1        
        header = self.generateHeader(True)
        return f'{header} (flags:AF;{rule_id})' 

    def allowSYNACK(self):
        #allow server to send SYN ACK to client
        rule_id = f'sid:{self.rule_id};'        
        self.rule_id += 1        
        header = self.generateHeader(False)
        return f'{header} (flags:SA;{rule_id})'    

    def dropAll(self):
        #add drop all traffic not allowed
        rule_id = f'sid:{self.rule_id};'        
        self.rule_id += 1
        header = 'drop tcp any any <> any any'
        return f'{header} (msg:\"drop all\";{rule_id})'

    def addOut(self):
        rule_id = f'sid:{self.rule_id};'        
        self.rule_id += 1        
        header = self.generateHeader(False)
        content = self.out
        return f'{header} (flow:established;{content}{rule_id})'
    
    def generateAllRules(self, outfile):
        #generate rules based on FSM
        rules=[]
        for sid, row in enumerate(self.transMatrix):
            for tid, v in enumerate(row):
                if v:
                    if outfile==None:
                        print(self.generateRule(sid, tid))
                    else:
                        rules.append(self.generateRule(sid, tid))
        #allow client to send SYN to server to enable connection
        if outfile==None:
            print(self.allowSYN())
            print(self.allowFIN())
            print(self.allowSYNACK())
            print(self.dropAll())
        else:
            rules.append(self.allowSYN())
            rules.append(self.allowFIN())
            rules.append(self.allowSYNACK())
            rules.append(self.dropAll())
        with open(outfile, 'w') as f:
            for rule in rules:
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


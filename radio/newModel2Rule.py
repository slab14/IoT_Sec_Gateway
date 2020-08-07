# -*- coding: utf-8 -*-

import argparse

class FSM():
    """This class represents the FSM read from model. It contains the states, initial state and transition matrix."""
    def __init__(self, states, transMatrix, initial, protofile):
        self.states = states
        self.transMatrix = transMatrix
        self.initial = initial
        self.proto = {}
        
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
        return f

    
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
            while True:
                line = f.readline()
                if (len(line) == 0):
                    break
                line = line.rstrip('\n')
                contents = line.split(' - ')
                if (len(contents) < 2):
                    print("WARNING: Protocol specification in the wrong format.")
                    break
                self.proto[contents[0]] = contents[1]

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
            return f'allow tcp {client} -> {server}'
        else:
            return f'allow tcp {server} -> {client}'

    def generateRule(self, sid, tid):
        content = self.generateContent(sid, tid)
        flowbits = self.generateFlowbitsOptions(sid, tid)
        rule_id = f'sid:{self.rule_id};'
        
        self.rule_id += 1
        
        #Assume transitions that contains read is query from client to server, transition that contains
        #response is from server to client
        if "Read" in self.transMatrix[sid][tid]:
            header = self.generateHeader(True)
            return f'{header} (flow:established;{content}{flowbits}tag:session,exclusive;{rule_id})' 
        elif "Response" in self.transMatrix[sid][tid]:
            header = self.generateHeader(False)
            return f'{header} (flow:established;{content}{flowbits}tag:session,exclusive;{rule_id})' 
        else:
            print("WARNING: Protocal specification in wrong format, cannot decide direction of flow.")
            return ''
    
    def allowSYN(self):
        #allow client to send SYN packets to server
        header = self.generateHeader(True)
        return f'{header} (flags:S;)' 

    def allowFIN(self):
        #allow client to send FIN to client
        header = self.generateHeader(True)
        return f'{header} (flags:AF;)' 

    def allowSYNACK(self):
        #allow server to send SYN ACK to client
        header = self.generateHeader(False)
        return f'{header} (flags:SA;)'    
    
    def generateAllRules(self):
        #generate rules based on FSM
        for sid, row in enumerate(self.transMatrix):
            for tid, v in enumerate(row):
                if v:
                    print(self.generateRule(sid, tid))
        #allow client to send SYN to server to enable connection
        print(self.allowSYN())
        print(self.allowFIN())
        print(self.allowSYNACK())

    def setServerPort(self, port):
        self.SERVER_PORT=port

    def setGroupName(self, name):
        self.GROUP_NAME=name
        

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
    F.setServerPort(args.port)
    F.setGroupName(args.name)    
    F.generateAllRules()


    

if __name__=='__main__':
    main()


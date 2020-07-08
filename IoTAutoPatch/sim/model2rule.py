# -*- coding: utf-8 -*-
import logging
from pathlib import Path

logging.basicConfig(level=logging.INFO, filename='/var/log/model2rule.log', format="[%(levelname)s] - %(asctime)s - %(message)s", datefmt='%H:%M:%S')

fModel = "/etc/radio/model2"
fProto = "/etc/radio/proto"
fIOT_IP = "IOT_IP"

fRules = "/etc/radio/modbus.rules"

fModel = open(fModel,"r")
fProto = open(fProto,"r")
IOT_IP = open(fIOT_IP,"r")

fRules = open(fRules,"w")

# read the model

GROUPNAME = "modbus"
SERVER_IP = IOT_IP.read()
SERVER_PORT = '502'
CLIENT_IP = '10.1.1.2'
CLIENT_PORT = 'any'

class FSM():

    CLIENT_TO_SERVER = -1
    SERVER_TO_CLIENT = 1
    BIDIRECTIONAL = 0
    
    """This class represents the FSM read from model. It contains the states, initial state and transition matrix."""
    def __init__(self, states, transMatrix, initial):
        self.states = states
        self.transMatrix = transMatrix
        self.initial = initial
        self.proto = {}
        
        # need for snort rule IDs
        self.rule_id = 3000000
        self.rev_id = 1
        self.classtype = 'tcp-connection'
        self.priority = 10
        
        #check if initial state is in states
        if self.initial not in self.states:
            logging.warning("WARNING: Initial state not found.")
        else:
            self.init_id = self.states.index(initial)
        #check if matrix has correct dimensions
        if len(self.transMatrix) != len(self.states):
            logging.warning("WARNING: Invalid matrix size (# rows).")
        for i, row in enumerate(self.transMatrix):
            if len(row) != len(self.states):
                logging.warning(f"WARNING: Invalid matrix size (# cols in row {i}).")
        
        self.readContent()
        
    def __repr__(self):
    
        v = "\n".join(str(r) for r in self.transMatrix)
    
        return f'''\
States: {" ".join(self.states)}

Transitions:
{v}

Initial state: {self.initial}
'''
    
    def generateFlowbitsOptions(self, sid, tid):
        # Generate the flowbits rule to check if in state S
        if sid == self.init_id:
            s_bits = f'isnotset,any,{GROUPNAME}'
        else:
            s_bits = f'isset,{self.states[sid]}'
        
        # Generate the flowbits rule to set state T
        if tid == self.init_id:
            t_bits = f'unset,all,{GROUPNAME}'
        else:
            t_bits = f'setx,{self.states[tid]},{GROUPNAME}'
        
        return f'flowbits:{s_bits};flowbits:{t_bits};'
        
    def readContent(self):
        """This function reads the protocol specifications and fill self.proto"""
        #self.proto: key - transition    value: content
        while True:
            line = fProto.readline()
            if (len(line) == 0):
                break
            line = line.rstrip('\n')
            contents = line.split(' - ')
            if (len(contents) < 2):
                logging.warning("WARNING: Protocol specification in the wrong format.")
                break
            self.proto[contents[0]] = contents[1]

    def generateContent(self, sid, tid): 
        content = ''
        for entry in self.proto:
            if entry in self.transMatrix[sid][tid]:
                content += self.proto[entry]
        return content

    def generateHeader(self, action, direction):
        server = f'{SERVER_IP} {SERVER_PORT}'
        client = f'{CLIENT_IP} {CLIENT_PORT}'
        if direction == FSM.BIDIRECTIONAL:
            return f'{action} tcp {client} <> {server}'
        elif direction == FSM.CLIENT_TO_SERVER:
            return f'{action} tcp {client} -> {server}'
        elif direction == FSM.SERVER_TO_CLIENT:
            return f'{action} tcp {server} -> {client}'
        else:
            logging.error("ERROR: Invalid direction!")
            raise ValueError("ERROR: Invalid direction!")

    def generateRule(self, sid, tid):
        content = self.generateContent(sid, tid)
        flowbits = self.generateFlowbitsOptions(sid, tid)
        rule_id = f'sid:{self.rule_id};'
        rev_id = f'rev:{self.rev_id};'
        classtype = f'classtype:{self.classtype};'
        priority = f'priority:{self.priority};'
        self.rule_id += 1
        
        # Assume transitions that contains read is query from client to server, transition that contains
        # response is from server to client
        if "Read" in self.transMatrix[sid][tid]:
            header = self.generateHeader('pass', FSM.CLIENT_TO_SERVER)
            return f'{header} (flow:established; {content} {flowbits} {rule_id} {rev_id} {classtype} {priority})' 
        elif "Response" in self.transMatrix[sid][tid]:
            header = self.generateHeader('pass', FSM.SERVER_TO_CLIENT)
            return f'{header} (flow:established; {content} {flowbits} {rule_id} {rev_id} {classtype} {priority})' 
        else:
            logging.warning("WARNING: Protocal specification in wrong format, cannot decide direction of flow.")
            return ''
    
    def allowSYN(self):
        #allow client to send SYN packets to server
        header = self.generateHeader('pass', FSM.CLIENT_TO_SERVER)
        rule_id = f'sid:{self.rule_id};'
        rev_id = f'rev:{self.rev_id};'
        classtype = f'classtype:{self.classtype};'
        priority = f'priority:{self.priority};'
        self.rule_id += 1
        return f'{header} (flags:S; {rule_id} {rev_id} {classtype} {priority})'
        
    def allowSYNACK(self):
        #allow client to send SYN packets to server
        header = self.generateHeader('pass', FSM.SERVER_TO_CLIENT)
        rule_id = f'sid:{self.rule_id};'
        rev_id = f'rev:{self.rev_id};'
        classtype = f'classtype:{self.classtype};'
        priority = f'priority:{self.priority};'
        self.rule_id += 1
        return f'{header} (flags:SA; {rule_id} {rev_id} {classtype} {priority})'

    def allowFIN(self):
        #allow client to send FIN to client
        header = self.generateHeader('pass', FSM.BIDIRECTIONAL)
        rule_id = f'sid:{self.rule_id};'
        rev_id = f'rev:{self.rev_id};'
        classtype = f'classtype:{self.classtype};'
        priority = f'priority:{self.priority};'
        self.rule_id += 1
        return f'{header} (flags:F+; {rule_id} {rev_id} {classtype} {priority})'
        
    def allowACK(self):
        #allow client to send FIN to client
        header = self.generateHeader('pass', FSM.BIDIRECTIONAL)
        rule_id = f'sid:{self.rule_id};'
        rev_id = f'rev:{self.rev_id};'
        classtype = f'classtype:{self.classtype};'
        priority = f'priority:{self.priority};'
        self.rule_id += 1
        return f'{header} (flags:A; dsize:0; {rule_id} {rev_id} {classtype} {priority})'
        
    def dropAll(self):
        header = self.generateHeader('drop', FSM.BIDIRECTIONAL)
        rule_id = f'sid:{self.rule_id};'
        rev_id = f'rev:{self.rev_id};'
        classtype = f'classtype:{self.classtype};'
        priority = f'priority:{self.priority};'
        self.rule_id += 1
        return f'{header} ({rule_id} {rev_id} {classtype} {priority})'

    def generateAllRules(self):
        #generate rules based on FSM
        for sid, row in enumerate(self.transMatrix):
            for tid, v in enumerate(row):
                if v:
                    fRules.write(self.generateRule(sid, tid)+'\n')
        #allow client to send SYN to server to enable connection
        fRules.write(self.allowSYN()+'\n' +self.allowSYNACK()+'\n'+self.allowFIN()+'\n'+self.allowACK()+'\n') # one alert for MsgAnalysis()
        # fRules.write(self.allowSYNACK()+'\n')
        # fRules.write(self.allowFIN()+'\n')
        # fRules.write(self.allowACK()+'\n')
        # fRules.write(self.dropAll()+'\n')
        
def readModel(fModel):
    """This function reads the model file and generate a FSM class out of it.""" 
    states = []
    transMatrix = []

    while True:
        line = fModel.readline()
        if len(line) == 0:
            break
        line = line.rstrip('\n')
        if line == "states":
            nextline = fModel.readline()
            nextline = nextline.rstrip('\n')
            states = nextline.split(",")
            m = len(states)
            for i in range(m):
                transMatrix.append([""] * m)
        if line == "#initial":
            nextline = fModel.readline()
            nextline = nextline.rstrip('\n')
            initstate = nextline
        if line == "#transitions":
            nextline = fModel.readline()
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
    return FSM(states, transMatrix, initstate)
    
F = readModel(fModel)
print(F)
F.generateAllRules()
modbus_rules = Path("/etc/radio/modbus.rules")
if(modbus_rules.exists()):
    logging.info("SUCCESS: modbus.rules created.")    
else:   
    logging.error("ERROR: Cannot find modbus.rules.")
    


#content:\"|03 00|\"; offset:5; depth:2; content:"|08 00 04|"; offset:7; depth:3; flowbits:readregreq,mobus; msg:"Modbus TCP - Read Register 3"; tag:session, exclusive;)\n")

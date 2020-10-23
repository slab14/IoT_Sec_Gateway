import java.io.BufferedReader;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.math.BigInteger;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.List;
import java.util.ArrayList;
import java.util.Random;
import java.util.Collections;
import java.util.Set;


public class Bro2Model {

    public static class FSMState {
	public String str;
	public FSMState(){ }
	public FSMState(String str){
	    this.str = str;
	}
    }


    public static class TraceData {
	ArrayList<ArrayList<String>> tracesAll;
	ArrayList<Integer> symbolList = new ArrayList<>();
	TraceData(){}
	TraceData(ArrayList<ArrayList<String>> tracesAll){
	    this.tracesAll = tracesAll;
	}
	TraceData(ArrayList<ArrayList<String>> tracesAll, ArrayList<Integer> symbolList){
	    this.tracesAll = tracesAll;
	    this.symbolList = symbolList;
	}
    }

    public static String convertStringToHex(String str) {
	String out="\"|";
	int count=2;
        for (char temp : str.toCharArray()) {
	    if((Character.compare(temp, '\\')==0) ||
	       (Character.compare(temp,'x')==0) ||
	       (Character.compare(temp,'\0')==0) ||
	       (Character.compare(temp, '\"')==0)) {continue;}
	    out+=temp;
        }
	out+="|\";";
        return out;
    }

    public static String addEscapes(String str) {
	String out="";
	for(char c: str.toCharArray()) {
	    if(Character.compare(c, '\"')==0) {
		out+="\\";
	    }
	    out+=c;
	}
	return out;
    }
    

    public static TraceData parseLog2(String logFile, String type) throws IOException {
	Map<String, ArrayList<String>> sequenceMap = new HashMap<String, ArrayList<String>>();
	Map<String, String> tMap = new HashMap<String,String>();
	Map<String, Integer[]> tsizeMap = new HashMap<String,Integer[]>();
	Map<String, String[]> tdataMap = new HashMap<String,String[]>();
	ArrayList<Integer> symbolList = new ArrayList<>();
	ArrayList<String> conns = new ArrayList<>();
	int msgNo = 0;
	ArrayList<ArrayList<String>> traces = new ArrayList<ArrayList<String>>();
	try {
	    BufferedReader br = null;
	    String sCurrentLine;
	    FileReader freader = new FileReader(logFile);
	    br = new BufferedReader(freader);
	    while ((sCurrentLine = br.readLine()) != null) {
		String[] splitted = sCurrentLine.split("\\t");
		if (splitted[0].charAt(0) == '#'){continue;}
		if (! conns.contains(splitted[0])){
		    conns.add(splitted[0]);
		    sequenceMap.put(splitted[0], new ArrayList<String>());
		}
		String toMult=splitted[6];
		String fromMult=splitted[8];
		String[] otherData={toMult, fromMult};
		int toKeyOff=Integer.parseInt(splitted[13]);
		if(toKeyOff!=0) {toKeyOff-=1;}
		int fromKeyOff=Integer.parseInt(splitted[18]);
		if(fromKeyOff!=0) {fromKeyOff-=1;}		
		int toKeyLen=Integer.parseInt(splitted[12])+toKeyOff;
		int fromKeyLen=Integer.parseInt(splitted[17])+fromKeyOff;
		int fromLen=Integer.parseInt(splitted[7]);
		int toLen=Integer.parseInt(splitted[5]);
		String toKey=addEscapes(splitted[11]);
		if(toKey.equals("(empty)")) { toKey=" "; }
		String fromKey=addEscapes(splitted[16]);
		if(fromKey.equals("(empty)")) { fromKey=" "; }		
		if(type.equals("http")){
		    String[] lastURI=splitted[10].split("/");
		    toKey=splitted[9]+",/"+lastURI[lastURI.length-1]+",";
		    if(splitted[11].equals("(empty)")) {
			toKeyLen=splitted[10].length()+5;
			toKeyOff=splitted[10].indexOf(lastURI[lastURI.length-1])+3;
		    }else{
			toKey+=addEscapes(splitted[11]);
		    }
		    fromKey=splitted[14]+","+splitted[15]+",";
		    if(splitted[16].equals("(empty)")) {
			fromKeyLen=fromKey.length();
			fromKeyOff=9;
		    }else{
			fromKey+=addEscapes(splitted[16]);			
		    }
		}
		Integer[] sizes = {toKeyLen, toKeyOff, fromKeyLen, fromKeyOff, toLen, fromLen};
		for(String key: tMap.keySet()) {
		    String[] sig = key.split(" :: ");
		    if ((sig[0].contains(toKey)) && (sig[1].contains(fromKey))) {
			Integer[] storedSizes = tsizeMap.get(tMap.get(key));
			for (int i=0; i<sizes.length; i++) {
			    if((i==1) || (i==3)) {
				if((storedSizes[i]>=0) && (sizes[i]!=storedSizes[i])) {
				    tsizeMap.get(tMap.get(key))[i]=-1;
				    storedSizes[i]=-1;
				}
			    }
			    if(storedSizes[i]<0){
				sizes[i]=storedSizes[i];
			    }else if(sizes[i]<=storedSizes[i]) {
				sizes[i]=storedSizes[i];
			    } else {
				tsizeMap.get(tMap.get(key))[i]=sizes[i];
			    }
			}
			break;
		    }
		}
		String direction = splitted[19];
		String msgTo=toKey;
		String msgFrom=fromKey;
		String transition = msgTo+" :: "+msgFrom;
		//Create alphabet of transitions
		if (!tMap.containsKey(transition)){
		    msgNo+=1;
		    String msgStr = Integer.toString(msgNo);
		    if((direction.equals("<-")) || (msgTo.equals(""))){ msgStr+="*"; }
		    tMap.put(transition, msgStr);
		    tsizeMap.put(msgStr, sizes);
		    tdataMap.put(msgStr, otherData);
		    symbolList.add(msgNo);
		    System.out.println("alphabet: "+msgStr+" -> "+msgTo+" | "+msgFrom);
		}
		sequenceMap.get(splitted[0]).add(tMap.get(transition));
	    }
	    freader.close();
	} catch (IOException e)	{ e.printStackTrace(); }
	FileWriter writer = new FileWriter("ms.csv");
	for (ArrayList<String> seq: sequenceMap.values()){
	    traces.add(seq);
	    for(String s: seq){
		writer.append(s);		
		System.out.print(s+",");		
		writer.append(",");
	    }
	    writer.append(""+0+"\n");
	    System.out.print("\n");
	}
	writer.flush();
	writer.close();	
	FileWriter f = new FileWriter("proto.txt");
	f.append("#type:"+type+"\n");
	f.append("#inputs\n");
	for(String alpha: tMap.keySet()) {
	    String content = alpha.split(" :: ")[0].trim();
	    String mult = tdataMap.get(tMap.get(alpha))[0];
	    if(content.contains("\\x")) {
		if(type.equals("http")){
		    String[] parts=content.split(",");
		    if(parts[2].contains("\\x")) {
			parts[2]=convertStringToHex(parts[2])+"rawbytes";
		    }
		    content=parts[0]+","+parts[1]+","+parts[2];
		} else {
		    content=convertStringToHex(content)+"rawbytes";
		}
	    }
	    Integer[] sizeData = tsizeMap.get(tMap.get(alpha));
	    if(!content.equals("")){
		if(!type.equals("http")) {
		    if(content.contains("/[")) {
			f.append(tMap.get(alpha)+" - "+"pcre:\""+content+"\"; - "+Integer.toString(sizeData[0])+" - "+Integer.toString(sizeData[1])+" - "+mult+" - "+Integer.toString(sizeData[4])+"\n");
		    } else if(content.contains("\"|")) {
			f.append(tMap.get(alpha)+" - "+"content:"+content+"; - "+Integer.toString(sizeData[0])+" - "+Integer.toString(sizeData[1])+" - "+mult+" - "+Integer.toString(sizeData[4])+"\n");
		    }else {
			f.append(tMap.get(alpha)+" - "+"content:\""+content+"\"; - "+Integer.toString(sizeData[0])+" - "+Integer.toString(sizeData[1])+" - "+mult+" - "+Integer.toString(sizeData[4])+"\n");
		    }
		} else {
		    String[] parts=content.split(",");
		    String rule="";
		    for(String part: parts) {
			if(part.contains("/[")) {
			    rule+="pcre:"+part+";";
			} else if(part.contains("\"|")) {
			    rule+="content:"+part+";";			    
			} else {
			    rule+="content:\""+part+"\";";
			}
		    }
		    f.append(tMap.get(alpha)+" - "+rule+" - "+Integer.toString(sizeData[0])+" - "+Integer.toString(sizeData[1])+" - "+mult+" - "+Integer.toString(sizeData[4])+"\n");
		}
	    }
	}
	f.append("#outputs\n");
	for(String bets: tMap.keySet()){	    
	    String content = bets.split(" :: ")[1];
	    String mult = tdataMap.get(tMap.get(bets))[1];
	    if(content.contains("\\x")) {
		if(type.equals("http")){
		    String[] parts=content.split(",");
		    if(parts[2].contains("\\x")) {
			parts[2]=convertStringToHex(parts[2])+"rawbytes";
		    }
		    content=parts[0]+","+parts[1]+","+parts[2];
		} else {
		    content=convertStringToHex(content)+"rawbytes";
		}		
	    }
	    Integer[] sizeData = tsizeMap.get(tMap.get(bets));	    
	    if(!content.equals(" ")){
		if(!type.equals("http")) {
		    if(content.contains("/[")) {
			f.append(tMap.get(bets)+" - "+"pcre:\""+content.trim()+"\"; - "+Integer.toString(sizeData[2])+" - "+Integer.toString(sizeData[3])+" - "+mult+" - "+Integer.toString(sizeData[5])+"\n");
		    } else if(content.contains("\"|")) {
			f.append(tMap.get(bets)+" - "+"content:"+content+"; - "+Integer.toString(sizeData[2])+" - "+Integer.toString(sizeData[3])+" - "+mult+" - "+Integer.toString(sizeData[5])+"\n");			
		    }else{
			f.append(tMap.get(bets)+" - "+"content:\""+content.trim()+"\"; - "+Integer.toString(sizeData[2])+" - "+Integer.toString(sizeData[3])+" - "+mult+" - "+Integer.toString(sizeData[5])+"\n");
		    }
		}else {
		    String[] parts=content.split(",");
		    String rule="";
		    for(String part: parts) {
			if(part.contains("/[")){
			    rule+="pcre:\""+part+"\";";
			}else{
			    rule+="content:\""+part+"\";";
			}
		    }
		    f.append(tMap.get(bets)+" - "+rule+" - "+Integer.toString(sizeData[2])+" - "+Integer.toString(sizeData[3])+" - "+mult+" - "+Integer.toString(sizeData[5])+"\n");
		}
	    }
	}
	f.flush();
	f.close();
	return new TraceData(traces, symbolList);
    }

    
    public static TraceData parseHTTPlog(String logFile) throws IOException {
	Map<String, String> dMap = new HashMap<String,String>();
	Map<String, ArrayList<String>> sequenceMap = new HashMap<String, ArrayList<String>>();
	Map<String, String> oMap = new HashMap<String, String>();
	Map<String, ArrayList<Integer>> outMsgLens = new HashMap<String, ArrayList<Integer>>();
	ArrayList<Integer> symbolList = new ArrayList<>();
	ArrayList<String> conns = new ArrayList<>();
	int msgNo = 0;
	ArrayList<ArrayList<String>> traces = new ArrayList<ArrayList<String>>();
	ArrayList<String> sequence = new ArrayList<String>();
	try {
	    BufferedReader br = null;
	    String sCurrentLine;
	    FileReader freader = new FileReader(logFile);
	    br = new BufferedReader(freader);
	    while ((sCurrentLine = br.readLine()) != null) {
		String[] splitted = sCurrentLine.split("\\s+");
		if (splitted[0].charAt(0) == '#'){continue;}
		if (! conns.contains(splitted[0])){
		    conns.add(splitted[0]);
		    sequenceMap.put(splitted[0], new ArrayList<String>());
		}
		String toLen=splitted[9];
		int fromLen=Integer.parseInt(splitted[10]);
		String[] lastURI=splitted[6].split("/");
		String msgTo=splitted[5]+"/"+lastURI[lastURI.length-1]+"/"+toLen;
		String msgFrom=splitted[7]+"/"+splitted[8];
		//Create alphabet of transitions
		if (!dMap.containsKey(msgTo)){
		    msgNo+=1;
		    dMap.put(msgTo, ""+msgNo);
		    symbolList.add(msgNo);
		    System.out.println("alphabet: "+msgNo+" -> "+msgTo+" | "+msgFrom);
		}
		sequenceMap.get(splitted[0]).add(dMap.get(msgTo));
		if (!oMap.containsKey(dMap.get(msgTo))){ oMap.put(dMap.get(msgTo), msgFrom); }
		if (!outMsgLens.containsKey(dMap.get(msgTo))) {outMsgLens.put(dMap.get(msgTo),new ArrayList<Integer>());}
		outMsgLens.get(dMap.get(msgTo)).add(fromLen);
	    }
	    freader.close();
	} catch (IOException e)	{ e.printStackTrace(); }
	FileWriter writer = new FileWriter("ms.csv");
	for (ArrayList<String> seq: sequenceMap.values()){
	    traces.add(seq);
	    for(String s: seq){
		writer.append(s);		
		System.out.print(s+",");		
		writer.append(",");
	    }
	    writer.append(""+0+"\n");
	    System.out.print("\n");
	}
	writer.flush();
	writer.close();	
	FileWriter f = new FileWriter("proto.txt");
	f.append("#inputs\n");
	for(String alpha: dMap.keySet()) {
	    String[] parts = alpha.split("/"); 
	    f.append(dMap.get(alpha)+" - "+"content:\""+parts[0]+"\";content:\""+parts[1]+"\"; - "+parts[2]+"\n");
	    // could modify to be dsize:part[2]
	}
	f.append("#outputs\n");
	for(String bets: oMap.keySet()){
	    String[] parts = oMap.get(bets).split("/");
	    int min = Collections.min(outMsgLens.get(bets));
	    int max = Collections.max(outMsgLens.get(bets));	    
	    String len = Integer.toString(min)+","+Integer.toString(max);
	    f.append(bets+" - "+"content:\""+parts[0]+"\";content:\""+parts[1]+"\"; - "+len+"\n");
	}
	f.flush();
	f.close();
	return new TraceData(traces, symbolList);
    }
    

    public static class MealyFSM {
	public String initialStateStr;
	public String curStateStr;
	public int stateNum = 0;
	public Map<String, FSMState> stateMap = new HashMap<String, FSMState>();
	public ArrayList<Integer> symbolList = new ArrayList<>();
	// transitionRelation S * I -> S
	public Map<String, Map<String,String> > delta = new HashMap<String, Map<String,String> >();
	
	public MealyFSM(){}
	
	public String newState(){
	    String stateStr = "s" + this.stateNum;
	    this.stateMap.put( stateStr, new FSMState(stateStr) );
	    this.stateNum = this.stateNum + 1;
	    return stateStr;
	}
	
	public void resetState(){
	    this.curStateStr = "s0";
	}
	
	public boolean tranverse(String iStr){
	    if (this.delta.containsKey(this.curStateStr)){
		if (this.delta.get(this.curStateStr).containsKey(iStr)){
		    String nextState = this.delta.get(this.curStateStr).get(iStr);
		    this.curStateStr = nextState;
		    return true;
		}
	    }
	    return false;
	}

	public void setSymbolList(ArrayList<Integer> symbolList){
	    this.symbolList=symbolList;
	}
    }


    
    public static MealyFSM buildTreeFSM( ArrayList<ArrayList<String>> traces ){
	MealyFSM treeFSM = new MealyFSM();
	treeFSM.initialStateStr = treeFSM.newState(); // add s0
	for (ArrayList<String> trace: traces) {
	    treeFSM.curStateStr = treeFSM.initialStateStr;
	    for (String state: trace) {
		if ( treeFSM.delta.get(treeFSM.curStateStr) == null ){
		    String nextStateStr = treeFSM.newState();
		    Map<String, String> dmap = new HashMap<String,String>();
		    dmap.put(state, nextStateStr);
		    treeFSM.delta.put(treeFSM.curStateStr, dmap);		
		    treeFSM.curStateStr = nextStateStr;
		} else if ( treeFSM.delta.get(treeFSM.curStateStr).get(state) == null ){
		    String nextStateStr = treeFSM.newState();
		    (treeFSM.delta.get(treeFSM.curStateStr)).put(state, nextStateStr);
		    treeFSM.curStateStr = nextStateStr;
		} else {
		    treeFSM.curStateStr = treeFSM.delta.get(treeFSM.curStateStr).get(state);
		}
	    }
	}
	return treeFSM;			
    }


    public static MealyFSM mergeFSM2(MealyFSM fsm, boolean init) {
	List<String> states = new ArrayList<String>();
	if (!init) { for (String stateTemp : fsm.stateMap.keySet()) { states.add(stateTemp);}}
	else { for (int i=0; i<fsm.stateMap.size(); i++) {states.add("s"+String.valueOf(i));}}
	for (String state : states) {
	    if ((!fsm.stateMap.containsKey(state)) || (fsm.delta.get(state)==null)) {continue; }
	    for (String transition: fsm.delta.get(state).keySet()) {
		String nextState = fsm.delta.get(state).get(transition);
		if (nextState.equals(state)){continue;}
		if ((fsm.delta.get(nextState)==null) || (fsm.delta.get(nextState).size()!=1)) {continue; }
		String nextTransition = fsm.delta.get(nextState).entrySet().iterator().next().getKey();
		while (transition.equals(nextTransition)) {
		    String nextNextState = fsm.delta.get(nextState).get(nextTransition);
		    fsm.delta.get(state).replace(transition, nextNextState);
		    fsm.stateMap.remove(nextState);
		    fsm.delta.remove(nextState);		    		    
		    nextState = nextNextState;
		    if (fsm.delta.get(nextState)==null){
			Map<String, String> dmap = new HashMap<String, String>();
			dmap.put(transition, nextState);
			fsm.delta.put(nextState, dmap);			
			break;
		    }
		    if (fsm.delta.get(nextState).size()!=1) {
			fsm.delta.get(nextState).put(transition, nextState);		    
			break;
		    }
		    nextTransition = fsm.delta.get(nextState).entrySet().iterator().next().getKey();
		    if (!transition.equals(nextTransition)) {fsm.delta.get(nextState).put(transition, nextState);} 
		}
	    }
	}
	for (String state : states) {
	    if ((!fsm.stateMap.containsKey(state)) || (fsm.delta.get(state)==null)) {continue; }
	    boolean hasLoop=false;
	    String loopTransition="";
	    for (String transition: fsm.delta.get(state).keySet()) {
		String nextState = fsm.delta.get(state).get(transition);
		if(nextState.equals(state)) {
		    hasLoop=true;
		    loopTransition=transition;
		    break;
		} else {
		    hasLoop=false;
		}
	    }
	    if (hasLoop) {
		ArrayList<String> transitions2add = new ArrayList<String>();
		for (String transition: fsm.delta.get(state).keySet()) {
		    if ((loopTransition.equals(transition)) || (fsm.delta.get(state)==null)) {continue;}
		    String preLoopTransition = transition;
		    String preLoopState = state;
		    String loopState = fsm.delta.get(preLoopState).get(preLoopTransition);
		    ArrayList<String> tested = new ArrayList<String>();
		    while ((fsm.delta.get(loopState)!=null) && !state.equals(loopState)) {
			tested.add(loopState);
			if (fsm.delta.get(loopState).size()>1) {
			    for (String secondLoopTransition: fsm.delta.get(loopState).keySet()) {
				if (!loopTransition.equals(secondLoopTransition)) {continue;}
				String checkLoop = fsm.delta.get(loopState).get(secondLoopTransition);
				if(checkLoop.equals(loopState)) {
				    for (String postLoopTransition: fsm.delta.get(loopState).keySet()) {
					if (postLoopTransition.equals(secondLoopTransition)) {continue;}
					String nextState = fsm.delta.get(loopState).get(postLoopTransition);
					if(!fsm.delta.get(state).containsKey(postLoopTransition)){
					    transitions2add.add(state+","+postLoopTransition+","+nextState);
					}
					fsm.delta.get(preLoopState).replace(preLoopTransition, state);
					fsm.stateMap.remove(loopState);
					fsm.delta.remove(loopState);
					loopState=nextState;
					break;
				    }
				}
			    }
			} else {
			    if(loopState.equals(fsm.delta.get(preLoopState).get(fsm.delta.get(loopState).entrySet().iterator().next().getKey()))) {
				fsm.delta.get(preLoopState).replace(preLoopTransition, state);
				fsm.stateMap.remove(loopState);
				fsm.delta.remove(loopState);
				break;
			    }
			    preLoopTransition = fsm.delta.get(loopState).entrySet().iterator().next().getKey();
			    preLoopState = loopState;
			    loopState = fsm.delta.get(preLoopState).get(preLoopTransition);
			    if(fsm.delta.get(loopState)==null){
				if(preLoopTransition.equals(loopTransition)){
				    fsm.delta.get(preLoopState).replace(preLoopTransition, state);
				    fsm.stateMap.remove(loopState);
				    fsm.delta.remove(loopState);
				}
			    }
			}
			if(tested.contains(loopState)) {
			    for(String newTransition: fsm.delta.get(loopState).keySet()) {
				String potential = fsm.delta.get(loopState).get(newTransition);
				if (tested.contains(potential)) {continue;}
				loopState=potential;
				break;
			    }
			}
		    }
		}
		for(String toAdd: transitions2add){
		    String[] add = toAdd.split(",");
		    if(!fsm.delta.get(add[0]).containsKey(add[1])){
			fsm.delta.get(add[0]).put(add[1], add[2]);
		    } else {
			for (String transition: fsm.delta.get(fsm.delta.get(add[0]).get(add[1])).keySet()) {
			    if (!fsm.delta.get(add[2]).containsKey(transition)){
				fsm.delta.get(add[2]).put(transition, fsm.delta.get(fsm.delta.get(add[0]).get(add[1])).get(transition));
				fsm.delta.remove(fsm.delta.get(add[0]).get(add[1]));
			    }
			}
			fsm.stateMap.remove(fsm.delta.get(add[0]).get(add[1]));
			fsm.delta.get(add[0]).replace(add[1], add[2]);
		    }
		}
	    }
	}
	int singleTranSeqlen=0;
	ArrayList<String[]> sequences = new ArrayList<String[]>();
	boolean start = false;
	String state="s0";
	String firstState = "";
	String checkingState="";
	while (fsm.delta.get(state)!=null) {
	    while(fsm.delta.get(state).size()==1) {
		singleTranSeqlen++;
		if (!start){
		    start=true;
		    firstState=state;
		}
		state = fsm.delta.get(state).get(fsm.delta.get(state).entrySet().iterator().next().getKey());
		if(fsm.delta.get(state)==null){break;}
		if(state.equals(checkingState)) {
		    state = null;
		    break;
		}
	    }
	    if(start){
		start=false;
		String[] entry={firstState, state, Integer.toString(singleTranSeqlen)};
		sequences.add(entry);
		singleTranSeqlen=0;
	    }
	    if(fsm.delta.get(state)==null){break;}	    
	    for(String transition: fsm.delta.get(state).keySet()) {
		String nextState = fsm.delta.get(state).get(transition);
		checkingState=state;
		if (state.equals(nextState)) {continue;}
		state=nextState;
		break;
	    }
	}
	for (String[] sequence: sequences) {
	    boolean modified=false;
	    for(int loopSize=3; loopSize>=2; loopSize--) {
		if(modified){break;}
		String[] baseStates = new String[loopSize];
		String[] baseTrans = new String[loopSize];
		String[] checkStates = new String[loopSize];
		String[] checkTrans = new String[loopSize];
		String outState="";
		int testLen = Integer.parseInt(sequence[2]);
		String initState=sequence[0];
		String startTest="";
		boolean need2write=false;
		String writeState="";
		String writeTrans="";
		String writeOut="";		    
		HashMap<String, String> writeMap = new HashMap<String, String>();
		while(testLen>=(loopSize*2)){
		    baseStates[0]=initState;
		    baseTrans[0]=fsm.delta.get(initState).entrySet().iterator().next().getKey();
		    for(int i=1; i<loopSize; i++) {
			baseStates[i]=fsm.delta.get(baseStates[i-1]).get(baseTrans[i-1]);
			baseTrans[i]=fsm.delta.get(baseStates[i]).entrySet().iterator().next().getKey();
		    }
		    checkStates[0]=fsm.delta.get(baseStates[baseStates.length-1]).get(baseTrans[baseTrans.length-1]);
		    checkTrans[0]=fsm.delta.get(checkStates[0]).entrySet().iterator().next().getKey();
		    for(int i=1;i<loopSize;i++) {
			checkStates[i]=fsm.delta.get(checkStates[i-1]).get(checkTrans[i-1]);
			checkTrans[i]=fsm.delta.get(checkStates[i]).entrySet().iterator().next().getKey();
		    }
		    outState=fsm.delta.get(checkStates[checkStates.length-1]).get(checkTrans[checkTrans.length-1]);
		    boolean foundLoop=true;
		    for(int i=0; i<loopSize; i++){
			foundLoop=foundLoop && (baseTrans[i]==checkTrans[i]);
		    }
		    if(foundLoop) {
			need2write=true;
			fsm.delta.get(baseStates[baseStates.length-1]).replace(baseTrans[baseTrans.length-1], outState);
			for(int i=0;i<loopSize;i++) {
			    fsm.stateMap.remove(checkStates[i]);
			    fsm.delta.remove(checkStates[i]);
			}
			modified=true;
			testLen-=loopSize;
		    } else {
			if(need2write){
			    fsm.delta.get(baseStates[baseStates.length-1]).replace(baseTrans[baseTrans.length-1],baseStates[0]);
			    need2write=false;
			    for(int i=0;i<loopSize;i++) {
				if(baseTrans[i]==checkTrans[i]) {
				    fsm.stateMap.remove(checkStates[i]);
				    fsm.delta.remove(checkStates[i]);			    
				} else {
				    String newState = fsm.delta.get(checkStates[i]).get(checkTrans[i]);
				    fsm.delta.get(baseStates[i]).put(checkTrans[i], newState);
				    fsm.stateMap.remove(checkStates[i]);
				    fsm.delta.remove(checkStates[i]);			    
				    initState=newState;				
				    testLen-=(i+1+loopSize);
				    break;
				}
			    }
			}else {
			    initState=baseStates[1];
			    testLen--;
			}
		    }
		}
		if(need2write){
		    fsm.delta.get(baseStates[baseStates.length-1]).replace(baseTrans[baseTrans.length-1],baseStates[0]);
		    for(int i=0; i<loopSize; i++) {
			if(fsm.delta.get(outState)!=null){
			    String nextTran = fsm.delta.get(outState).entrySet().iterator().next().getKey();
			    String nextState = fsm.delta.get(outState).get(nextTran);
			    if (baseTrans[i]!=nextTran) {
				fsm.delta.get(baseStates[i]).put(nextTran,nextState);
				break;
			    } else {
				fsm.stateMap.remove(outState);
				fsm.delta.remove(outState);			    				
				outState = nextState;
			    }
			} else {
			    break;
			}
		    }
		    fsm.stateMap.remove(outState);
		    fsm.delta.remove(outState);			    
		}
	    }
	}
	
	printFSM(fsm);
	return fsm;
    }
    


    public static BigInteger binomial(final int N, final int K) {
	BigInteger ret = BigInteger.ONE;
	for (int k = 0; k < K; k++) {
	    ret = ret.multiply(BigInteger.valueOf(N-k)).divide(BigInteger.valueOf(k+1));
	}
	return ret;
    }

    
    public static int fsmSize (MealyFSM fsm){
	int size = 0;		
	for (Map<String,String> map:fsm.delta.values()){
	    size = size + map.size();
	}
	return size;
    }

    
    public static void printFSM (MealyFSM fsm)	{
	System.out.println("###");
	System.out.println("#states");
	for (String statestr : fsm.stateMap.keySet()){ System.out.println(statestr); }
	System.out.println("#initial");
	System.out.println(fsm.initialStateStr);
	System.out.println("#alphabet");
	ArrayList<String> alphabet = new ArrayList<String>();
	for (String sstate : fsm.delta.keySet() ){
	    for (String x : fsm.delta.get(sstate).keySet()){
		if (!alphabet.contains(x)){
		    alphabet.add(x);
		    System.out.println(x);
		}
	    }
	}
	System.out.println("#transitions");
	for (String sstate : fsm.delta.keySet() ){
	    for (String x : fsm.delta.get(sstate).keySet()){
		String dstate = fsm.delta.get(sstate).get(x);
		System.out.println(""+sstate+":"+x+">"+dstate);
	    }
	}
	System.out.println("###");
    }


    public static void writeFSM(MealyFSM fsm) throws IOException{
	try{
	    FileWriter writer = new FileWriter("model.txt");
	    writer.append("states\n");
	    String outStr="";
	    for (String statestr : fsm.stateMap.keySet()){outStr+=statestr+","; }
	    outStr=outStr.substring(0, outStr.length()-1);
	    writer.append(outStr+"\n");
	    writer.append("#initial\n");
	    writer.append(fsm.initialStateStr+"\n");
	    writer.append("#alphabet\n");
	    outStr="";
	    ArrayList<String> alphabet = new ArrayList<String>();
	    for (String sstate : fsm.delta.keySet() ){
		for (String x : fsm.delta.get(sstate).keySet()){
		    if (!alphabet.contains(x)){
			alphabet.add(x);
			outStr+=x+",";
		    }
		}
	    }
	    outStr=outStr.substring(0, outStr.length()-1);
	    writer.append(outStr+"\n");
	    writer.append("#transitions\n");
	    outStr="";
	    for (String sstate : fsm.delta.keySet() ){
		for (String x : fsm.delta.get(sstate).keySet()){
		    String dstate = fsm.delta.get(sstate).get(x);
		    outStr+=sstate+">"+x+">"+dstate+",";
		}
	    }
	    outStr=outStr.substring(0, outStr.length()-1);
	    writer.append(outStr+"\n");	
	    writer.flush();
	    writer.close();
	} catch (IOException e)	{ e.printStackTrace(); }
    }


    public static void genFSM (ArrayList<ArrayList<String>> traces) throws Exception{
	MealyFSM FSM = new MealyFSM();
	FSM = buildTreeFSM(traces);
	FSM = mergeFSM2(FSM, true);
	writeFSM(FSM);
    }
    

    public static String getLogType(String fileName){
	String[] dirs = fileName.split("/");
	String[] name = dirs[dirs.length-1].split("\\.");
	String[] vals = name[0].split("_");
	if (vals.length==3) {
	    return vals[1];
	} else {
	    return name[0];
	}
    }
    
    public static void main(String[] args) throws Exception{
	if (args.length == 0) { System.out.println("no arguments were given."); }
	else {
	    for (String s: args) {
		String type = getLogType(s);
		TraceData traces = parseLog2(s, type);
		genFSM(traces.tracesAll);
	    }
	}
    }
    
}

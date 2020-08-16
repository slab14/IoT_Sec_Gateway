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


public class MattModel {

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
    

    public static TraceData parseLog(String logFile, String type) throws IOException{
	Map<String, String> dMap = new HashMap<String,String>();
	Map<String, ArrayList<String>> sequenceMap = new HashMap<String, ArrayList<String>>();
	ArrayList<String> outMsgs = new ArrayList<String>();
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
		if (! conns.contains(splitted[1])){
		    conns.add(splitted[1]);
		    sequenceMap.put(splitted[1], new ArrayList<String>());
		}
		String[] lastURI=splitted[9].split("/");
		String msgTo=splitted[7]+lastURI[lastURI.length-1];
		String msgFrom=splitted[16]+splitted[17];
		//Create alphabet of transitions
		if (!outMsgs.contains(msgFrom)){outMsgs.add(msgFrom);}
		if (!dMap.containsKey(msgTo)){
		    msgNo+=1;
		    dMap.put(msgTo, ""+msgNo);
		    symbolList.add(msgNo);
		}
		sequenceMap.get(splitted[1]).add(dMap.get(msgTo));
	    }
	    freader.close();
	} catch (IOException e)	{ e.printStackTrace(); }
	FileWriter writer = new FileWriter("ms.csv");
	for (ArrayList<String> seq: sequenceMap.values()){
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
	for (String statestr : fsm.stateMap.keySet()){
	    System.out.println(statestr);
	}
	System.out.println("#initial");
	System.out.println(fsm.initialStateStr);
	System.out.println("#accepting");
	System.out.println("#alphabet");
	ArrayList<String> alphabet = new ArrayList<String>();
	for (String sstate : fsm.delta.keySet() ){
	    for (String x : fsm.delta.get(sstate).keySet()){
		String dstate = fsm.delta.get(sstate).get(x);
		// remove redundancy
		String word = ""+x+"";
		if (!alphabet.contains(word)){
		    alphabet.add(word);
		    System.out.println(""+x+"");
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



    public static void genFSM (ArrayList<ArrayList<String>> traces){
	MealyFSM FSM = new MealyFSM();
	FSM = buildTreeFSM(traces);
	printFSM(FSM);	
    }
    

    
    public static void main(String[] args) throws Exception{
	if (args.length == 0) { System.out.println("no arguments were given."); }
	else {
	    for (String s: args) {
		TraceData traces = parseLog(s, "bro");
		genFSM(traces.tracesAll);
	    }
	}
    }
    
}




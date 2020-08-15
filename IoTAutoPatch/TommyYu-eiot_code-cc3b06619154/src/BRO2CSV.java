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
//import slab.TraceData;


public class BRO2CSV {

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
		    System.out.println("Alphabet item "+msgNo+": "+msgTo);
		}
		sequenceMap.get(splitted[1]).add(dMap.get(msgTo));
		System.out.println("Sequence Item: "+msgTo+" / "+dMap.get(msgTo));
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


    public static void main(String[] args) throws Exception{
	if (args.length == 0) { System.out.println("no arguments were given."); }
	else {
	    for (String s: args) {
		parseLog(s, "bro");
	    }
	}
    }
    
}




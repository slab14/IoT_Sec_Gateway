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

public class LearnFSM {

    public static MealyFSM buildTreeFSM( ArrayList<ArrayList<String[]>> traces ){
	MealyFSM treeFSM = new MealyFSM();
	// add s0
	treeFSM.initialStateStr = treeFSM.newState();
	for (int m = 0; m < traces.size(); m++)	{
	    treeFSM.curStateStr = treeFSM.initialStateStr;
	    for (int j = 0; j < traces.get(m).size(); j++) {
		if ( treeFSM.lambda.get(treeFSM.curStateStr) == null ){
		    String nextStateStr = treeFSM.newState();
		    Map<String, String> dmap = new HashMap<String,String>();
		    dmap.put(traces.get(m).get(j)[0], nextStateStr);
		    treeFSM.delta.put(treeFSM.curStateStr, dmap);		
		    Map<String, String> lmap = new HashMap<String,String>();
		    lmap.put(traces.get(m).get(j)[0], traces.get(m).get(j)[1]);
		    treeFSM.lambda.put(treeFSM.curStateStr, lmap);
		    treeFSM.curStateStr = nextStateStr;
		} else if ( treeFSM.lambda.get(treeFSM.curStateStr).get(traces.get(m).get(j)[0]) == null ){
		    String nextStateStr = treeFSM.newState();
		    (treeFSM.delta.get(treeFSM.curStateStr)).put(traces.get(m).get(j)[0], nextStateStr);
		    (treeFSM.lambda.get(treeFSM.curStateStr)).put(traces.get(m).get(j)[0], traces.get(m).get(j)[1]);
		    treeFSM.curStateStr = nextStateStr;
		} else {
		    treeFSM.curStateStr = treeFSM.delta.get(treeFSM.curStateStr).get(traces.get(m).get(j)[0]);
		}
	    }
	}
	return treeFSM;			
    }

    
    public static MealyFSM buildTreeFSMWithSymbols( ArrayList<ArrayList<String[]>> traces, ArrayList<Integer> symbolList){
	MealyFSM treeFSM = new MealyFSM();
	// add s0
	treeFSM.initialStateStr = treeFSM.newState();
	treeFSM.symbolList =  symbolList;
	for (int m = 0; m < traces.size(); m++)	{
	    treeFSM.curStateStr = treeFSM.initialStateStr;
	    for (int j = 0; j < traces.get(m).size(); j++){
		if ( treeFSM.lambda.get(treeFSM.curStateStr) == null ){
		    String nextStateStr = treeFSM.newState();
		    Map<String, String> dmap = new HashMap<String,String>();
		    dmap.put(traces.get(m).get(j)[0], nextStateStr);
		    treeFSM.delta.put(treeFSM.curStateStr, dmap);		
		    Map<String, String> lmap = new HashMap<String,String>();
		    lmap.put(traces.get(m).get(j)[0], traces.get(m).get(j)[1]);
		    treeFSM.lambda.put(treeFSM.curStateStr, lmap);
		    treeFSM.curStateStr = nextStateStr;
		} else if ( treeFSM.lambda.get(treeFSM.curStateStr).get(traces.get(m).get(j)[0]) == null ){
		    String nextStateStr = treeFSM.newState();
		    (treeFSM.delta.get(treeFSM.curStateStr)).put(traces.get(m).get(j)[0], nextStateStr);
		    (treeFSM.lambda.get(treeFSM.curStateStr)).put(traces.get(m).get(j)[0], traces.get(m).get(j)[1]);
		    treeFSM.curStateStr = nextStateStr;
		}else {
		    treeFSM.curStateStr = treeFSM.delta.get(treeFSM.curStateStr).get(traces.get(m).get(j)[0]);
		}
	    }
	}
	return treeFSM;			
    }

    
    public static MealyFSM mergeFSM(MealyFSM fsm) {
	List<String> statesToMerge = new ArrayList<String>();
	List<String> red = new ArrayList<String>();
	List<String> blue = new ArrayList<String>();
	// add all states to state to merge
	for (String stateTemp : fsm.stateMap.keySet()) {
	    statesToMerge.add(stateTemp);
	}
	// start from the end of the tree
	Collections.reverse(statesToMerge);
	for (String stateToMerge : statesToMerge) {
	    // check if stateToMerge still exists in fsm
	    if (!fsm.stateMap.containsKey(stateToMerge)) {
		continue;
	    }
	    // start from stateToMerge
	    red.add(stateToMerge);
	    // red.add(fsm.initialStateStr);
	    for (String stateTemp : fsm.stateMap.keySet()) {
		blue.add(stateTemp);
	    }
	    blue.remove(fsm.initialStateStr);
	    while (!blue.isEmpty()) {
		boolean isPromote = false;
		String stateB = blue.get(0);
		blue.remove(stateB);
		for (int i = 0; i < red.size(); i++) {
		    String stateR = red.get(i);
		    // Promote the state if the merge will break determinism
		    // Condition 1: child transition conflicts
		    if ((fsm.delta.get(stateR) != null)	&& (fsm.delta.get(stateB) != null)) {
			for (String xR : fsm.delta.get(stateR).keySet()) {
			    for (String xB : fsm.delta.get(stateB).keySet()) {
				// state R's child
				String stateRR = fsm.delta.get(stateR).get(xR);
				// state B's child
				String stateBB = fsm.delta.get(stateB).get(xB);
				String yR = fsm.lambda.get(stateR).get(xR);
				String yB = fsm.lambda.get(stateB).get(xB);
				// deterministic condition
				// 1) if different children
				if (stateRR.equals(stateBB)) {
				    if ((xR.equals(xB)) && (!yR.equals(yB))) {
					// if ( xR.equals(xB) ){
					// promote stateB
					red.add(stateB);
					isPromote = true;
					break;
				    }
				// 2) if same children				    
				}else{
				    if (xR.equals(xB)) {
					// if ( xR.equals(xB) ){
					// promote stateB
					red.add(stateB);
					isPromote = true;
					break;
				    }
				}
			    }
			    if (isPromote) {
				break;
			    }
			}
		    } // end of condition 1
		    if (isPromote) {
			break;
		    }
		    // merge states
		    if (!isPromote) {
			// merge stateB's children to state R
			if (fsm.delta.get(stateB) != null) {
			    for (String xB : fsm.delta.get(stateB).keySet()) {
				String stateBB = fsm.delta.get(stateB).get(xB);
				// if stateR already has transitions
				if (fsm.delta.get(stateR) != null) {
				    fsm.delta.get(stateR).put(xB, stateBB);
				// create new transitions for stateR				    
				} else   {
				    Map<String, String> dmap = new HashMap<String, String>();
				    dmap.put(xB, stateBB);
				    fsm.delta.put(stateR, dmap);
				}
			    }
			    if (!stateR.equals(stateB)) {
				fsm.delta.remove(stateB);
			    }
			    for (String xB : fsm.lambda.get(stateB).keySet()) {
				String yB = fsm.lambda.get(stateB).get(xB);
				// if stateR already has output
				if (fsm.lambda.get(stateR) != null) {
				    fsm.lambda.get(stateR).put(xB, yB);
			        // create new outputs for stateR				    
				} else 	{
				    Map<String, String> lmap = new HashMap<String, String>();
				    lmap.put(xB, yB);
				    fsm.lambda.put(stateR, lmap);
				}
			    }
			    if (!stateR.equals(stateB)) {
				fsm.lambda.remove(stateB);
			    }
			}
			// merge stateB's parent to state R
			for (String stateP : fsm.delta.keySet()) {
			    if (fsm.delta.get(stateP) != null) {
				for (String xP : fsm.delta.get(stateP).keySet()) {
				    if (fsm.delta.get(stateP).get(xP).equals(stateB)) {
					fsm.delta.get(stateP).put(xP, stateR);
				    }
				}
			    }
			}
			// remove stateB after merge
			if (!stateR.equals(stateB)) {
			    fsm.stateMap.remove(stateB);
			}
		    }
		}
	    }
	}
	return fsm;
    }

    
    // This method allows same transition into different states
    public static MealyFSM mergeFSMHistory(MealyFSM fsm) {
	List<String> statesToMerge = new ArrayList<String>();
	List<String> red = new ArrayList<String>();
	List<String> blue = new ArrayList<String>();
	// add all states to state to merge
	for (String stateTemp : fsm.stateMap.keySet()) {
	    statesToMerge.add(stateTemp);
	}
	// start from the end of the tree
	// Collections.reverse(statesToMerge);
	for (String stateToMerge : statesToMerge) {
	    // check if stateToMerge still exists in fsm
	    if (!fsm.stateMap.containsKey(stateToMerge)) {
		continue;
	    }
	    // start from stateToMerge
	    red.add(stateToMerge);
	    // red.add(fsm.initialStateStr);
	    for (String stateTemp : fsm.stateMap.keySet()) {
		blue.add(stateTemp);
	    }
	    blue.remove(fsm.initialStateStr);
	    while (!blue.isEmpty()) {
		boolean isPromote = false;
		String stateB = blue.get(0);
		blue.remove(stateB);
		for (int i = 0; i < red.size(); i++) {
		    String stateR = red.get(i);
		    // Promote the state if the merge will break determinism
		    // Condition 1: child transition conflicts
		    if ((fsm.delta.get(stateR) != null)	&& (fsm.delta.get(stateB) != null)) {
			for (String xR : fsm.delta.get(stateR).keySet()) {
			    for (String xB : fsm.delta.get(stateB).keySet()) {
				// state R's child
				String stateRR = fsm.delta.get(stateR).get(xR);
				// state B's child
				String stateBB = fsm.delta.get(stateB).get(xB);
				String yR = fsm.lambda.get(stateR).get(xR);
				String yB = fsm.lambda.get(stateB).get(xB);
				// deterministic condition
				// 1) if same children
				if (stateRR.equals(stateBB)){
				    if ((xR.equals(xB)) && (!yR.equals(yB))) {
					// if ( xR.equals(xB) ){
					// promote stateB
					red.add(stateB);
					isPromote = true;
					break;
				    }
			        // 2) if different children
				}else{
				    // TODO: testing
				    if (xR.equals(xB)) {
					if ( !yR.equals(yB) ) {
					    // if ( xR.equals(xB) ){
					    // promote stateB
					    red.add(stateB);
					    isPromote = true;
					    break;
					}else {
					}
				    }
				}
			    }
			    if (isPromote) {
				break;
			    }
			}
		    } // end of condition 1
		    if (isPromote) {
			break;
		    }
		    // merge states
		    if (!isPromote) {
			// merge stateB's children to state R
			if (fsm.delta.get(stateB) != null) {
			    ArrayList<String> keys = new ArrayList<String>();
			    //Collections.addAll(keys, fsm.delta.get(stateB).keySet().toArray(keys));
			    for (String xB : fsm.delta.get(stateB).keySet()) {
				keys.add(xB);
			    }
			    // for (String xB : fsm.delta.get(stateB).keySet()) {
			    for (String xB : keys) {
				String stateBB = fsm.delta.get(stateB).get(xB);
				// if stateR already has transitions
				if (fsm.delta.get(stateR) != null) {
				    // fsm.delta.get(stateR).put(xB, stateBB);
				    String yB = fsm.lambda.get(stateB).get(xB);
				    if (fsm.lambda.get(stateR).get(xB) != null)
					if (!stateR.equals(stateB)) {
					    if (fsm.lambda.get(stateR).get(xB).equals(yB)) {
						String stateRR = fsm.delta.get(stateR).get(xB);
						// for stateR: increase the symbol by offset
						String xBforR = "" + (Integer.valueOf(xB) + fsm.symbolList.size());
						String yBforR = "" + (Integer.valueOf(yB) + fsm.symbolList.size());
						fsm.lambda.get(stateR).put(xBforR, yBforR);
						fsm.delta.get(stateR).put(xBforR, stateRR);
						// for stateB: use the symbol of stateR
						fsm.lambda.get(stateR).put(xB, yB);
						fsm.delta.get(stateR).put(xB, stateBB);
					    } else {
						fsm.delta.get(stateR).put(xB, stateBB);
					    }
					} else {
					    fsm.delta.get(stateR).put(xB, stateBB);
					// create new transitions for stateR					    
					} else 	{
					Map<String, String> dmap = new HashMap<String, String>();
					dmap.put(xB, stateBB);
					fsm.delta.put(stateR, dmap);
				    }
				}
				if (!stateR.equals(stateB)) {
				    fsm.delta.remove(stateB);
				}
				for (String xB : fsm.lambda.get(stateB).keySet()) {
				    String yB = fsm.lambda.get(stateB).get(xB);
				    // if stateR already has output
				    if (fsm.lambda.get(stateR) != null) {
					fsm.lambda.get(stateR).put(xB, yB);
			            // create new outputs for stateR
				    } else {
					Map<String, String> lmap = new HashMap<String, String>();
					lmap.put(xB, yB);
					fsm.lambda.put(stateR, lmap);
				    }
				}
				if (!stateR.equals(stateB)) {
				    fsm.lambda.remove(stateB);
				}
			    }
			    // merge stateB's parent to state R
			    for (String stateP : fsm.delta.keySet()) {
				if (fsm.delta.get(stateP) != null) {
				    for (String xP : fsm.delta.get(stateP).keySet()) {
					if (fsm.delta.get(stateP).get(xP).equals(stateB)) {
					    fsm.delta.get(stateP).put(xP, stateR);
					}
				    }
				}
			    }
			    // remove stateB after merge
			    if (!stateR.equals(stateB)) {
				fsm.stateMap.remove(stateB);
			    }
			}
		    }
		}
	    }
	}
	return fsm;
    }

	
    public static MealyFSM mergeFSM_RPNI(MealyFSM fsm) {
	List<String> statesToMerge = new ArrayList<String>();
	List<String> red = new ArrayList<String>();
	List<String> blue = new ArrayList<String>();
	for (String stateTemp : fsm.stateMap.keySet()) {
	    statesToMerge.add(stateTemp);
	}
	for (String stateToMerge : statesToMerge) {
	    // check if stateToMerge still exists in fsm
	    if (!fsm.stateMap.containsKey(stateToMerge)) {
		continue;
	    }
	    // start from stateToMerge
	    red.add(stateToMerge);
	    // red.add(fsm.initialStateStr);
	    for (String stateTemp : fsm.stateMap.keySet()) {
		blue.add(stateTemp);
	    }
	    blue.remove(fsm.initialStateStr);
	    while (!blue.isEmpty()) {
		boolean isPromote = false;
		String stateB = blue.get(0);
		blue.remove(stateB);
		for (int i = 0; i < red.size(); i++) {
		    String stateR = red.get(i);
		    // Promote the state if the merge will break determinism
		    // Condition 1: child transition conflicts
		    if ((fsm.delta.get(stateR) != null) && (fsm.delta.get(stateB) != null)) {
			for (String xR : fsm.delta.get(stateR).keySet()) {
			    for (String xB : fsm.delta.get(stateB).keySet()) {
				// state R's child
				String stateRR = fsm.delta.get(stateR).get(xR);
				// state B's child
				String stateBB = fsm.delta.get(stateB).get(xB);
				String yR = fsm.lambda.get(stateR).get(xR);
				String yB = fsm.lambda.get(stateB).get(xB);
				// deterministic condition
				// 1) if different children
				if (stateRR.equals(stateBB)){
				    if ((xR.equals(xB)) && (!yR.equals(yB))) {
					// if ( xR.equals(xB) ){
					// promote stateB
					red.add(stateB);
					isPromote = true;
					break;
				    }
				// 2) if same children				    
				}else{
				    if (xR.equals(xB)) {
					// if ( xR.equals(xB) ){
					// promote stateB
					red.add(stateB);
					isPromote = true;
					break;
				    }
				}
			    }
			    if (isPromote) {
				break;
			    }
			}
		    } // end of condition 1
		    if (isPromote) {
			isPromote = false;
		    }
		    // merge states
		    if (!isPromote) {
			// merge stateB's children to state R
			if (fsm.delta.get(stateB) != null) {
			    for (String xB : fsm.delta.get(stateB).keySet()) {
				String stateBB = fsm.delta.get(stateB).get(xB);
				// if stateR already has transitions
				if (fsm.delta.get(stateR) != null) {
				    fsm.delta.get(stateR).put(xB, stateBB);
				// create new transitions for stateR				    
				} else 	{
				    Map<String, String> dmap = new HashMap<String, String>();
				    dmap.put(xB, stateBB);
				    fsm.delta.put(stateR, dmap);
				}
			    }
			    if (!stateR.equals(stateB)) {
				fsm.delta.remove(stateB);
			    }
			    for (String xB : fsm.lambda.get(stateB).keySet()) {
				String yB = fsm.lambda.get(stateB).get(xB);
				// if stateR already has output
				if (fsm.lambda.get(stateR) != null) {
				    fsm.lambda.get(stateR).put(xB, yB);
				// create new outputs for stateR				    
				} else 	{
				    Map<String, String> lmap = new HashMap<String, String>();
				    lmap.put(xB, yB);
				    fsm.lambda.put(stateR, lmap);
				}
			    }
			    if (!stateR.equals(stateB)) {
				fsm.lambda.remove(stateB);
			    }
			}
			// merge stateB's parent to state R
			for (String stateP : fsm.delta.keySet()) {
			    if (fsm.delta.get(stateP) != null) {
				for (String xP : fsm.delta.get(stateP).keySet()) {
				    if (fsm.delta.get(stateP).get(xP).equals(stateB)) {
					fsm.delta.get(stateP).put(xP, stateR);
				    }
				}
			    }
			}
			// remove stateB after merge
			if (!stateR.equals(stateB)) {
			    fsm.stateMap.remove(stateB);
			}
		    }
		}
	    }
	}
	return fsm;
    }

    
    public static MealyFSM composeFSM(MealyFSM fsm1, MealyFSM fsm2) {
	MealyFSM fsm = new MealyFSM();
	return fsm;		
    }

    
    public static int editingDst (MealyFSM fsmA, MealyFSM fsmB) {
	int dst = 0;
	return dst;
    }

    
    // generate actual subset by index sequence
    public static ArrayList<String[][]> getSubset(ArrayList<String[][]> input, int[] subset) {
	ArrayList<String[][]> result = new ArrayList<String[][]>();
	for (int i = 0; i < subset.length; i++)  {
	    result.add(input.get(subset[i]));
	}
	return result;
    }

    
    public static ArrayList<ArrayList<String[][]>> getSubsets(ArrayList<String[][]> input, int k) {
	ArrayList<ArrayList<String[][]>> subsets = new ArrayList<ArrayList<String[][]>>();
	int[] s = new int[k];
	if (k <= input.size()) {
	    // first index sequence: 0, 1, 2, ...
	    for (int i = 0; i < k; i++)	{
		s[i] = i;
	    }
	    subsets.add(getSubset(input, s));
	    for(;;) {
		int i;
		// find position of item that can be incremented
		for (i = k - 1; i >= 0 && s[i] == input.size() - k + i; i--);
		if (i < 0) {
		    break;
		}
		s[i]++;                    // increment this item
		for (++i; i < k; i++) {    // fill up remaining items
		    s[i] = s[i - 1] + 1; 
		}
		subsets.add(getSubset(input, s));
	    }
	}
	return subsets;
    }

    
    // generate actual subset by index sequence
    public static ArrayList<Integer> getIdSubset(ArrayList<Integer> input, int[] subset) {
	ArrayList<Integer> result = new ArrayList<Integer>();
	for (int i = 0; i < subset.length; i++) {
	    result.add(input.get(subset[i]));
	}
	return result;
    }

    
    public static ArrayList<ArrayList<Integer>> getIdSubsets(int arraySize, int k){
	ArrayList<Integer> input = new ArrayList<Integer>(arraySize);
	for (int i = 0; i < arraySize; i++){
	    input.add(i);
	}
	ArrayList<ArrayList<Integer>> subsets = new ArrayList<ArrayList<Integer>>();
	int[] s = new int[k];
	if (k <= input.size()) {
	    // first index sequence: 0, 1, 2, ...
	    for (int i = 0; i < k; i++)	{
		s[i] = i;
	    }
	    subsets.add(getIdSubset(input, s));
	    for(;;) {
		int i;
		// find position of item that can be incremented
		for (i = k - 1; i >= 0 && s[i] == input.size() - k + i; i--);
		if (i < 0) {
		    break;
		}
		s[i]++;                    // increment this item
		for (++i; i < k; i++) {    // fill up remaining items
		    s[i] = s[i - 1] + 1; 
		}
		subsets.add(getIdSubset(input, s));
	    }
	}
	return subsets;
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
	for (Map<String,String> map:fsm.lambda.values()){
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
		String y = fsm.lambda.get(sstate).get(x);
		// remove redundancy
		String word = ""+x+"/"+y+"";
		if (!alphabet.contains(word)){
		    alphabet.add(word);
		    System.out.println(""+x+"/"+y+"");
		}
	    }
	}
	System.out.println("#transitions");
	for (String sstate : fsm.delta.keySet() ){
	    for (String x : fsm.delta.get(sstate).keySet()){
		String dstate = fsm.delta.get(sstate).get(x);
		String y = fsm.lambda.get(sstate).get(x);
		System.out.println(""+sstate+":"+x+"/"+y+">"+dstate);
	    }
	}
	System.out.println("###");
    }

    
    public static void RANSACModelAccurancy (ArrayList<ArrayList<String[]>> tracesAll)	{
	int n = 50;
	int k = 10000;
	int runNum = 100;
	int minSize = 6;
	ArrayList<ArrayList<Integer>> kSubsets = new ArrayList<ArrayList<Integer>>();
	System.out.println("tracesAll.size = " + tracesAll.size());
	int combNum = binomial(tracesAll.size(),n).intValue();
	System.out.println("combination = " + combNum);
	int hitNum = 0;
	int smallerNum = 0;
	int largerNum = 0;
	for (int j = 0; j < runNum; j++){
	    for (int i = 0; i < k; i++){
		// TODO: this approach can generate dup rand numbers
		Random randomno = new Random();
		int trace_num = randomno.nextInt(combNum);
		ArrayList<ArrayList<String[]>> traces = new ArrayList<ArrayList<String[]>>();
		for (int id = 0; id < n; id++){
		    Random rand = new Random();
		    int rand_id = randomno.nextInt(tracesAll.size()-1);
		    traces.add(tracesAll.get(rand_id));
		}
		// build tree fsm
		MealyFSM treeFSM = buildTreeFSM( traces );
		// reduce fsm
		MealyFSM resultFSM = mergeFSM(treeFSM);
		int size = fsmSize(resultFSM);
		if (size == minSize){
		    hitNum = hitNum + 1;
		    break;
		}else if (size < minSize){
		    smallerNum = smallerNum + 1;
		    continue;
		}
	    }
	}
	System.out.println("hitNum = " + hitNum);
	System.out.println("smallerNum = " + smallerNum);
    }
	
	
    public static MealyFSM RANSAC( ArrayList<ArrayList<String[]>> tracesAll, int nTemp, int kTemp, int runNumTemp) {
	// output
	MealyFSM benignFSM = new MealyFSM();
	// minimum num of samples
	// default 50
	int n = nTemp;
	int k = kTemp;
	int runNum = runNumTemp;
	ArrayList<ArrayList<Integer>> kSubsets = new ArrayList<ArrayList<Integer>>();
	System.out.println("tracesAll.size = " + tracesAll.size());
	int combNum = binomial(tracesAll.size(), n).intValue();
	System.out.println("combination = " + combNum);
	int minSize = 30000;
	for (int j = 0; j < runNum; j++) {
	    for (int i = 0; i < k; i++) {
		Random randomno = new Random();
		ArrayList<ArrayList<String[]>> traces = new ArrayList<ArrayList<String[]>>();
		for (int id = 0; id < n; id++) {
		    int rand_id = randomno.nextInt(tracesAll.size() - 1);
		    traces.add(tracesAll.get(rand_id));
		}
		// build tree fsm
		MealyFSM treeFSM = buildTreeFSM(traces);
		printFSM(treeFSM);
		// reduce fsm
		// MealyFSM resultFSM = treeFSM;
		MealyFSM resultFSM = mergeFSM(treeFSM);
		printFSM(resultFSM);
		int size = fsmSize(resultFSM);
		System.out.println("size = "+size);
		if (size < minSize) {
		    minSize = size;
		    benignFSM = resultFSM;
		}
	    }
	}
	System.out.println("minSize = " + minSize);
	return benignFSM;
    }

    
    public static MealyFSM RANSAC_PLUS( ArrayList<ArrayList<String[]>> tracesAll, ArrayList<Integer> symbolList, int nTemp, int alsoNum, int kTemp, int runNumTemp, int maxMismatch) {
	// output
	MealyFSM benignFSM = new MealyFSM();
	// minimum num of samples
	int n = nTemp;
	// minimum num for a good model
	int k = kTemp;
	int runNum = runNumTemp;
	ArrayList<ArrayList<Integer>> kSubsets = new ArrayList<ArrayList<Integer>>();
	System.out.println("tracesAll.size = " + tracesAll.size());
	int combNum = binomial(tracesAll.size(), n).intValue();
	System.out.println("combination = " + combNum);
	int minSize = 30000;
	for (int j = 0; j < runNum; j++) {
	    ArrayList<Integer> k_list = new ArrayList<Integer>();
	    for (int i=0; i<tracesAll.size(); i++) {
		k_list.add(new Integer(i));
	    }
	    Collections.shuffle(k_list);
	    // for each iteration
	    for (int i = 0; i < k; i++) {
		// Random randomno = new Random();
		ArrayList<ArrayList<String[]>> traces = new ArrayList<ArrayList<String[]>>();
		// select n samples
		for (int id = 0; id < n; id++) {
		    int rand_id = k_list.get(id);
		    traces.add(tracesAll.get(rand_id));
		}
		// build tree fsm
		// MealyFSM treeFSM = buildTreeFSM(traces);
		MealyFSM treeFSM = buildTreeFSMWithSymbols(traces, symbolList);
		printFSM(treeFSM);
		// reduce fsm
		MealyFSM resultFSM = mergeFSMHistory(treeFSM);
		printFSM(resultFSM);
		int size = fsmSize(resultFSM);
		ArrayList<ArrayList<String[]>> traces_also = new ArrayList<ArrayList<String[]>>();
		for (int id = n; id < tracesAll.size(); id++) {
		    int rand_id = k_list.get(id);
		    int fitNum = FSMTranverseSingle(resultFSM, tracesAll.get(rand_id));
		    if (fitNum >= maxMismatch)	{
			traces_also.add(tracesAll.get(rand_id));
		    }
		}
		// check if the model should be rejected
		if (traces_also.size() >= alsoNum){	
		    // build tree fsm
		    traces.addAll(traces_also);
		    MealyFSM treeFSM_plus = buildTreeFSM(traces);
		    // reduce fsm
		    MealyFSM resultFSM_plus = mergeFSM(treeFSM_plus);
		    int size_plus = fsmSize(resultFSM_plus);
		    if (size_plus < minSize) {
			minSize = size_plus;
			benignFSM = resultFSM_plus;
		    }
		}
	    }
	}
	System.out.println("minSize = " + minSize);
	printFSM(benignFSM);
	return benignFSM;
    }

	
    //public static MealyFSM RANSAC( ArrayList<ArrayList<String[]>> tracesAll) {
    public static MealyFSM RANSAC_RPNI( ArrayList<ArrayList<String[]>> tracesAll, int nTemp, int kTemp, int runNumTemp) {
	// output
	MealyFSM benignFSM = new MealyFSM();
	// minimum num of samples
	// default 50
	int n = nTemp;
	int k = kTemp;
	int runNum = runNumTemp;
	ArrayList<ArrayList<Integer>> kSubsets = new ArrayList<ArrayList<Integer>>();
	System.out.println("tracesAll.size = " + tracesAll.size());
	int combNum = binomial(tracesAll.size(), n).intValue();
	System.out.println("combination = " + combNum);
	// kSubsets = getIdSubsets(tracesAll.size(), n);
	int minSize = 30000;
	for (int j = 0; j < runNum; j++) {
	    for (int i = 0; i < k; i++) {
		// TODO: this approach can generate dup rand numbers
		Random randomno = new Random();
		ArrayList<ArrayList<String[]>> traces = new ArrayList<ArrayList<String[]>>();
		for (int id = 0; id < n; id++) {
		    int rand_id = randomno.nextInt(tracesAll.size() - 1);
		    traces.add(tracesAll.get(rand_id));
		}
		// build tree fsm
		MealyFSM treeFSM = buildTreeFSM(traces);
		// reduce fsm
		MealyFSM resultFSM = mergeFSM_RPNI(treeFSM);
		int size = fsmSize(resultFSM);
		System.out.println("size = "+size);
		if (size < minSize) {
		    minSize = size;
		    benignFSM = resultFSM;
		}
	    }
	}
	System.out.println("minSize = " + minSize);
	return benignFSM;
    }

    
    public static MealyFSM RANSAC_Simple_Hueristic( ArrayList<ArrayList<String[]>> tracesAll, int nTemp, int kTemp, int runNumTemp) {
	// output
	MealyFSM benignFSM = new MealyFSM();
	// minimum num of samples
	// default 50
	int n = nTemp;
	int k = kTemp;
	int runNum = runNumTemp;
	ArrayList<ArrayList<Integer>> kSubsets = new ArrayList<ArrayList<Integer>>();
	System.out.println("tracesAll.size = " + tracesAll.size());
	int combNum = binomial(tracesAll.size(), n).intValue();
	System.out.println("combination = " + combNum);
	int minSize = 30000;
	for (int j = 0; j < runNum; j++) {
	    for (int i = 0; i < k; i++) {
		// TODO: this approach can generate dup rand numbers
		Random randomno = new Random();
		ArrayList<ArrayList<String[]>> traces = new ArrayList<ArrayList<String[]>>();
		for (int id = 0; id < n; id++) {
		    int rand_id = randomno.nextInt(tracesAll.size() - 1);
		    traces.add(tracesAll.get(rand_id));
		}
		// build tree fsm
		MealyFSM treeFSM = buildTreeFSM(traces);
		// printFSM(treeFSM);
		// reduce fsm
		MealyFSM resultFSM = treeFSM;
		int size = fsmSize(resultFSM);
		System.out.println("size = "+size);
		if (size < minSize) {
		    minSize = size;
		    benignFSM = resultFSM;
		}
	    }
	}
	System.out.println("minSize = " + minSize);
	return benignFSM;
    }

    
    public static MealyFSM Prospex( ArrayList<ArrayList<String[]>> tracesAll) {
	// build tree fsm
	MealyFSM treeFSM = buildTreeFSM(tracesAll);
	// reduce fsm
	MealyFSM resultFSM = mergeFSM(treeFSM);
	return resultFSM;
    }

    
    public static int[] FSMTranverseMulti(MealyFSM fsm, ArrayList<ArrayList<String[]>> tracesAll){
	int traceNum = tracesAll.size();
	int[] assignments = new int[traceNum];
	for (int i = 0; i < traceNum; i++) {
	    ArrayList<String[]> trace = tracesAll.get(i);
	    // set current state to 0
	    fsm.resetState();			
	    for (int j = 0; j < trace.size(); j++){
		String iStr = trace.get(j)[0];
		String oStr = trace.get(j)[1];
		boolean isMatch =  fsm.tranverse(iStr, oStr);
		// strict match condition
		if (isMatch == false){
		    assignments[i] = 1;
		    break;
		}
	    }
	}
	return assignments;
    }

    
    // Theta is the max threshold for match
    public static int[] FSMTranverseMultiTheta(MealyFSM fsm, ArrayList<ArrayList<String[]>> tracesAll, double theta){
	int traceNum = tracesAll.size();
	int[] assignments = new int[traceNum];
	for (int i = 0; i < traceNum; i++) {
	    ArrayList<String[]> trace = tracesAll.get(i);
	    // set current state to 0
	    fsm.resetState();			
	    for (int j = 0; j < trace.size(); j++){
		String iStr = trace.get(j)[0];
		String oStr = trace.get(j)[1];
		boolean isMatch =  fsm.tranverse(iStr, oStr);
		// strict match condition
		if (isMatch == false) {
		    int statesNum = trace.size();
		    if ( (statesNum - j)*1.0/statesNum >= theta ){
			assignments[i] = 1;
			break;
		    }
		}
	    }
	}
	return assignments;
    }

    
    public static int FSMTranverseSingle(MealyFSM fsm, ArrayList<String[]> trace) {
	// int assignments = 0;
	int matches = 0;
	// set current state to 0
	fsm.resetState();
	for (int j = 0; j < trace.size(); j++) {
	    String iStr = trace.get(j)[0];
	    String oStr = trace.get(j)[1];
	    boolean isMatch = fsm.tranverse(iStr, oStr);
	    if (isMatch == false) {
		matches = j;
		break;
	    }
	}
	return matches;
    }

    
    public static int editDistance(String word1, String word2) {
	int len1 = word1.length();
	int len2 = word2.length();
	// len1+1, len2+1, because finally return dp[len1][len2]
	int[][] dp = new int[len1 + 1][len2 + 1];
	for (int i = 0; i <= len1; i++) {
	    dp[i][0] = i;
	}
	for (int j = 0; j <= len2; j++) {
	    dp[0][j] = j;
	}
	//iterate though, and check last char
	for (int i = 0; i < len1; i++) {
	    char c1 = word1.charAt(i);
	    for (int j = 0; j < len2; j++) {
		char c2 = word2.charAt(j);
		//if last two chars equal
		if (c1 == c2) {
		    //update dp value for +1 length
		    dp[i + 1][j + 1] = dp[i][j];
		} else {
		    int replace = dp[i][j] + 1;
		    int insert = dp[i][j + 1] + 1;
		    int delete = dp[i + 1][j] + 1;
		    int min = replace > insert ? insert : replace;
		    min = delete > min ? min : delete;
		    dp[i + 1][j + 1] = min;
		}
	    }
	}
	return dp[len1][len2];
    }

    
    /*
     * edit distance of string array
     * */
    public static int editDistance(String[] word1, String[] word2) {
	int len1 = word1.length;
	int len2 = word2.length;
	// len1+1, len2+1, because finally return dp[len1][len2]
	int[][] dp = new int[len1 + 1][len2 + 1];
	for (int i = 0; i <= len1; i++) {
	    dp[i][0] = i;
	}
	for (int j = 0; j <= len2; j++) {
	    dp[0][j] = j;
	}
	//iterate though, and check last char
	for (int i = 0; i < len1; i++) {
	    String c1 = word1[i];
	    for (int j = 0; j < len2; j++) {
		String c2 = word2[j];
		//if last two chars equal
		if (c1.equals(c2)) {
		    //update dp value for +1 length
		    dp[i + 1][j + 1] = dp[i][j];
		} else {
		    int replace = dp[i][j] + 1;
		    int insert = dp[i][j + 1] + 1;
		    int delete = dp[i + 1][j] + 1;
		    int min = replace > insert ? insert : replace;
		    min = delete > min ? min : delete;
		    dp[i + 1][j + 1] = min;
		}
	    }
	}
	return dp[len1][len2];
    }

    
    /*
     * edit distance of string array
     * */
    public static int editDistance(ArrayList<String[]> word1, ArrayList<String[]> word2) {
	int len1 = word1.size();
	int len2 = word2.size();
	// len1+1, len2+1, because finally return dp[len1][len2]
	int[][] dp = new int[len1 + 1][len2 + 1];
	for (int i = 0; i <= len1; i++) {
	    dp[i][0] = i;
	}
	for (int j = 0; j <= len2; j++) {
	    dp[0][j] = j;
	}
	//iterate though, and check last char
	for (int i = 0; i < len1; i++) {
	    // combine the pair
	    String c1 = word1.get(i)[0]+word1.get(i)[1];
	    for (int j = 0; j < len2; j++) {
		String c2 = word2.get(j)[0]+word2.get(j)[1];
		//if last two chars equal
		if (c1.equals(c2)) {
		    //update dp value for +1 length
		    dp[i + 1][j + 1] = dp[i][j];
		} else {
		    int replace = dp[i][j] + 1;
		    int insert = dp[i][j + 1] + 1;
		    int delete = dp[i + 1][j] + 1;
		    int min = replace > insert ? insert : replace;
		    min = delete > min ? min : delete;
		    dp[i + 1][j + 1] = min;
		}
	    }
	}
	return dp[len1][len2];
    }

    
    public static class TraceData {
	ArrayList<ArrayList<String[]>> tracesAll;
	ArrayList<Integer> symbolList = new ArrayList<>();
	int[] labels;
	TraceData(){}
	TraceData(ArrayList<ArrayList<String[]>> tracesAll, int[] labels){
	    this.tracesAll = tracesAll;
	    this.labels = labels;
	}
	TraceData(ArrayList<ArrayList<String[]>> tracesAll, ArrayList<Integer> symbolList, int[] labels){
	    this.tracesAll = tracesAll;
	    this.symbolList = symbolList;
	    this.labels = labels;
	}
    }

    
    // generate CSV for HTTP
    public static TraceData generateHTTP(int sampleNum, int benignNum, int attackNum, int pollution) throws IOException{
	// Parse log
	// dictionary map: abstract msg to number
	Map<String, String> dMap = new HashMap<String,String>();
	int msgNo = 0;
	// http: request, response pair
	String[] msgPair = {"",""};
	// Parse log output				
	ArrayList<ArrayList<String[]>> tracesAttack = new ArrayList<ArrayList<String[]>>();
	ArrayList<ArrayList<String[]>> tracesBenign = new ArrayList<ArrayList<String[]>>();	
	try {
	    for (int i = 1; i<=attackNum ;i++){
		ArrayList<String[]> traces = new ArrayList<String[]>();
		String filePath = "/Users/tianlongyu/Documents/Workspace/Eclipse/LearnFSM/data/cisco_http_new/cisco-http-a";
		filePath = filePath + i + ".log";
		BufferedReader br = null;
		String sCurrentLine;
		FileReader freader = new FileReader(filePath);
		br = new BufferedReader(freader);
		System.out.println("Attack "+i);
		while ((sCurrentLine = br.readLine()) != null) {
		    String[] splited = sCurrentLine.split("\\s+");
		    // check if first char is #
		    if (splited[0].charAt(0) == '#'){
			continue;
		    }
		    // otherwise get 12th fields msg and 13th msg uri
		    // check request or response
		    String msgDirection = "";
		    String msg = "";
		    if (splited[11].contains(",")){
			msgDirection = "To";
			msg = msgDirection+splited[11]+splited[12];
		    }else{
			msgDirection = "From";
			msg = msgDirection+splited[11];
		    }
		    // check if msg is in dictionary
		    if (dMap.containsKey(msg)){
		    }else{
			msgNo = msgNo + 1;
			dMap.put(msg, ""+msgNo);
		    }
		    if (msgDirection.equals("To")){
			msgPair[0] = dMap.get(msg);
			// handle Post has no response
			if (msg.contains("POST")){
			    msgPair[1] = "0"; // 0 for no response
			    String[] curMsgPair = msgPair.clone();
			    System.out.println("Attack Msg: "+curMsgPair[0]+"/"+curMsgPair[1]);
			    traces.add(curMsgPair);
			}
		    }
		    if (msgDirection.equals("From")){
			msgPair[1] = dMap.get(msg);
			String[] curMsgPair = msgPair.clone();
			System.out.println("Attack Msg: "+curMsgPair[0]+"/"+curMsgPair[1]);		
			traces.add(curMsgPair);
		    }
		}
		tracesAttack.add(traces);
		freader.close();
	    }
	} catch (IOException e) {
	    e.printStackTrace();
	}
	try {
	    for (int i = 1; i<=benignNum ;i++){
		ArrayList<String[]> traces = new ArrayList<String[]>();
		String filePath = "/Users/tianlongyu/Documents/Workspace/Eclipse/LearnFSM/data/cisco_http_new/cisco-ios-http-b";
		filePath = filePath + i + ".log";
		BufferedReader br = null;
		String sCurrentLine;
		FileReader freader = new FileReader(filePath);
		br = new BufferedReader(freader);
		while ((sCurrentLine = br.readLine()) != null)	{
		    String[] splited = sCurrentLine.split("\\s+");
		    // check if first char is #
		    if (splited[0].charAt(0) == '#'){
			continue;
		    }
		    // otherwise get 12th fields msg and 13th msg uri
		    System.out.println("Msg: "+splited[11]+splited[12]);							
		    // check request or response
		    String msgDirection = "";
		    String msg = "";
		    if (splited[11].contains(",")){
			msgDirection = "To";
			msg = msgDirection+splited[11]+splited[12];
		    }else{
			msgDirection = "From";
			msg = msgDirection+splited[11];
		    }
		    // check if msg is in dictionary
		    if (dMap.containsKey(msg)){
		    }else{
			msgNo = msgNo + 1;
			dMap.put(msg, ""+msgNo);
		    }
		    if (msgDirection.equals("To")){
			msgPair[0] = dMap.get(msg);
			// handle Post has no response
			if (msg.contains("POST")){
			    msgPair[1] = "0"; // 0 for no response
			    String[] curMsgPair = msgPair.clone();
			    System.out.println("Benign Msg: "+curMsgPair[0]+"/"+curMsgPair[1]);
			    traces.add(curMsgPair);
			}
		    }
		    if (msgDirection.equals("From")){
			msgPair[1] = dMap.get(msg);
			String[] curMsgPair = msgPair.clone();
			System.out.println("Benign Msg: "+curMsgPair[0]+"/"+curMsgPair[1]);
			traces.add(curMsgPair);
		    }
		}
		tracesBenign.add(traces);
		freader.close();
	    }
	} catch (IOException e)	{
	    e.printStackTrace();
	}
	// Mix traces
	ArrayList<ArrayList<String[]>> tracesAll = new ArrayList<ArrayList<String[]>>();
	// Max trace length
	int maxLen = 0;
	// generate 10/100 traces
	for (int i = 0; i < sampleNum/benignNum; i++){
	    for (int j = 0; j < tracesBenign.size(); j++){
		tracesAll.add(tracesBenign.get(j));
		if (tracesAll.get(j).size() * 2 > maxLen) {
		    maxLen = tracesAll.get(j).size() * 2;
		}
	    }	
	}
	// add labels after tracesAll are created
	int[] labels = new int[tracesAll.size()];
	// pollution % of attacks
	// pollution % of attacks
	// int attackNum = tracesAttack.size();
	int allNum = tracesAll.size();
	int iNum = ( allNum * pollution ) / ( 100 * attackNum );
	int jNum = attackNum;
	for (int i = 0; i < iNum; i++){
	    for (int j = 0; j < jNum; j++){
		int id = allNum*i/iNum + allNum*j/(iNum*jNum);
		tracesAll.set(id, tracesAttack.get(j));
		labels[id] = 1;
	    }			
	}
	// output to csv file
	// message series csv
	FileWriter writer = new FileWriter("ms.csv");
	for (int i=0; i< maxLen; i++ ){
	    writer.append(""+i);
	    writer.append(',');
	}
	writer.append(""+maxLen);
	writer.append('\n');
	for (int i=0; i< tracesAll.size(); i++ ){
	    for (int j=0; j< tracesAll.get(i).size(); j++ ){
		String si = tracesAll.get(i).get(j)[0];
		String so = tracesAll.get(i).get(j)[1];
		writer.append(si);
		writer.append(',');
		writer.append(so);
		writer.append(',');
	    }
	    for (int j=(tracesAll.get(i).size())*2; j<maxLen; j++ ){
		writer.append(""+0);
		writer.append(',');
	    }
	    writer.append(""+0);
	    writer.append('\n');
	}
	writer.flush();
	// editing distance csv
	writer = new FileWriter("editDistance.csv");
	// features
	int tracesNum = tracesAll.size();
	for (int i=0; i< tracesNum - 1; i++ ){
	    writer.append(""+i);
	    writer.append(',');
	}
	writer.append(""+ (tracesNum-1) );
	writer.append('\n');
	writer.flush();
	for (int i=0; i< tracesNum; i++ ){
	    for (int j=0; j< tracesNum; j++ ){
		if (i != j){
		    // calculate the edit distance of two instances
		    int ed = editDistance(tracesAll.get(i), tracesAll.get(j));
		    // output to csv
		    writer.append(""+ed);
		    writer.append(',');
		}				
	    }
	    writer.append(""+ 0 );
	    writer.append('\n');
	}
	writer.flush();
	writer.close();
	return new TraceData(tracesAll, labels);
    }


    // generate CSV for Telnet (Camera)
    public static TraceData generateTelnet(int sampleNum, int benignNum, int attackNum, int pollution) throws IOException{
	// Parse log
	// dictionary map: abstract msg to number
	Map<String, String> dMap = new HashMap<String,String>();
	int msgNo = 0;
	// http: request, response pair
	String[] msgPair = {"",""};
	// Parse log output				
	ArrayList<ArrayList<String[]>> tracesAttack = new ArrayList<ArrayList<String[]>>();
	ArrayList<ArrayList<String[]>> tracesBenign = new ArrayList<ArrayList<String[]>>();	
	for (int i = 1; i<=attackNum ;i++){
	    ArrayList<String[]> traces = new ArrayList<String[]>();
	    BufferedReader br = null;
	    String sCurrentLine;
	    System.out.println("Attack "+i);
	    for (int j = 1; j<=9; j++){
		String[] curMsgPair = {"",""};
		curMsgPair[0] = "1";//"ToTelnetCMD";
		curMsgPair[1] = "2";//"FromTelnetCMD";
		traces.add(curMsgPair);
	    }
	    tracesAttack.add(traces);
	}
	for (int i = 1; i<=benignNum ;i++){
	    ArrayList<String[]> traces = new ArrayList<String[]>();
	    for (int j = 1; j<=i%10; j++){
		String[] curMsgPair = {"",""};
		curMsgPair[0] = "3";//"ToTelnetSYN";
		curMsgPair[1] = "4";//"FromTelnetRST";
		traces.add(curMsgPair);
	    }
	    tracesBenign.add(traces);
	}
	// Mix traces
	ArrayList<ArrayList<String[]>> tracesAll = new ArrayList<ArrayList<String[]>>();
	// Max trace length
	int maxLen = 0;
	// generate 10/100 traces
	for (int i = 0; i < sampleNum/benignNum; i++){
	    for (int j = 0; j < tracesBenign.size(); j++){
		tracesAll.add(tracesBenign.get(j));
		if (tracesAll.get(j).size() * 2 > maxLen) {
		    maxLen = tracesAll.get(j).size() * 2;
		}
	    }	
	}
	// add labels after tracesAll are created
	int[] labels = new int[tracesAll.size()];
	// pollution % of attacks
	// pollution % of attacks
	int allNum = tracesAll.size();
	int iNum = ( allNum * pollution ) / ( 100 * attackNum );
	int jNum = attackNum;
	for (int i = 0; i < iNum; i++){
	    for (int j = 0; j < jNum; j++){
		int id = allNum*i/iNum + allNum*j/(iNum*jNum);
		tracesAll.set(id, tracesAttack.get(j));
		labels[id] = 1;
	    }			
	}
	// output to csv file
	// message series csv
	FileWriter writer = new FileWriter("ms.csv");
	for (int i=0; i< maxLen; i++ ){
	    writer.append(""+i);
	    writer.append(',');
	}
	writer.append(""+maxLen);
	writer.append('\n');
	for (int i=0; i< tracesAll.size(); i++ ){
	    for (int j=0; j< tracesAll.get(i).size(); j++ ){
		String si = tracesAll.get(i).get(j)[0];
		String so = tracesAll.get(i).get(j)[1];
		writer.append(si);
		writer.append(',');
		writer.append(so);
		writer.append(',');
	    }
	    for (int j=(tracesAll.get(i).size())*2; j<maxLen; j++ ){
		writer.append(""+0);
		writer.append(',');
	    }
	    writer.append(""+0);
	    writer.append('\n');
	}
	writer.flush();
	// ngram csv
	// editing distance csv
	writer = new FileWriter("editDistance.csv");
	// features
	int tracesNum = tracesAll.size();
	for (int i=0; i< tracesNum - 1; i++ ){
	    writer.append(""+i);
	    writer.append(',');
	}
	writer.append(""+ (tracesNum-1) );
	writer.append('\n');
	writer.flush();
	for (int i=0; i< tracesNum; i++ ){
	    for (int j=0; j< tracesNum; j++ ){
		if (i != j){
		    // calculate the edit distance of two instances
		    int ed = editDistance(tracesAll.get(i), tracesAll.get(j));
		    // output to csv
		    writer.append(""+ed);
		    writer.append(',');
		}				
	    }
	    writer.append(""+ 0 );
	    writer.append('\n');
	}
	writer.flush();
	writer.close();
	return new TraceData(tracesAll, labels);
    }

    
    // generate CSV for SNMP 
    public static TraceData generateCSV_SNMP(int sampleNum, int benignNum, int attackNum, int pollution) throws IOException{
	// Parse log
	// dictionary map: abstract msg to number
	Map<String, String> dMap = new HashMap<String,String>();
	int msgNo = 0;
	// http: request, response pair
	String[] msgPair = {"",""};
	// Parse log output				
	ArrayList<ArrayList<String[]>> tracesAttack = new ArrayList<ArrayList<String[]>>();
	ArrayList<ArrayList<String[]>> tracesBenign = new ArrayList<ArrayList<String[]>>();	
	try {
	    for (int i = 1; i<=attackNum ;i++){
		ArrayList<String[]> traces = new ArrayList<String[]>();
		String filePath = "/Users/tianlong/eclipse-workspace/eiot_code/data/cisco_ios_snmp_new/cisco-ios-snmp-a";
		filePath = filePath + i + ".log";
		BufferedReader br = null;
		String sCurrentLine;
		FileReader freader = new FileReader(filePath);
		br = new BufferedReader(freader);
		System.out.println("Attack "+i);
		int paired = 0;
		while ((sCurrentLine = br.readLine()) != null)	{
		    String[] splited = sCurrentLine.split("\\s+");
		    // check if first char is #
		    if (splited[0].charAt(0) == '#'){
			continue;
		    }
		    // otherwise get 12th fields msg and 13th msg uri
		    System.out.println("Msg: "+splited[11]+splited[12]);							
		    // check request or response
		    String msgDirection = "";
		    String msg = "";
		    if (splited[11].contains("request")){
			msgDirection = "To";
			msg = msgDirection+splited[11]+splited[12];
		    }else{
			msgDirection = "From";
			msg = msgDirection+splited[11]+splited[12];
		    }
		    // check if msg is in dictionary
		    if (dMap.containsKey(msg)){
		    }else{
			msgNo = msgNo + 1;
			dMap.put(msg, ""+msgNo);
		    }
		    if (msgDirection.equals("To")){
			msgPair[0] = dMap.get(msg);
			// handle Post has no response
			if (paired == 1){
			    msgPair[1] = "0"; // 0 for no response
			    String[] curMsgPair = msgPair.clone();
			    System.out.println("Attack Msg: "+curMsgPair[0]+"/"+curMsgPair[1]);
			    traces.add(curMsgPair);
			    paired = 0;
			}else{
			    paired = 1;
			}
		    }
		    if (msgDirection.equals("From")){
			msgPair[1] = dMap.get(msg);
			String[] curMsgPair = msgPair.clone();
			System.out.println("Attack Msg: "+curMsgPair[0]+"/"+curMsgPair[1]);		
			traces.add(curMsgPair);
			paired = 0;
		    }
		}
		tracesAttack.add(traces);
		freader.close();
	    }
	} catch (IOException e)	{
	    e.printStackTrace();
	}
	try {
	    for (int i = 1; i<=benignNum ;i++)	{
		ArrayList<String[]> traces = new ArrayList<String[]>();
		String filePath = "/Users/tianlong/eclipse-workspace/eiot_code/data/cisco_ios_snmp_new/cisco-ios-snmp-b";
		filePath = filePath + i + ".log";
		BufferedReader br = null;
		String sCurrentLine;
		FileReader freader = new FileReader(filePath);
		br = new BufferedReader(freader);
		int paired = 0;
		while ((sCurrentLine = br.readLine()) != null){
		    String[] splited = sCurrentLine.split("\\s+");
		    // check if first char is #
		    if (splited[0].charAt(0) == '#'){
			continue;
		    }
		    // otherwise get 12th fields msg and 13th msg uri
		    System.out.println("Msg: "+splited[11]+splited[12]);							
		    // check request or response
		    String msgDirection = "";
		    String msg = "";
		    if (splited[11].contains("request")){
			msgDirection = "To";
			msg = msgDirection+splited[11]+splited[12];
		    }else{
			msgDirection = "From";
			msg = msgDirection+splited[11]+splited[12];
		    }
		    // check if msg is in dictionary
		    if (dMap.containsKey(msg)){
		    }else{
			msgNo = msgNo + 1;
			dMap.put(msg, ""+msgNo);
		    }
		    if (msgDirection.equals("To")){
			msgPair[0] = dMap.get(msg);
			if (paired == 1){
			    msgPair[1] = "0"; // 0 for no response
			    String[] curMsgPair = msgPair.clone();
			    System.out.println("Attack Msg: "+curMsgPair[0]+"/"+curMsgPair[1]);
			    traces.add(curMsgPair);
			    paired = 0;
			}else{
			    paired = 1;
			}
		    }
		    if (msgDirection.equals("From")){
			msgPair[1] = dMap.get(msg);
			String[] curMsgPair = msgPair.clone();
			System.out.println("Benign Msg: "+curMsgPair[0]+"/"+curMsgPair[1]);
			traces.add(curMsgPair);
			paired = 0;
		    }
		}
		tracesBenign.add(traces);
		freader.close();
	    }
	} catch (IOException e)	{
	    e.printStackTrace();
	}
	// Mix traces
	ArrayList<ArrayList<String[]>> tracesAll = new ArrayList<ArrayList<String[]>>();
	// Max trace length
	int maxLen = 0;
	// generate 10/100 traces
	for (int i = 0; i < sampleNum/benignNum; i++){
	    for (int j = 0; j < tracesBenign.size(); j++){
		tracesAll.add(tracesBenign.get(j));
		if (tracesAll.get(j).size() * 2 > maxLen) {
		    maxLen = tracesAll.get(j).size() * 2;
		}
	    }	
	}
	// add labels after tracesAll are created
	int[] labels = new int[tracesAll.size()];
	// record max trace length
	// pollution % of attacks
	//int attackNum = tracesAttack.size();
	int allNum = tracesAll.size();
	int iNum = ( allNum * pollution ) / ( 100 * attackNum );
	int jNum = attackNum;
	for (int i = 0; i < iNum; i++){
	    for (int j = 0; j < jNum; j++){
		int id = allNum*i/iNum + allNum*j/(iNum*jNum);
		tracesAll.set(id, tracesAttack.get(j));
		labels[id] = 1;
	    }			
	}
	// output to csv file
	// message series csv
	FileWriter writer = new FileWriter("ms.csv");
	for (int i=0; i< maxLen; i++ ){
	    writer.append(""+i);
	    writer.append(',');
	}
	writer.append(""+maxLen);
	writer.append('\n');
	for (int i=0; i< tracesAll.size(); i++ ){
	    for (int j=0; j< tracesAll.get(i).size(); j++ ){
		String si = tracesAll.get(i).get(j)[0];
		String so = tracesAll.get(i).get(j)[1];
		writer.append(si);
		writer.append(',');
		writer.append(so);
		writer.append(',');
	    }
	    for (int j=(tracesAll.get(i).size())*2; j<maxLen; j++ ){
		writer.append(""+0);
		writer.append(',');
	    }
	    writer.append(""+0);
	    writer.append('\n');
	}
	writer.flush();
	// ngram csv
	// editing distance csv
	writer = new FileWriter("editDistance.csv");
	// features
	int tracesNum = tracesAll.size();
	for (int i=0; i< tracesNum - 1; i++ ){
	    writer.append(""+i);
	    writer.append(',');
	}
	writer.append(""+ (tracesNum-1) );
	writer.append('\n');
	writer.flush();
	for (int i=0; i< tracesNum; i++ ){
	    for (int j=0; j< tracesNum; j++ ){
		if (i != j){
		    // calculate the edit distance of two instances
		    int ed = editDistance(tracesAll.get(i), tracesAll.get(j));
		    // output to csv
		    writer.append(""+ed);
		    writer.append(',');
		}				
	    }
	    writer.append(""+ 0 );
	    writer.append('\n');
	}
	writer.flush();
	writer.close();
	return new TraceData(tracesAll, labels);
    }

    
    // generate CSV for AlexaDNS 
    public static TraceData generateCSV_AlexaDNS(int sampleNum, int benignNum, int attackNum, int pollution) throws IOException{
	// Parse log
	// dictionary map: abstract msg to number
	Map<String, String> dMap = new HashMap<String,String>();
	int msgNo = 0;
	// http: request, response pair
	String[] msgPair = {"",""};
	// Parse log output				
	ArrayList<ArrayList<String[]>> tracesAttack = new ArrayList<ArrayList<String[]>>();
	ArrayList<ArrayList<String[]>> tracesBenign = new ArrayList<ArrayList<String[]>>();	
	try {
	    for (int i = 1; i<=attackNum ;i++)	{
		ArrayList<String[]> traces = new ArrayList<String[]>();
		String filePath = "/Users/tianlong/eclipse-workspace/eiot_code/data/alexa_dns/alexa-dns-a";
		filePath = filePath + i + ".log";
		BufferedReader br = null;
		String sCurrentLine;
		FileReader freader = new FileReader(filePath);
		br = new BufferedReader(freader);
		int paired = 0;
		while ((sCurrentLine = br.readLine()) != null){
		    String[] splited = sCurrentLine.split("\\s+");
		    // check if first char is #
		    if (splited[0].charAt(0) == '#'){
			continue;
		    }
		    // otherwise get 12th fields msg and 13th msg uri
		    // check pair splited[11] cmd and splited[12] flags
		    String msg1 = splited[11];
		    String msg2 = splited[12];
		    // check if msg is in dictionary
		    if (dMap.containsKey(msg1)){
		    }else{
			msgNo = msgNo + 1;
			dMap.put(msg1, ""+msgNo);
			System.out.println(""+msgNo+":"+msg1);
		    }
		    if (dMap.containsKey(msg2)){
		    }else{
			msgNo = msgNo + 1;
			dMap.put(msg2, ""+msgNo);
			System.out.println(""+msgNo+":"+msg2);
		    }
		    msgPair[0] = dMap.get(msg1);
		    msgPair[1] = dMap.get(msg2);
		    String[] curMsgPair = msgPair.clone();
		    traces.add(curMsgPair);
		}
		tracesAttack.add(traces);
		freader.close();
	    }
	} catch (IOException e)	{
	    e.printStackTrace();
	}
	try {
	    for (int i = 1; i<=benignNum ;i++){
		ArrayList<String[]> traces = new ArrayList<String[]>();
		String filePath = "/Users/tianlong/eclipse-workspace/eiot_code/data/alexa_dns/alexa-dns-b";
		filePath = filePath + i + ".log";
		BufferedReader br = null;   
		String sCurrentLine;
		FileReader freader = new FileReader(filePath);
		br = new BufferedReader(freader);
		int paired = 0;
		while ((sCurrentLine = br.readLine()) != null)	{
		    String[] splited = sCurrentLine.split("\\s+");
		    // check if first char is #
		    if (splited[0].charAt(0) == '#'){
			continue;
		    }
		    // otherwise get 12th fields msg and 13th msg uri
		    // check pair splited[11] cmd and splited[12] flags
		    String msg1 = splited[11];
		    String msg2 = splited[12];
		    // check if msg is in dictionary
		    if (dMap.containsKey(msg1)){
		    } else{
			msgNo = msgNo + 1;
			dMap.put(msg1, ""+msgNo);
			System.out.println(""+msgNo+":"+msg1);
		    }
		    if (dMap.containsKey(msg2)){
		    }else{
			msgNo = msgNo + 1;
			dMap.put(msg2, ""+msgNo);
			System.out.println(""+msgNo+":"+msg2);
		    }
		    msgPair[0] = dMap.get(msg1);
		    msgPair[1] = dMap.get(msg2);
		    String[] curMsgPair = msgPair.clone();
		    traces.add(curMsgPair);
		}
		tracesBenign.add(traces);
		freader.close();
	    }
	} catch (IOException e){
	    e.printStackTrace();
	}
	// Mix traces
	ArrayList<ArrayList<String[]>> tracesAll = new ArrayList<ArrayList<String[]>>();
	// Max trace length
	int maxLen = 0;
	// generate 10/100 traces
	for (int i = 0; i < sampleNum/benignNum; i++){
	    for (int j = 0; j < tracesBenign.size(); j++){
		tracesAll.add(tracesBenign.get(j));
		if (tracesAll.get(j).size() * 2 > maxLen) {
		    maxLen = tracesAll.get(j).size() * 2;
		}
	    }	
	}
	// add labels after tracesAll are created
	int[] labels = new int[tracesAll.size()];
	// record max trace length
	// pollution % of attacks
	//int attackNum = tracesAttack.size();
	int allNum = tracesAll.size();
	int iNum = ( allNum * pollution ) / ( 100 * attackNum );
	int jNum = attackNum;
	for (int i = 0; i < iNum; i++){
	    for (int j = 0; j < jNum; j++){
		int id = allNum*i/iNum + allNum*j/(iNum*jNum);
		tracesAll.set(id, tracesAttack.get(j));
		labels[id] = 1;
	    }			
	}
	// output to csv file
	// message series csv
	// FileWriter writer = new FileWriter("snmp_ms.csv");
	FileWriter writer = new FileWriter("ms.csv");
	for (int i=0; i< maxLen; i++ ){
	    writer.append(""+i);
	    writer.append(',');
	}
	writer.append(""+maxLen);
	writer.append('\n');
	for (int i=0; i< tracesAll.size(); i++ ){
	    for (int j=0; j< tracesAll.get(i).size(); j++ ){
		String si = tracesAll.get(i).get(j)[0];
		String so = tracesAll.get(i).get(j)[1];
		writer.append(si);
		writer.append(',');
		writer.append(so);
		writer.append(',');
	    }
	    for (int j=(tracesAll.get(i).size())*2; j<maxLen; j++ ){
		writer.append(""+0);
		writer.append(',');
	    }
	    writer.append(""+0);
	    writer.append('\n');
	}
	writer.flush();
	// ngram csv
	// editing distance csv
	writer = new FileWriter("editDistance.csv");
	// features
	int tracesNum = tracesAll.size();
	for (int i=0; i< tracesNum - 1; i++ ){
	    writer.append(""+i);
	    writer.append(',');
	}
	writer.append(""+ (tracesNum-1) );
	writer.append('\n');
	writer.flush();
	for (int i=0; i< tracesNum; i++ ){
	    for (int j=0; j< tracesNum; j++ ){
		if (i!=j) {
		    int ed = editDistance(tracesAll.get(i), tracesAll.get(j));
		    // output to csv
		    writer.append(""+ed);
		    writer.append(',');
		}				
	    }
	    writer.append(""+ 0 );
	    writer.append('\n');
	}
	writer.flush();
	writer.close();
	return new TraceData(tracesAll, labels);
    }
	
    // generate CSV for HuelightHTTP
    // public static TraceData generateCSV_HuelightHTTP(int sampleNum, int benignNum, int attackNum, int pollution) throws IOException{
    public static TraceData generateCSV_HuelightHTTP(String attackPath, String benignPath, int sampleNum, int benignNum, int attackNum, int pollution) throws IOException{
	// Parse log
	// dictionary map: abstract msg to number
	Map<String, String> dMap = new HashMap<String,String>();
	int msgNo = 0;
	// http: request, response pair
	String[] msgPair = {"",""};
	ArrayList<Integer> symbolList = new ArrayList<>();
	// Parse log output				
	ArrayList<ArrayList<String[]>> tracesAttack = new ArrayList<ArrayList<String[]>>();
	ArrayList<ArrayList<String[]>> tracesBenign = new ArrayList<ArrayList<String[]>>();	
	try {
	    for (int i = 1; i<=attackNum ;i++)	{
		ArrayList<String[]> traces = new ArrayList<String[]>();
		String filePath = attackPath;
		filePath = filePath + i + ".log";
		BufferedReader br = null;
		String sCurrentLine;
		FileReader freader = new FileReader(filePath);
		br = new BufferedReader(freader);
		while ((sCurrentLine = br.readLine()) != null)	{
		    String[] splited = sCurrentLine.split("\\s+");
		    // check if first char is #
		    if (splited[0].charAt(0) == '#'){
			continue;
		    }
		    // check pair splited[11] cmd and splited[12] flags
		    String msg1 = splited[11];
		    String msg2 = splited[12];
		    // check if msg is in dictionary
		    if (dMap.containsKey(msg1)){
		    }else{
			msgNo = msgNo + 1;
			dMap.put(msg1, ""+msgNo);
			System.out.println(""+msgNo+":"+msg1);
			symbolList.add(msgNo);
		    }
		    if (dMap.containsKey(msg2)){
		    }else{
			msgNo = msgNo + 1;
			dMap.put(msg2, ""+msgNo);
			System.out.println(""+msgNo+":"+msg2);
			symbolList.add(msgNo);
		    }
		    msgPair[0] = dMap.get(msg1);
		    msgPair[1] = dMap.get(msg2);
		    String[] curMsgPair = msgPair.clone();
		    System.out.println("Attack Msg: "+curMsgPair[0]+"/"+curMsgPair[1]);
		    traces.add(curMsgPair);
		}
		tracesAttack.add(traces);
		freader.close();
	    }
	} catch (IOException e)	{
	    e.printStackTrace();
	}
	try {
	    for (int i = 1; i<=benignNum ;i++)	{
		ArrayList<String[]> traces = new ArrayList<String[]>();
		String filePath = benignPath;
		filePath = filePath + i + ".log";
		BufferedReader br = null;   
		String sCurrentLine;
		FileReader freader = new FileReader(filePath);
		br = new BufferedReader(freader);
		while ((sCurrentLine = br.readLine()) != null){
		    String[] splited = sCurrentLine.split("\\s+");
		    // check if first char is #
		    if (splited[0].charAt(0) == '#'){
			continue;
		    }
		    // check pair splited[11] cmd and splited[12] flags
		    String msg1 = splited[11];
		    String msg2 = splited[12];
		    // check if msg is in dictionary
		    if (dMap.containsKey(msg1)){
		    }else{
			msgNo = msgNo + 1;
			dMap.put(msg1, ""+msgNo);
			System.out.println(""+msgNo+":"+msg1);
			symbolList.add(msgNo);
		    }
		    if (dMap.containsKey(msg2)){
		    }else{
			msgNo = msgNo + 1;
			dMap.put(msg2, ""+msgNo);
			System.out.println(""+msgNo+":"+msg2);
			symbolList.add(msgNo);
		    }
		    msgPair[0] = dMap.get(msg1);
		    msgPair[1] = dMap.get(msg2);
		    String[] curMsgPair = msgPair.clone();
		    traces.add(curMsgPair);
		}
		tracesBenign.add(traces);
		freader.close();
	    }
	} catch (IOException e)	{
	    e.printStackTrace();
	}
	// Mix traces
	ArrayList<ArrayList<String[]>> tracesAll = new ArrayList<ArrayList<String[]>>();
	// Max trace length
	int maxLen = 0;
	// generate 10/100 traces
	for (int i = 0; i < sampleNum/benignNum; i++){
	    for (int j = 0; j < tracesBenign.size(); j++){
		tracesAll.add(tracesBenign.get(j));
		if (tracesAll.get(j).size() * 2 > maxLen) {
		    maxLen = tracesAll.get(j).size() * 2;
		}
	    }	
	}
	// add labels after tracesAll are created
	int[] labels = new int[tracesAll.size()];
	// record max trace length
	// pollution % of attacks
	int allNum = tracesAll.size();
	int iNum = ( allNum * pollution ) / ( 100 * attackNum );
	int jNum = attackNum;
	for (int i = 0; i < iNum; i++){
	    for (int j = 0; j < jNum; j++){
		int id = allNum*i/iNum + allNum*j/(iNum*jNum);
		tracesAll.set(id, tracesAttack.get(j));
		labels[id] = 1;
	    }			
	}
	// output to csv file
	// message series csv
	FileWriter writer = new FileWriter("ms.csv");
	for (int i=0; i< maxLen; i++ ){
	    writer.append(""+i);
	    writer.append(',');
	}
	writer.append(""+maxLen);
	writer.append('\n');
	for (int i=0; i< tracesAll.size(); i++ ){
	    for (int j=0; j< tracesAll.get(i).size(); j++ ){
		String si = tracesAll.get(i).get(j)[0];
		String so = tracesAll.get(i).get(j)[1];
		writer.append(si);
		writer.append(',');
		writer.append(so);
		writer.append(',');
	    }
	    for (int j=(tracesAll.get(i).size())*2; j<maxLen; j++ ){
		writer.append(""+0);
		writer.append(',');
	    }
	    writer.append(""+0);
	    writer.append('\n');
	}
	writer.flush();
	// ngram csv
	// editing distance csv
	writer = new FileWriter("editDistance.csv");
	// features
	int tracesNum = tracesAll.size();
	for (int i=0; i< tracesNum - 1; i++ ){
	    writer.append(""+i);
	    writer.append(',');
	}
	writer.append(""+ (tracesNum-1) );
	writer.append('\n');
	writer.flush();
	for (int i=0; i< tracesNum; i++ ){
	    for (int j=0; j< tracesNum; j++ ){
		if (i != j){
		    int ed = editDistance(tracesAll.get(i), tracesAll.get(j));
		    // output to csv
		    writer.append(""+ed);
		    writer.append(',');
		}				
	    }
	    writer.append(""+ 0 );
	    writer.append('\n');
	}
	writer.flush();
	writer.close();
	return new TraceData(tracesAll, symbolList, labels);
    }

    
    // generate CSV for SMB
    public static TraceData generateCSV_SMB(int sampleNum, int benignNum, int attackNum, int pollution) throws IOException{
	// Parse log
	// dictionary map: abstract msg to number
	Map<String, String> dMap = new HashMap<String,String>();
	int msgNo = 0;
	// http: request, response pair
	String[] msgPair = {"",""};
	// Parse log output				
	ArrayList<ArrayList<String[]>> tracesAttack = new ArrayList<ArrayList<String[]>>();
	ArrayList<ArrayList<String[]>> tracesBenign = new ArrayList<ArrayList<String[]>>();	
	try {
	    for (int i = 1; i<=attackNum ;i++){
		ArrayList<String[]> traces = new ArrayList<String[]>();
		String filePath = "/Users/tianlongyu/Documents/Workspace/Eclipse/LearnFSM/data/freenas_smb_new/freenas-smb-a";
		filePath = filePath + i + ".log";
		BufferedReader br = null;
		String sCurrentLine;
		FileReader freader = new FileReader(filePath);
		br = new BufferedReader(freader);
		System.out.println("Attack "+i);
		while ((sCurrentLine = br.readLine()) != null){
		    String[] splited = sCurrentLine.split("\\s+");
		    // check if first char is #
		    if (splited[0].charAt(0) == '#'){
			continue;
		    }
		    // otherwise get 12th fields msg and 13th msg uri
		    System.out.println("Msg: "+splited[11]+"/"+splited[12]);							
		    // check pair splited[11] cmd and splited[12] flags
		    String msg1 = "cmd:"+splited[11];
		    String msg2 = "flags:"+splited[12];
		    // check if msg is in dictionary
		    if (dMap.containsKey(msg1)){
		    }else{
			msgNo = msgNo + 1;
			dMap.put(msg1, ""+msgNo);
		    }
		    if (dMap.containsKey(msg2)){
		    }else{
			msgNo = msgNo + 1;
			dMap.put(msg2, ""+msgNo);
		    }
		    msgPair[0] = dMap.get(msg1);
		    msgPair[1] = dMap.get(msg2);
		    String[] curMsgPair = msgPair.clone();
		    System.out.println("Attack Msg: "+curMsgPair[0]+"/"+curMsgPair[1]);
		    traces.add(curMsgPair);
		}
		tracesAttack.add(traces);
		freader.close();
	    }
	} catch (IOException e){
	    e.printStackTrace();
	}
	try {
	    for (int i = 1; i<=benignNum; i++)	{
		ArrayList<String[]> traces = new ArrayList<String[]>();
		String filePath = "/Users/tianlongyu/Documents/Workspace/Eclipse/LearnFSM/data/freenas_smb_new/freenas-smb-b";
		filePath = filePath + i + ".log";
		BufferedReader br = null;
		String sCurrentLine;
		FileReader freader = new FileReader(filePath);
		br = new BufferedReader(freader);
		int paired = 0;
		System.out.println("Benign "+i);
		while ((sCurrentLine = br.readLine()) != null)	{
		    String[] splited = sCurrentLine.split("\\s+");
		    // check if first char is #
		    if (splited[0].charAt(0) == '#'){
			continue;
		    }
		    // otherwise get 12th fields msg and 13th msg uri
		    System.out.println("Msg: "+splited[11]+splited[12]);							
		    // check pair splited[11] cmd and splited[12] flags
		    String msg1 = "cmd:"+splited[11];
		    String msg2 = "flags:"+splited[12];
		    // check if msg is in dictionary
		    if (dMap.containsKey(msg1)){
		    }else{
			msgNo = msgNo + 1;
			dMap.put(msg1, ""+msgNo);
		    }
		    if (dMap.containsKey(msg2)){
		    }else{
			msgNo = msgNo + 1;
			dMap.put(msg2, ""+msgNo);
		    }
		    msgPair[0] = dMap.get(msg1);
		    msgPair[1] = dMap.get(msg2);
		    String[] curMsgPair = msgPair.clone();
		    System.out.println("Benign Msg: "+curMsgPair[0]+"/"+curMsgPair[1]);
		    traces.add(curMsgPair);
		}
		tracesBenign.add(traces);
		freader.close();
	    }
	} catch (IOException e) {
	    e.printStackTrace();
	}
	// Mix traces
	ArrayList<ArrayList<String[]>> tracesAll = new ArrayList<ArrayList<String[]>>();
	// Max trace length
	int maxLen = 0;
	// generate sampleNum of traces
	for (int i = 0; i < sampleNum/benignNum; i++){
	    for (int j = 0; j < tracesBenign.size(); j++){
		tracesAll.add(tracesBenign.get(j));
		if (tracesAll.get(j).size() * 2 > maxLen) {
		    maxLen = tracesAll.get(j).size() * 2;
		}
	    }
	}
	// add labels after tracesAll are created
	int[] labels = new int[tracesAll.size()];
	int allNum = tracesAll.size();
	int iNum = ( allNum * pollution ) / ( 100 * attackNum );
	int jNum = attackNum;
	for (int i = 0; i < iNum; i++){
	    for (int j = 0; j < jNum; j++){
		int id = allNum*i/iNum + allNum*j/(iNum*jNum);
		tracesAll.set(id, tracesAttack.get(j));
		labels[id] = 1;
	    }			
	}
	// output to csv file
	// message series csv
	// FileWriter writer = new FileWriter("freenas_smb_ms.csv");
	FileWriter writer = new FileWriter("ms.csv");
	// for (int i=0; i< tracesAll.size(); i++ ){
	for (int i=0; i< maxLen; i++ ){
	    writer.append(""+i);
	    writer.append(',');
	}
	writer.append(""+maxLen);
	writer.append('\n');
	for (int i=0; i< tracesAll.size(); i++ ){
	    for (int j=0; j< tracesAll.get(i).size(); j++ ){
		String si = tracesAll.get(i).get(j)[0];
		String so = tracesAll.get(i).get(j)[1];
		writer.append(si);
		writer.append(',');
		writer.append(so);
		writer.append(',');
	    }
	    for (int j=(tracesAll.get(i).size())*2; j<maxLen; j++ ){
		writer.append(""+0);
		writer.append(',');
	    }
	    writer.append(""+0);
	    writer.append('\n');
	}
	writer.flush();
	// ngram csv
	// editing distance csv
	writer = new FileWriter("editDistance.csv");
	// features
	int tracesNum = tracesAll.size();
	for (int i=0; i< tracesNum - 1; i++ ){
	    writer.append(""+i);
	    writer.append(',');
	}
	writer.append(""+ (tracesNum-1) );
	writer.append('\n');
	writer.flush();
	for (int i=0; i< tracesNum; i++ ){
	    for (int j=0; j< tracesNum; j++ ){
		if (i != j){
		    int ed = editDistance(tracesAll.get(i), tracesAll.get(j));
		    // output to csv
		    writer.append(""+ed);
		    writer.append(',');
		}				
	    }
	    writer.append(""+ 0 );
	    writer.append('\n');
	}
	writer.flush();
	writer.close();
	return new TraceData(tracesAll, labels);
    }
	
	
    public static float[] metrics (int[] labels, int[] assignments){
	float[] output = {0,0,0,0,0,0,0,0,0,0,0};
	int total = labels.length;
	int fp = 0;
	int fn = 0;
	int tp = 0;
	int tn = 0;
	float fpr = 0;
	float tpr = 0;
	float fnr = 0;
	float tnr = 0;
	float precision = 0;
	float recall = 0;
	float fscore = 0;
	// ROC 
	for (int i=0; i < total; i++ ){
	    // FP: 0 in labels, 1 in assignments
	    if ( (labels[i] == 0 ) && (assignments[i] == 1) ) {
		fp ++;
	    }
	    // FN: 1 in labels, 0 in assignments
	    if ( (labels[i] == 1 ) && (assignments[i] == 0) ) {
		fn ++;
	    }
	    // TP: 1 in labels, 1 in assignments
	    if ( (labels[i] == 1 ) && (assignments[i] == 1) ) {
		tp ++;
	    }
	    // TN: 0 in labels, 0 in assignments
	    if ( (labels[i] == 0 ) && (assignments[i] == 0) ) {
		tn ++;
	    }
	}
	// fpr
	fpr = ((float) fp)/(fp + tn);
	// tpr
	tpr = ((float) tp)/(tp + fn);
	// fnr
	fnr = ((float) fn)/(tp + fn);
	// tnr
	tnr = ((float) tn)/(fp + tn);
	// precision
	precision = ((float) tp)/(tp + fp);
	// recall
	recall = ((float) tp)/(tp + fn);
	// fscore
	if (tp == 0)   {
	    fscore = 0;
	}else{
	    fscore = ((float) 2 * precision * recall)/(precision + recall);
	}
	System.out.printf("fp = %d \n", fp );
	System.out.printf("tp = %d \n", tp );
	System.out.printf("fn = %d \n", fn );
	System.out.printf("tn = %d \n", tn );
	System.out.printf("fpr = %f \n", fpr );
	System.out.printf("tpr = %f \n", tpr );
	System.out.printf("fnr = %f \n", fnr );
	System.out.printf("tnr = %f \n", tnr );
	System.out.printf("precision = %f \n", precision );
	System.out.printf("recall = %f \n", recall );
	System.out.printf("fscore = %f \n", fscore );
	output[0] = fp;
	output[1] = tp;
	output[2] = fn;
	output[3] = tn;
	output[4] = fpr;
	output[5] = tpr;
	output[6] = fnr;
	output[7] = tnr;
	output[8] = precision;
	output[9] = recall;
	output[10] = fscore;
	return output;
    }

    
    public static void main(String[] args) throws Exception{
	System.out.println("main");			
	// Data Inputs
	// testcases
	// 1: http
	// 2: snmp
	// 3: smb
	// 4: router/switch cmp
	// 5: camera telnet
	// 6: alexa dns
	// 7: huelight http synthesize
	// 71: huelight http user
	int testcase = 7;
		
	// 1: our RANSAC
	// 111: our RANSAC - best parameter
	// 11: basic RPNI
	// 12: simple hueristic
	// 2: Ngram + Xmeans
	// 3: Editing distance + Single hierachy
	// 4: Prospex
	int approach = 1;
	
	ArrayList<float[]> rocList = new ArrayList<float[]>();
	// Pollution percentage
	// 10: 10 % pollution
	int pollution = 10;
		
	int sampleNum = 1000;//1280;//1000;
	int benignNum = 100;//1280;//1280;
	int attackNum = 100;
	
	// Our RANSAC
	// number of samples
	int n = 20;
	// number of iterations
	int k = 100;
	// number of runs
	int runNum = 10;
	// max mismatch to judge if model diff
	int maxmismatch = 1;
	double maxtheta = 0.8;
		
	TraceData traceData = new TraceData();
		
	if (testcase == 1){
	    traceData = generateHTTP(sampleNum, benignNum, attackNum, pollution);
	}
	if (testcase == 2){
	    traceData = generateCSV_SNMP(sampleNum, benignNum, attackNum, pollution);
	}
	if (testcase == 3){
	    traceData = generateCSV_SMB(sampleNum, benignNum, attackNum, pollution);
	}
	if (testcase == 5){
	    traceData = generateTelnet(sampleNum, benignNum, attackNum, pollution);
	}
	if (testcase == 6){
	    traceData = generateCSV_AlexaDNS(sampleNum, benignNum, attackNum, pollution);
	}
	// hue light synthesized traces
	if (testcase == 7){
	    String attackPath = "/Users/tianlong/eclipse-workspace/eiot_code/data/huelight_http/huelight-http-a";
	    String benignPath = "/Users/tianlong/eclipse-workspace/eiot_code/data/huelight_http/huelight-http-b";
	    traceData = generateCSV_HuelightHTTP(attackPath, benignPath, sampleNum, benignNum, attackNum, pollution);
	}
	// hue light synthesized traces
	if (testcase == 71){
	    sampleNum = 1000;//1280;//1000;
	    benignNum = 10;//1280;//1280;
	    attackNum = 100;
	    // Our RANSAC
	    // number of samples
	    n = 20;
	    // number of iterations
	    k = 1;//100;
	    // number of runs
	    runNum = 1;//10;
	    // max mismatch to judge if model diff
	    maxmismatch = 1;
	    maxtheta = 0.6;
	    String attackPath = "/Users/tianlong/eclipse-workspace/eiot_code/data/huelight_http/huelight-http-a";
	    String benignPath = "/Users/tianlong/eclipse-workspace/eiot_code/data/huelight_http/huelight-user-b";
	    traceData = generateCSV_HuelightHTTP(attackPath, benignPath, sampleNum, benignNum, attackNum, pollution);
	}
	int[] labels = traceData.labels;
	ArrayList<ArrayList<String[]>> tracesAll = traceData.tracesAll;
	ArrayList<Integer> symbolList = traceData.symbolList;
	// Xmeans
	int seed = 10;
	long startTime=System.currentTimeMillis();
	// 1. Our approach
	if (approach == 1){	
	    for (int i = 1; i <= 10; i++) {
		int nVar = 5*i;
		int allNum = tracesAll.size();
		int alsoNum = allNum*50/100;
		MealyFSM benignFSM = RANSAC_PLUS(tracesAll, symbolList, nVar, alsoNum, k, runNum, maxmismatch);
		int[] assignments = FSMTranverseMultiTheta(benignFSM, tracesAll, maxtheta);
		float[] rocPair = metrics(labels, assignments);
		rocList.add(rocPair);
	    }
	    System.out.printf("rocList\n");
	    System.out.printf("fp,       tp,        fn,       tn,       fpr,       tpr,       fnr,       tnr,     precision, recall, fscore\n");
	    for (int i = 0; i < rocList.size(); i++) {
		System.out.printf("%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f\n", rocList.get(i)[0], rocList.get(i)[1], rocList.get(i)[2], rocList.get(i)[3], rocList.get(i)[4], rocList.get(i)[5], rocList.get(i)[6], rocList.get(i)[7], rocList.get(i)[8], rocList.get(i)[9], rocList.get(i)[10]);
	    }
	}
	// RADIO best parameter
	if (approach == 111){	
	    for (int i = 1; i <= 10; i++) {
		int nVar = 20*2;
		MealyFSM benignFSM = RANSAC(tracesAll, nVar, k, runNum);
		printFSM(benignFSM);
		int[] assignments = FSMTranverseMulti(benignFSM, tracesAll);
		float[] rocPair = metrics(labels, assignments);
		rocList.add(rocPair);
	    }
	    System.out.printf("rocList\n");
	    for (int i = 0; i < rocList.size(); i++) {
		System.out.printf("%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f\n", rocList.get(i)[0], rocList.get(i)[1], rocList.get(i)[2], rocList.get(i)[3], rocList.get(i)[4], rocList.get(i)[5], rocList.get(i)[6], rocList.get(i)[7], rocList.get(i)[8], rocList.get(i)[9], rocList.get(i)[10]);
	    }
	}
	// 11: basic RPNI
	if (approach == 11){	
	    for (int i = 1; i <= 10; i++) {
		int nVar = 5*i;
		// int nVar = 1*i; // SNMP only
		MealyFSM benignFSM = RANSAC_RPNI(tracesAll, nVar, k, runNum);
		// printFSM(benignFSM);
		int[] assignments = FSMTranverseMulti(benignFSM, tracesAll);
		float[] rocPair = metrics(labels, assignments);
		rocList.add(rocPair);
	    }
	    System.out.printf("rocList\n");
	    for (int i = 0; i < rocList.size(); i++) {
		System.out.printf("%f, %f\n", rocList.get(i)[0], rocList.get(i)[1]);
	    }
	}
	// 12: simple hueristic
	if (approach == 12){	
	    for (int i = 1; i <= 10; i++) {
		int nVar = 5*i;
		// int nVar = 1*i; // SNMP only
		MealyFSM benignFSM = RANSAC_Simple_Hueristic(tracesAll, nVar, k, runNum);
		// printFSM(benignFSM);
		int[] assignments = FSMTranverseMulti(benignFSM, tracesAll);
		float[] rocPair = metrics(labels, assignments);
		rocList.add(rocPair);
	    }
	    System.out.printf("rocList\n");
	    for (int i = 0; i < rocList.size(); i++) {
		System.out.printf("%f, %f\n", rocList.get(i)[0], rocList.get(i)[1]);
	    }
	}
	// 2. Clustering-based approaches
	// 2a. Antonakakis et.al. Detecting dga-based malware (Usenix Security 12)
	// Ngram + Xmeans
	if (approach == 2){	
	    for (int i = 1; i <= 10; i++) {
		int seedVar = 2*i;
		Cluster cluster = new Cluster();
		int[] assignments  = cluster.XMeansFunc("ms.csv", seedVar);
		// Thread.sleep(2000); 
		float[] rocPair = metrics(labels, assignments);
		rocList.add(rocPair);
	    }
	    System.out.printf("Xmeans rocList\n");
	    for (int i = 0; i < rocList.size(); i++) {
		System.out.printf("%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f\n", rocList.get(i)[0], rocList.get(i)[1], rocList.get(i)[2], rocList.get(i)[3], rocList.get(i)[4], rocList.get(i)[5], rocList.get(i)[6], rocList.get(i)[7], rocList.get(i)[8], rocList.get(i)[9], rocList.get(i)[10]);
	    }
	}
	if (approach == 222){	
	    for (int i = 1; i <= 10; i++) {
		int seedVar = 4;
		Cluster cluster = new Cluster();
		int[] assignments  = cluster.XMeansFunc("ms.csv", seedVar);
		// Thread.sleep(2000); 
		float[] rocPair = metrics(labels, assignments);
		rocList.add(rocPair);
	    }
	    System.out.printf("Xmeans rocList\n");
	    for (int i = 0; i < rocList.size(); i++) {
		System.out.printf("%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f\n", rocList.get(i)[0], rocList.get(i)[1], rocList.get(i)[2], rocList.get(i)[3], rocList.get(i)[4], rocList.get(i)[5], rocList.get(i)[6], rocList.get(i)[7], rocList.get(i)[8], rocList.get(i)[9], rocList.get(i)[10]);
	    }
	}
	// 2b. Perdisci et.al. Behavioral clustering of http-based malware (NSDI10)
	// Editing distance + SingleHierarchical
	if (approach == 3)   {	
	    for (int i = 1; i <= 10; i++) {
		int clusterNum = 2*i;
		Cluster cluster = new Cluster();
		int[] assignments  = cluster.HierarchicalClusterer("editDistance.csv", clusterNum);
		float[] rocPair = metrics(labels, assignments);
		rocList.add(rocPair);
	    }
	    System.out.printf("Single Hierachy rocList\n");
	    for (int i = 0; i < rocList.size(); i++) {
		System.out.printf("%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f\n", rocList.get(i)[0], rocList.get(i)[1], rocList.get(i)[2], rocList.get(i)[3], rocList.get(i)[4], rocList.get(i)[5], rocList.get(i)[6], rocList.get(i)[7], rocList.get(i)[8], rocList.get(i)[9], rocList.get(i)[10]);
	    }
	}
	if (approach == 333){	
	    for (int i = 1; i <= 10; i++) {
		int clusterNum = 2;
		Cluster cluster = new Cluster();
		int[] assignments  = cluster.HierarchicalClusterer("editDistance.csv", clusterNum);
		float[] rocPair = metrics(labels, assignments);
		rocList.add(rocPair);
	    }
	    System.out.printf("Single Hierachy rocList\n");
	    for (int i = 0; i < rocList.size(); i++) {
		System.out.printf("%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f\n", rocList.get(i)[0], rocList.get(i)[1], rocList.get(i)[2], rocList.get(i)[3], rocList.get(i)[4], rocList.get(i)[5], rocList.get(i)[6], rocList.get(i)[7], rocList.get(i)[8], rocList.get(i)[9], rocList.get(i)[10]);
	    }
	}
	// 3. FSM-based approaches
	// 3a. Prospex
	if (approach == 4){	
	    for (int i = 1; i <= 10; i++) {
		int nVar = 10*i;
		MealyFSM benignFSM = Prospex(tracesAll);
		printFSM(benignFSM);
		int[] assignments = FSMTranverseMulti(benignFSM, tracesAll);
		float[] rocPair = metrics(labels, assignments);
		rocList.add(rocPair);
	    }
	    System.out.printf("rocList\n");
	    for (int i = 0; i < rocList.size(); i++) {
		System.out.printf("%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f\n", rocList.get(i)[0], rocList.get(i)[1], rocList.get(i)[2], rocList.get(i)[3], rocList.get(i)[4], rocList.get(i)[5], rocList.get(i)[6], rocList.get(i)[7], rocList.get(i)[8], rocList.get(i)[9], rocList.get(i)[10]);
	    }
	}
	long endTime=System.currentTimeMillis();
	System.out.println("Running Time： "+(endTime-startTime)+"ms");   
    }
}

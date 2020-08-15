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

public class MattLearnFSM {

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
	MealyFSM treeFSM = buildTreeFSM(traces);
	treeFSM.setSymbolList(symbolList);
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

import java.util.HashMap;
import java.util.Map;
import java.util.List;
import java.util.ArrayList;

public class MealyFSM {
	
    public Map<String, FSMState> stateMap = new HashMap<String, FSMState>();
    public String initialStateStr;
    public List<String> inputSymbols = new ArrayList<String> ();
    public List<String> outputSymbols = new ArrayList<String> ();
    // all symbols
    public ArrayList<Integer> symbolList = new ArrayList<>();
    // transitionRelation S * I -> S
    public Map<String, Map<String,String> > delta = new HashMap<String, Map<String,String> >();
    // outputRelation S * I -> O
    public Map<String, Map<String,String> > lambda = new HashMap<String, Map<String,String> >();
	
    public String curStateStr;
    public int stateNum = 0;
	
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
	
    public boolean tranverse(String iStr, String oStr){
	if (this.delta.containsKey(this.curStateStr)){
	    if (this.delta.get(this.curStateStr).containsKey(iStr)){
		if ( oStr.equals(this.lambda.get(this.curStateStr).get(iStr)) )	{
		    String nextState = this.delta.get(this.curStateStr).get(iStr);
		    this.curStateStr = nextState;
		    return true;
		}
	    }
	}
	return false;
    }
}

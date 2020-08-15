import java.util.List;
import java.util.ArrayList;

package slab;

public static class TraceData {
    ArrayList<ArrayList<String[]>> tracesAll;
    ArrayList<Integer> symbolList = new ArrayList<>();
    int[] labels;
    TraceData(){}
    TraceData(ArrayList<ArrayList<String[]>> tracesAll){
	this.tracesAll = tracesAll;
    }    
    TraceData(ArrayList<ArrayList<String[]>> tracesAll, int[] labels){
	this.tracesAll = tracesAll;
	this.labels = labels;
    }
    TraceData(ArrayList<ArrayList<String[]>> tracesAll, ArrayList<Integer> symbolList){
	this.tracesAll = tracesAll;
	this.symbolList = symbolList;
    }    
    TraceData(ArrayList<ArrayList<String[]>> tracesAll, ArrayList<Integer> symbolList, int[] labels){
	this.tracesAll = tracesAll;
	this.symbolList = symbolList;
	this.labels = labels;
    }
}

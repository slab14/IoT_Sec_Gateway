import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;

import weka.clusterers.SimpleKMeans;
import weka.clusterers.XMeans;
import weka.clusterers.HierarchicalClusterer;
import weka.core.Instances;
import weka.core.converters.CSVLoader;
import weka.core.EditDistance;
import weka.core.EuclideanDistance;
import weka.core.DistanceFunction;
import weka.core.ManhattanDistance;
import weka.core.ChebyshevDistance;
// import weka.core.MinkowskiDistance;
 
public class Cluster {
 
	public static BufferedReader readDataFile(String filename) {
		BufferedReader inputReader = null;
 
		try {
			inputReader = new BufferedReader(new FileReader(filename));
		} catch (FileNotFoundException ex) {
			System.err.println("File not found: " + filename);
		}
 
		return inputReader;
	}

	public static int[] SimpleKMeansFunc(String filePath) throws Exception {
		SimpleKMeans kmeans = new SimpleKMeans();
 
		kmeans.setSeed(10);
 
		//important parameter to set: preserver order, number of cluster.
		kmeans.setPreserveInstancesOrder(true);
		// kmeans.setNumClusters(5);
  
		CSVLoader cnv = new CSVLoader();
		File file = new File(filePath);
		cnv.setSource(file);
		Instances data = cnv.getDataSet();
		
		// set to two clusters: attack and benign
		kmeans.setNumClusters(2);
		// default kmeans.setSeed(10);700
		kmeans.setSeed(7);
		// kmeans.setDontReplaceMissingValues(false);
		kmeans.buildClusterer(data);
 
		// This array returns the cluster number (starting with 0) for each instance
		// The array has as many elements as the number of instances
		int[] assignments = kmeans.getAssignments();
 
		int i=0;
		for(int clusterNum : assignments) {
		    System.out.printf("Instance %d -> Cluster %d \n", i, clusterNum);
		    i++;
		}
		
		return assignments;
	}

	public static int[] XMeansFunc(String filePath) throws Exception {
		// SimpleKMeans xmeans = new SimpleKMeans();
		XMeans xmeans = new XMeans();
 
		xmeans.setSeed(10);
 
		//important parameter to set: preserver order, number of cluster.
		// xmeans.setPreserveInstancesOrder(true);
		// kmeans.setNumClusters(5);
  
		CSVLoader cnv = new CSVLoader();
		File file = new File(filePath);
		cnv.setSource(file);
		Instances data = cnv.getDataSet();
		
		// set to two clusters: attack and benign
		// xmeans.setNumClusters(2);
		// default kmeans.setSeed(10);700
		xmeans.setSeed(7);
		// kmeans.setDontReplaceMissingValues(false);
		xmeans.buildClusterer(data);
 
		// This array returns the cluster number (starting with 0) for each instance
		// The array has as many elements as the number of instances
		// int[] assignments = xmeans.getAssignments();
		int[] assignments = new int[data.numInstances()];
		 
		for(int i=0; i< assignments.length; i++) {
			int clusterNum = xmeans.clusterInstance(data.instance(i));			
		    System.out.printf("Instance %d -> Cluster %d \n", i, clusterNum);
		    if (clusterNum > 1)
		    {
		    	assignments[i] = 1;
		    }
		    else{
		    	assignments[i] = clusterNum;
		    }
		}
		
		return assignments;
	}
	
	
	public static int[] XMeansFunc(String filePath, int seed) throws Exception {
		// SimpleKMeans xmeans = new SimpleKMeans();
		XMeans xmeans = new XMeans();
 
		// xmeans.setSeed(10);
 
		//important parameter to set: preserver order, number of cluster.
		// xmeans.setPreserveInstancesOrder(true);
		// kmeans.setNumClusters(5);
  
		CSVLoader cnv = new CSVLoader();
		File file = new File(filePath);
		cnv.setSource(file);
		Instances data = cnv.getDataSet();
		
		// set to two clusters: attack and benign
		// xmeans.setMinNumClusters(maxNum);
		// xmeans.setMaxNumClusters(maxNum+10);
		// default kmeans.setSeed(10);700
		xmeans.setSeed(seed);
		// kmeans.setDontReplaceMissingValues(false);
		xmeans.buildClusterer(data);
 
		// This array returns the cluster number (starting with 0) for each instance
		// The array has as many elements as the number of instances
		// int[] assignments = xmeans.getAssignments();
		int[] assignments = new int[data.numInstances()];
		 
		for(int i=0; i< assignments.length; i++) {
			int clusterNum = xmeans.clusterInstance(data.instance(i));			
		    // System.out.printf("Instance %d -> Cluster %d \n", i, clusterNum);
		    if (clusterNum > 1)
		    {
		    	assignments[i] = 1;
		    }
		    else{
		    	assignments[i] = clusterNum;
		    }
		}
		
		return assignments;
	}
	
	public static int[] HierarchicalClusterer(String filePath) throws Exception {
		HierarchicalClusterer hCluster = new HierarchicalClusterer();
  
		CSVLoader cnv = new CSVLoader();
		File file = new File(filePath);
		cnv.setSource(file);
		Instances data = cnv.getDataSet();
		
		// set to two clusters: attack and benign
		hCluster.setNumClusters(2);
		// default kmeans.setSeed(10);700
		
		// hCluster.setDistanceFunction(new EuclideanDistance());
		hCluster.setDistanceFunction(new ManhattanDistance());
		// hCluster.setDistanceFunction(new ChebyshevDistance());
		// hCluster.setDistanceFunction(new MinkowskiDistance());
		hCluster.buildClusterer(data);
 
		// This array returns the cluster number (starting with 0) for each instance
		// The array has as many elements as the number of instances
		int[] assignments = new int[data.numInstances()];
 
		for(int i=0; i< assignments.length; i++) {
			int clusterNum = hCluster.clusterInstance(data.instance(i));
			assignments[i] = clusterNum;
		    System.out.printf("Instance %d -> Cluster %d \n", i, clusterNum);
		}
		// return {1,2};
		return assignments;
	}
	
	
	public static int[] HierarchicalClusterer(String filePath, int clusterNum) throws Exception {
		HierarchicalClusterer hCluster = new HierarchicalClusterer();
  
		CSVLoader cnv = new CSVLoader();
		File file = new File(filePath);
		cnv.setSource(file);
		Instances data = cnv.getDataSet();
		
		// set to two clusters: attack and benign
		// hCluster.setNumClusters(2);
		hCluster.setNumClusters(clusterNum);
		// default kmeans.setSeed(10);700
		
		// hCluster.setDistanceFunction(new EuclideanDistance());
		hCluster.setDistanceFunction(new ManhattanDistance());
		// hCluster.setDistanceFunction(new ChebyshevDistance());
		// hCluster.setDistanceFunction(new MinkowskiDistance());
		hCluster.buildClusterer(data);
 
		// This array returns the cluster number (starting with 0) for each instance
		// The array has as many elements as the number of instances
		int[] assignments = new int[data.numInstances()];
 
		for(int i=0; i< assignments.length; i++) {
			int clusterID = hCluster.clusterInstance(data.instance(i));
			// System.out.printf("Instance %d -> Cluster %d \n", i, clusterNum);
			if (clusterID > 1)
			{
				clusterID = 1;
			}
			assignments[i] = clusterID;
		}
		// return {1,2};
		return assignments;
	}
	
	
}
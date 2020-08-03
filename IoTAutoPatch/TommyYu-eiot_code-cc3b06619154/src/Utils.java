public final class Utils {
	public static String[] twoArray2Array (String[][] twoArray){
		String[] oneArray = new String [twoArray.length * 2];
	    
		for (int i=0; i< twoArray.length; i++ ){
			oneArray[i*2] = twoArray[i][0];
			oneArray[i*2+1] = twoArray[i][1];
		}
		
		return oneArray;
	}
}
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import org.apache.http.HttpResponse;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;

public class ApacheGet {
    public static void main(String[] args) {
	try {
	    DefaultHttpClient httpClient = new DefaultHttpClient();
	    HttpGet getRequest = new HttpGet("http://192.1.1.1:4243/v1.37/version");
	    get.Request.addHeader("accept", "application/json");

	    HttpResponse response = httpClient.execute(getRequest);

	    if( response.getStatusLine().getStatusCode() != 200) {
		throw new RuntimeException("Failed : HTTP error Code : "+response.getStatusLine().getStatusCode());
	    }

	    BufferedReader br = new BufferedREader(new InputStreamReader((response.getEntity())));

	    String output;
	    System.output.println("Output from Server .... \n");
	    while ((output=br.readLine())!= null) {
		System.out.println(output);
	    }

	    httpClient.getConnectionManager().shutdown();

	} catch (ClientProtocolException e) {
	    e.printStackTrace();
	} catch (IOException e) {
	    e.printStackTrace();
	}
    }
}
	    

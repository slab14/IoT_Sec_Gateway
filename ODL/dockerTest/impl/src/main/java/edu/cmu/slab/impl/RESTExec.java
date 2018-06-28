import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;

public class RESTExec {
    public String RESTSend(String url_uri, String data, String type) {
	StringBuffer output = new StringBuffer();
	try {
	    //url_uri in the form of http://ip:port/cmd
	    URL url = new URL(url_uri);
	    HttpURLConnection conn=(HttpURLConnection) url.openConnection();
	    //type is either GET, POST, or DELETE
	    conn.setRequestMethod(type);
	    if (type=="GET") {
		conn.setRequestProperty("Accept", "application/json");
		if (conn.getResponseCode() != 200) {
		    throw new RuntimeException("Failed : HTTP error code : " + conn.getResponseCode());
		}
	    } else if (type=="POST") {
		conn.setRequestProperty("Content-Type", "application/json");
		OutputStream os = conn.getOutputStream();
		os.write(data.getBytes());
		os.flush();
		if (conn.getResponseCode() != HttpURLConnection.HTTP_CREATED) {
		    throw new RuntimeException("Failed : HTTP error code : "+conn.getResponseCode());
		}
	    } else if (type=="DELETE") {
		//is anything needed here?
		if(conn.getResponseCode() != 200) {
		    throw new RuntimeException("Failed : HTTP error code : " + conn.getResponseCode());
		}
	    } else {
		System.out.println("This type of request is not supported");
		return "";
	    }

	    BufferedReader br = new BufferedReader(new InputStreamReader((conn.getInputStream())));
	    String line;
	    while ((line=br.readLine())!=null) {
		output.append(line+"\n");
	    }

	    conn.disconnect();
	} catch (MalformedURLException e) {
	    e.printStackTrace();
	} catch (IOException e) {
	    e.printStackTrace();
	}
	return output.toString();
    }
}
	    


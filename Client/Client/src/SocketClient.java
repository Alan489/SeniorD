import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;
import java.net.UnknownHostException;
import java.util.ArrayList;

public class SocketClient 
{
	private Socket sock;
	private BufferedReader br;
	private PrintWriter pw;
	private boolean closed = false;
	ArrayList<Event> EventConnections = new ArrayList<>();
	
	SocketClient(String ip, int port) //Main Constructor
	{
		
		//Attempt to connect to server with the IP and port combination
		globals.log.println("Creating new Client socket " + ip + ":" + port + " ... Attempting connection");
		try {
			sock = new Socket(ip, port);
		} catch (Exception e) {
			// TODO Auto-generated catch block
			globals.log.println("Unable to create new Client socket...");
			e.printStackTrace();
			return;
		}
		
		globals.log.println("Got connection ... Attempting to link.");
		
		//Attach the print writer and buffered reader. Catch error
		try {
		br = new BufferedReader(new InputStreamReader(sock.getInputStream()));
		pw = new PrintWriter(sock.getOutputStream());
		}
		catch (Exception e)
		{
			globals.log.println("Unable to create new Client socket...");
			e.printStackTrace();
			return;
		}
		//waitForData();
		
		new threaded().start();
		
		globals.log.println("SocketClient ready.");
	}
	
	SocketClient(String ip)
	{
		this(ip, globals.defaultPort);
	}
	
	//waitForData will halt the thread and wait for the server to send data over. Includes a try catch block in the event that the 
	//Socket has been closed or disconnected, that the networkManager didn't catch prior to the read.
	public String waitForData()
	{
		try {
			return br.readLine();
		}
		catch(Exception c)
		{
			globals.log.println("Socket closed.");
			closed = true;
			return null;
			//c.printStackTrace();
		}
		
	}
	
	//getData does NOT halt the thread for waiting for data. Technically will not throw an error, but included just incase some network
	//trickery is running about.
	public String getData()
	{
		String data = null;
		
		try {
			if (br.ready())
				data = br.readLine();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			globals.log.println("Error getting data off line. Is the socket closed?");
			e.printStackTrace();
			
		}
		
		return data;
	}
	
	
	public void attachEvent(Event e)
	{
		EventConnections.add(e);
	}
	
	public void removeEvent(Event e)
	{
		
		for (int i = 0; i < EventConnections.size(); i++)
			if (EventConnections.get(i) == e)
			{
				EventConnections.remove(i);
				return;
			}
	}
	
	public void processEvent(String s)
	{
		
		//Sanity check
		if (s == null) return;
		//Split by arguments
		String[] args = s.split("`");
		System.out.println("Received data " + args[1] + " with Event " + args[0]);
		//Find any EventConnections attached- Pass along the info
		for (int i = 0; i < EventConnections.size(); i++)
		{
			if (EventConnections.get(i).ConnectionName.equals(args[0]))
				EventConnections.get(i).Fire(args);
		}
		
	}
	
	//Simple enough?
	public void writeData(String e, String s)
	{
		System.out.println("Sending data " + s + " with event " + e);
		try
		{
			pw.println(e+"`"+s);
			pw.flush();
		} catch (Exception c)
		{
			globals.log.println("Error putting data on line. Is the socket closed?");
		}
	}
	
	private class threaded extends Thread
	{
		public void run()
		{
			while(!closed)
			{
				processEvent(waitForData());
			}
		}
	}
}

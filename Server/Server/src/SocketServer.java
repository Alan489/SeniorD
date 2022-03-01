import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.ArrayList;

public class SocketServer 
{
	ServerSocket sock;
	ArrayList<Sock> connections = new ArrayList<>();
	boolean accept = true;
	ArrayList<Event> EventConnections = new ArrayList<>();
	
	SocketServer(int port)
	{
		globals.log.println("Creating new Server socket " + port);
		try {
			sock = new ServerSocket(port);
			new threaded(this, sock).start(); 
		} catch (IOException e) {
			globals.log.println("Unable to create new Server socket...");
			
			e.printStackTrace();
		}
		
	}
	
	SocketServer()
	{
		this(globals.defaultPort);
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
		//Resend out to all of the connections
		send(s);
	}
	
	public void send(String e, String v)
	{
		for (int i = 0; i < connections.size(); i ++)
		{
			connections.get(i).writeData(e+"`"+v);
		}
		for (int i = 0; i < connections.size(); i ++)
		{
			if (connections.get(i).closed)
			{
				connections.remove(i);
				i--;
			}
		}
	}
	
	public void send(String s)
	{
		for (int i = 0; i < connections.size(); i ++)
		{
			System.out.println("Sending to: " + i);
			connections.get(i).writeData(s);
		}
		for (int i = 0; i < connections.size(); i ++)
		{
			if (connections.get(i).closed)
			{
				connections.remove(i);
				i--;
			}
		}
	}
	
	private class threaded extends Thread{
		ServerSocket s;
		SocketServer called;
		
		threaded(SocketServer caller, ServerSocket sock)
		{
			s = sock;
			called = caller;
		}
		
		public void run()
		{
			while (called.accept)
				try {

					called.connections.add(new Sock(s.accept(), called));
				} catch (IOException e) {
					globals.log.println("Attempted to add a new connection, but something happened. Was the server socket closed?");
					e.printStackTrace();
				}
		}
		
		
	}
	
	
	public class Sock
	{
		private BufferedReader br;
		private PrintWriter pw;
		Socket sock;
		public boolean closed = false;
		SocketServer serve;
		Sock(Socket s, SocketServer ss)
		{
			serve = ss;
			sock = s;
			globals.log.println("Got connection ... Attempting to link.");
			
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
			
			new threaded().start();
			
			globals.log.println("SocketClient ready.");
			
		}
		
		private class threaded extends Thread
		{
			public void run()
			{
				while (!closed)
				{
					serve.processEvent(waitForData());
				}
			}
					
		}
		
		public boolean isClosed()
		{
			return closed;
		}
		
		public String waitForData()
		{
			try {
				return br.readLine();
			}
			catch(Exception c)
			{
				closed = true;
				
			}
			return null;
		}
		
		public String getData()
		{
			String data = null;
			
			try {
				if (br.ready())
					data = br.readLine();
			} catch (IOException e) {
				
				globals.log.println("Error getting data off line. Is the socket closed?");
				e.printStackTrace();
				
			}
			
			return data;
		}
		
		public void writeData(String s)
		{
			try
			{
				pw.println(s);
				pw.flush();
			} catch (Exception c)
			{
				globals.log.println("Error putting data on line. Is the socket closed?");
				closed = true;
			}
		}
		
	}
	
	
}

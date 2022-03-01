import java.util.ArrayList;

//So networkManager is wrapping a SocketClient which is already wrapping a Socket.... Why.
//Short answer: Need a way to easily keep the connection alive/ detect when dead.
//Long answer: Wrapping the client in this class will allow for easier detection when the connection goes dead.
//			   Hopefully avoid hard errors!  Network code is not fun, I rate this 0/10 good time.
//

public class networkManager extends SocketClient implements Runnable
{
	ArrayList<String> data = new ArrayList<>();
	private boolean open = true;
	//Create the SocketClient
	networkManager(String ip, int port)
	{
		super(ip, port);
		Thread t = new Thread(this);
		t.start();
		//writeData("Ready.");
	}
	
	networkManager(String ip)
	{
		this(ip, globals.defaultPort);
	}
	
	public String next()
	{
		if (data.size() == 0)
			return null;
		String temp = data.get(0);
		data.remove(0);
		return temp;
	}
	
	@Override
	public void run() {
		String newData = "INIT1231231231231231";
		while (newData != null)
		{
			if (newData.equals("ping"))
			{
				//writeData("pong");
				System.out.println("Got a ping.");
			}
			else
			{
				if (!newData.equals("INIT1231231231231231"))
					data.add(newData);
			}
			newData = waitForData();
		}
	}
	
	
}

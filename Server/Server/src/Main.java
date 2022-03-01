import java.util.Scanner;

public class Main 
{
	public static void main(String[] args)
	{
		globals.printCRInfo();
		
		globals.log = new logger("Server");
		
		globals.in = new Scanner(System.in);
		
		
		int p1 = -1;
		
		while (p1 == -1 || p1 <1 || p1 > 65535)
		{
			String parse = globals.log.getInput("Port to scan. Press enter to use default");
			if (parse.equals(""))
			{
				p1 = globals.defaultPort;
				globals.log.println("Using default port.");
			}
			try{
				p1 = Integer.parseInt(parse);
			}
			catch (Exception c) {}
			
		}
		
		globals.SS = new SocketServer(p1);
		
		
	}
}

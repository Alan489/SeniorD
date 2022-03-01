import java.util.Date;

public class Debug {
	public static class test extends Event
	{
		
		public test()
		{
			this.ConnectionName = "Hello World";
		}
				@Override
		public void Fire(String[] args) {
			
			// TODO Auto-generated method stub
			System.out.println(args[1]);
		}
		
	}
	public static void main(String[] args)
	{
		globals.printCRInfo();
		
		logger l = new logger("DebugClient");
		
		globals.log = l;
		
		SocketClient sc = new SocketClient("127.0.0.1");
		long start = new Date().getTime();
		while(new Date().getTime()-start < 1000);
		sc.attachEvent(new test());
		sc.writeData("Hello World", "My name is juan");
		
	}
}

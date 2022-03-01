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
		
		logger l = new logger("DebugServer");
		System.out.println("Test!");
		globals.log = l;
		
		SocketServer ss = new SocketServer();
		ss.attachEvent(new test());
		
		
		
	}
}

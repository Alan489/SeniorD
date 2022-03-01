import java.io.BufferedWriter;
import java.io.Closeable;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Date;

public class logger implements Closeable
{

	private File outFile;
	private BufferedWriter bw;
	private String context;
	
	logger(String A)
	{
		context = A;
		System.out.println("Creating logger " + context);
		Date d = new Date();
		int t = 0;
		String TD = "" + d.getDay() + d.getSeconds() + d.getMonth();
		outFile = new File(A + "." + TD + t+ ".txt");
		while (outFile.exists() && t < 100)
		{
			t++;
			outFile = new File(A + "." + TD + t + ".txt");
		}
		
		if (outFile.exists())
		{
			System.out.println("Error creating log file with context " + A + ". Logging will not be available.");
		}
		
		try
		{
			boolean created = outFile.createNewFile();
			if (created)
			{
				bw = new BufferedWriter(new FileWriter(outFile));
			}
		}
		catch (Exception c)
		{
			System.err.println("Logger unable to start context " + context + " due to error!");
			c.printStackTrace();
		}
		
		println("Successfully created new logger.");
		
	}
	
	logger()
	{
		this("Main");
	}
	
	public String getInput(String prompt)
	{
		Date d = new Date();
		String Built = d.getHours() + ":" + d.getMinutes() + ":" + d.getSeconds();
		d = null;
		Built = "[" + context + " " + Built + "] " + prompt;
		
		System.out.print("*" + Built + "> ");
		
		String input = globals.in.nextLine();
		
		try {
			bw.write("***\t" + Built + " \" " + input + " \"");
			bw.newLine();
			bw.flush();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			System.err.println("[" + context + "] Was unable to post a message to the file.");
			e.printStackTrace();
		}
		
		return input;
	}
	
	public void println(String a)
	{
		Date d = new Date();
		String Built = d.getHours() + ":" + d.getMinutes() + ":" + d.getSeconds();
		d = null;
		Built = "[" + context + " " + Built + "] " + a;
		
		System.out.println(Built);
		
		try {
			bw.write("\t" + Built);
			bw.newLine();
			bw.flush();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			System.err.println("[" + context + "] Was unable to post a message to the file.");
			e.printStackTrace();
		}
	}
	
	
	@Override
	public void close() throws IOException {
		try {
			bw.close();
		} catch (Exception e) {
			// TODO: handle exception
		}
	}
	
}

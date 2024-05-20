using System;
using System.IO;
using System.Windows.Forms;

public class HelloWorld : Form
{
    static void Main()
    {
        Application.Run(new HelloWorld());
    }

    public HelloWorld()
    {
        this.Text = "Purple Team Test";
        File.AppendAllText("BasicOutput.txt", $"{DateTime.Now} - Screensaver-TextOutput.scr executed successfully\n");
    }
}

using System;
using System.Diagnostics;

namespace Instrumental
{

  class InstrumentServerProcess
  {

    private EventLog destination;
    private Process  process;

    public InstrumentServerProcess(EventLog log){
      destination = log;
    }

    public void Run(string executablePath, string configPath, string hostname, bool scriptsEnabled, string scriptsDirectory){
      SetupProcess(executablePath, configPath, hostname, scriptsEnabled, scriptsDirectory);
    }

    public bool IsRunning(){
      try {
        return !Convert.ToBoolean(process?.HasExited);
      } catch(InvalidOperationException){
        return false;
      }
    }

    public void CleanupProcess(){
      process?.Close();
      process = null;
    }

    public TimeSpan Age(){
      DateTime lastStarted = process?.StartTime ?? DateTime.Now;
      return DateTime.Now - lastStarted;
    }

    public void SetupProcess(string executablePath, string configPath, string hostname, bool scriptsEnabled, string scriptsDirectory){
      CleanupProcess();
      string args                              = $"-f \"{configPath}\" -H \"{hostname}\"";
      if(scriptsEnabled){
        args += $" -e -s \"{scriptsDirectory}\"";
      }
      args += " foreground";
      destination.WriteEntry($"Trying to start {executablePath} {args}", EventLogEntryType.Information);
      process                                  = new Process();
      process.StartInfo.FileName               = executablePath;
      process.StartInfo.Arguments              = args;
      process.StartInfo.UseShellExecute        = false;
      process.StartInfo.RedirectStandardOutput = true;
      process.StartInfo.RedirectStandardError  = true;
      process.StartInfo.CreateNoWindow         = true;
      process.OutputDataReceived              += new DataReceivedEventHandler((sender, e) => {
          if(!String.IsNullOrEmpty(e.Data)){
            destination.WriteEntry(e.Data, EventLogEntryType.Information);
          }
        });
      process.ErrorDataReceived               += new DataReceivedEventHandler((sender, e) => {
          if(!String.IsNullOrEmpty(e.Data)){
            destination.WriteEntry(e.Data, EventLogEntryType.Error);
          }
        });
      if(!process.Start()){
        destination.WriteEntry("Failed to start process", EventLogEntryType.Error);
      } else {
        process.BeginOutputReadLine();
        process.BeginErrorReadLine();
      }
    }


  }
}
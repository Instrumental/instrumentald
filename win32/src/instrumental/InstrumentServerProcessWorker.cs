using System;
using System.Diagnostics;
using System.Threading;

namespace Instrumental
{

  class InstrumentServerProcessWorker
  {

    private volatile bool doRun;
    private string executablePath;
    private string configPath;
    private string hostname;
    private bool scriptsEnabled;
    private string scriptsDirectory;
    private EventLog destination;
    private Thread runnerThread;
    private TimeSpan checkInterval;
    private int retryFallback;
    private int retries;
    private int maxFallbackMult;

    public InstrumentServerProcessWorker(EventLog log, string execPath, string confPath, string host, bool enableScripts, string scriptDir){
      destination      = log;
      executablePath   = execPath;
      configPath       = confPath;
      hostname         = host;
      scriptsEnabled   = enableScripts;
      scriptsDirectory = scriptDir;
      runnerThread     = null;
      doRun            = false;
      checkInterval    = TimeSpan.FromSeconds(5);
      retryFallback    = 7; // Seconds
      maxFallbackMult  = 3; // Seconds
      retries          = -1;
    }

    public void Run(){
      destination.WriteEntry("Starting worker thread", EventLogEntryType.Information);
      InstrumentServerProcess process = new InstrumentServerProcess(destination);
      try {
        process.Run(executablePath, configPath, hostname, scriptsEnabled, scriptsDirectory);
      } catch (Exception ex) {
        destination.WriteEntry("Exception trying to start, " + ex.Message, EventLogEntryType.Error);
      }
      DateTime lastIter = DateTime.Now;
      DateTime lastExec = lastIter;
      while(doRun){
        Thread.Sleep(checkInterval);
        try {
          if(!process.IsRunning()){
            if( (DateTime.Now - lastExec) > TimeSpan.FromSeconds(Math.Pow(retryFallback, retries))){
              destination.WriteEntry("Attempting to start process", EventLogEntryType.Information);
              process.Run(executablePath, configPath, hostname, scriptsEnabled, scriptsDirectory);
              lastExec = DateTime.Now;
              retries = Math.Min(retries + 1, maxFallbackMult);
            }
          }
        } catch (Exception ex) {
          destination.WriteEntry("Exception trying to start, " + ex.Message, EventLogEntryType.Error);
          retries = Math.Min(retries + 1, maxFallbackMult);
        }
      }
      process.CleanupProcess();
      destination.WriteEntry("Worker thread ended", EventLogEntryType.Information);
    }

    public void RequestStop(){
      doRun = false;
    }

    public void Stop(){
      RequestStop();
      runnerThread?.Join();
      runnerThread = null;
    }

    public void Start(){
      if(Convert.ToBoolean(runnerThread?.IsAlive)){
        Stop();
      }
      doRun = true;
      runnerThread = new Thread(this.Run);
      runnerThread.Start();
    }

  }
}
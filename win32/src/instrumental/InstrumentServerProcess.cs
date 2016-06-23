using System;
using System.Collections.Generic;
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
      if(process == null){
        return false;
      }
      try {
        return !Convert.ToBoolean(process?.HasExited);
      } catch(InvalidOperationException){
        return false;
      }
    }

    public void CleanupProcess(){
      if(IsRunning()){
        process.Kill();
        process.WaitForExit();
      }
      process?.Close();
      process = null;
    }

    public TimeSpan Age(){
      DateTime lastStarted = process?.StartTime ?? DateTime.Now;
      return DateTime.Now - lastStarted;
    }

    public string RubyDir(string basePath){
      return basePath + "\\lib\\ruby";
    }

    public string RubyLibDir(string basePath){
      return RubyDir(basePath) + "\\lib\\ruby";
    }

    public string AppDir(string basePath){
      return basePath + "\\lib\\app";
    }

    public string VendorDir(string basePath){
      return basePath + "\\lib\\vendor";
    }

    public string Gemfile(string basePath){
      return VendorDir(basePath) + "\\Gemfile";
    }

    public string RubyExecutable(string basePath){
      return RubyDir(basePath) + "\\bin.real\\ruby.exe";
    }

    public string InstrumentServerScript(string basePath){
      return AppDir(basePath) + "\\bin\\instrumentald";
    }

    public string RubyFlags(){
      return "-rbundler/setup";
    }

    public string SslCertFile(string basePath){
      return RubyDir(basePath) + "\\lib\\ca-bundle.crt";
    }

    public void SetupProcess(string executablePath, string configPath, string hostname, bool scriptsEnabled, string scriptsDirectory){
      CleanupProcess();
      string args                              = $"{RubyFlags()} \"{InstrumentServerScript(executablePath)}\" -f \"{configPath}\" -H \"{hostname}\"";
      if(scriptsEnabled){
        args += $" -e -s \"{scriptsDirectory}\"";
      }
      args += " foreground";

      string rubyVersion = "2.1.0";
      string rubyArch = "i386-mingw32";
      string rubyDir = RubyLibDir(executablePath);
      string[] libDirs = new string[]{
        $"{rubyDir}\\site_ruby\\{rubyVersion}",
        $"{rubyDir}\\site_ruby\\{rubyVersion}\\{rubyArch}",
        $"{rubyDir}\\site_ruby",
        $"{rubyDir}\\vendor_ruby\\{rubyVersion}",
        $"{rubyDir}\\vendor_ruby\\{rubyVersion}\\{rubyArch}",
        $"{rubyDir}\\vendor_ruby",
        $"{rubyDir}\\{rubyVersion}",
        $"{rubyDir}\\{rubyVersion}\\{rubyArch}"
      };

      Dictionary<string, string> env = new Dictionary<string, string>(){
        { "BUNDLE_GEMFILE",       Gemfile(executablePath) },
        { "RUBYLIB",              String.Join(";", libDirs) },
        { "SSL_CERT_FILE",        SslCertFile(executablePath) }
      };

      destination.WriteEntry($"Trying to start {RubyExecutable(executablePath)} {args} with env {String.Join(";", env)}", EventLogEntryType.Information);

      process                                  = new Process();
      process.StartInfo.FileName               = RubyExecutable(executablePath);
      process.StartInfo.Arguments              = args;

      foreach(KeyValuePair<string, string> entry in env){
        process.StartInfo.EnvironmentVariables[entry.Key] = entry.Value;
      }

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

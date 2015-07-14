using Microsoft.Win32;

using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.ServiceProcess;
using System.Threading;

namespace Instrumental
{
  class InstrumentServerService : ServiceBase
  {
    public const string NameOfService       = "Instrument Server";
    public const string PathKey             = "Path";
    public const string ConfigKey           = "Config";
    public const string HostnameKey         = "Hostname";
    public const string EnableScriptsKey    = "ScriptsEnabled";
    public const string ScriptsDirectoryKey = "ScriptsDirectory";
    public const string InstrumentalKey     = "Instrumental";

    private InstrumentServerProcessWorker ProcessWorker;

    public InstrumentServerService()
    {
      this.ServiceName                 = InstrumentServerService.NameOfService;

      this.EventLog.Log                = "Application";

      this.CanHandlePowerEvent         = false;
      this.CanHandleSessionChangeEvent = false;
      this.CanPauseAndContinue         = false;
      this.CanShutdown                 = false;
      this.CanStop                     = true;

      string path = BasePath() ?? DefaultBasePath();
      EventLog.WriteEntry($"Starting with path {BasePath()} (Default: {DefaultBasePath()}), config {Config()} (Default: {DefaultConfig()}), hostname {Hostname()} (Default: {DefaultHostname()}), scripts enabled {ScriptsEnabled()}, scripts directory {ScriptsDirectory()} (Default: {DefaultScriptsDirectory()}), values taken from {InstrumentalRegistryKey()}", EventLogEntryType.Information);

      this.ProcessWorker               = new InstrumentServerProcessWorker(EventLog,
                                                                           path,
                                                                           Config() ?? DefaultConfig(),
                                                                           Hostname() ?? DefaultHostname(),
                                                                           ScriptsEnabled(),
                                                                           ScriptsDirectory() ?? DefaultScriptsDirectory());
    }

    static void Main()
    {
      ServiceBase.Run(new InstrumentServerService());
    }

    public static RegistryKey InstrumentalRegistryKey(bool withWriteAccess = false){
      RegistryKey localKey;
      if(Environment.Is64BitOperatingSystem){
        localKey = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry64);
      } else {
        localKey = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry32);
      }
      if(withWriteAccess){
        return localKey.OpenSubKey("Software", true).CreateSubKey(InstrumentalKey);
      } else {
        return localKey.OpenSubKey("Software").OpenSubKey(InstrumentalKey);
      }
    }

    public static string AssemblyDirectory()
    {
      string codeBase     = Assembly.GetExecutingAssembly().CodeBase;
      UriBuilder uri      = new UriBuilder(codeBase);
      string assemblyPath = Uri.UnescapeDataString(uri.Path);
      return Path.GetDirectoryName(assemblyPath);
    }

    public static string StringFromRegistryKey(string keyName){
      RegistryKey regkey = InstrumentalRegistryKey();
      if(regkey != null){
        return Convert.ToString(regkey.GetValue(keyName));
      } else {
        return null;
      }
    }

    public static string BasePath() {
      return StringFromRegistryKey(PathKey);
    }

    public static string DefaultBasePath() {
      return InstrumentServerService.AssemblyDirectory();
    }

    public static string Config() {
      return StringFromRegistryKey(ConfigKey);
    }

    public static string DefaultConfig() {
      return DefaultBasePath() + "\\etc\\instrumental.yml";
    }

    public static string Hostname(){
      return StringFromRegistryKey(HostnameKey);
    }

    public static string DefaultHostname(){
      return System.Environment.MachineName;
    }

    public static bool ScriptsEnabled() {
      object value = InstrumentalRegistryKey()?.GetValue(EnableScriptsKey);
      if(value != null){
        return Convert.ToBoolean(value);
      } else {
        return DefaultScriptsEnabled();
      }
    }

    public static bool DefaultScriptsEnabled(){
      return false;
    }

    public static string ScriptsDirectory() {
      return StringFromRegistryKey(ScriptsDirectoryKey);
    }

    public static string DefaultScriptsDirectory(){
      return DefaultBasePath() + "\\Scripts";
    }

    protected override void Dispose(bool disposing)
    {
      base.Dispose(disposing);
    }

    protected override void OnStart(string[] args)
    {
      base.OnStart(args);
      ProcessWorker.Start();
    }

    protected override void OnStop()
    {
      base.OnStop();
      ProcessWorker.Stop();
    }

  }
}
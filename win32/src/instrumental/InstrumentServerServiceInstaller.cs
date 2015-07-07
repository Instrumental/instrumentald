using Microsoft.Win32;

using System;
using System.Collections;
using System.ComponentModel;
using System.Configuration.Install;
using System.ServiceProcess;

namespace Instrumental
{
  [RunInstaller(true)]
  public class InstrumentServerServiceInstaller : Installer
  {

    public const string PathArgument             = "Path";
    public const string ConfigArgument           = "Config";
    public const string HostnameArgument         = "Hostname";
    public const string ScriptsDirectoryArgument = "ScriptsDirectory";
    public const string ScriptsEnabledArgument   = "ScriptsEnabled";

    public InstrumentServerServiceInstaller()
    {
      ServiceProcessInstaller serviceProcessInstaller = new ServiceProcessInstaller();
      ServiceInstaller serviceInstaller               = new ServiceInstaller();

      serviceProcessInstaller.Account                 = ServiceAccount.LocalService;
      serviceProcessInstaller.Username                = null;
      serviceProcessInstaller.Password                = null;

      serviceInstaller.DisplayName                    = InstrumentServerService.NameOfService;
      serviceInstaller.StartType                      = ServiceStartMode.Automatic;
      serviceInstaller.ServiceName                    = InstrumentServerService.NameOfService;

      this.Installers.Add(serviceProcessInstaller);
      this.Installers.Add(serviceInstaller);
    }

    public override void Install(IDictionary savedState)
    {
      base.Install(savedState);

      RegistryKey AppKey = InstrumentServerService.InstrumentalRegistryKey(true);
      string Path        = Context.Parameters[PathArgument]             ?? InstrumentServerService.DefaultBasePath();
      string Config      = Context.Parameters[ConfigArgument]           ?? InstrumentServerService.DefaultConfig();
      string ScriptDir   = Context.Parameters[ScriptsDirectoryArgument] ?? InstrumentServerService.DefaultScriptsDirectory();
      string Hostname    = Context.Parameters[HostnameArgument]         ?? InstrumentServerService.DefaultHostname();

      bool EnableScripts = InstrumentServerService.DefaultScriptsEnabled();
      if(Context.Parameters[ScriptsEnabledArgument] != null){
        EnableScripts = Convert.ToBoolean(Context.Parameters[ScriptsEnabledArgument]);
      }

      AppKey.SetValue(InstrumentServerService.PathKey, Path);
      AppKey.SetValue(InstrumentServerService.ConfigKey, Config);
      AppKey.SetValue(InstrumentServerService.EnableScriptsKey, EnableScripts);
      AppKey.SetValue(InstrumentServerService.ScriptsDirectoryKey, ScriptDir);
      AppKey.SetValue(InstrumentServerService.HostnameKey, Hostname);
    }
  }
}
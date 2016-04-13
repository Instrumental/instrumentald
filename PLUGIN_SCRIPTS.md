# Plugin Scripts

You may have specific pieces of architecture that you would like `instrument_server` to monitor. Pass the `-e` flag to `instrument_server` on startup to enable this script plugins. There are many [existing plugins](examples/) that you may use for your infrastructure, or you can [write your own](#writing-plugin-scripts). We also work with customers to develop plugins on an as-needed basis. Please contact us at [support@instrumentalapp.com](mailto:support@instrumentalapp.com) if we can assist with plugin development.

## Installing Plugin Scripts

To install scripts, place them in the directory `$HOME/.instrumental_scripts`. The `instrument_server` process will create this directory if it doesn't exist the first time you run the process with script functionality enabled (`-e`). You may also specify a specific directory to the `instrument_server` process with the `-s` (`--script-location`) flag.

### Permission Requirements

The directory you use for plugin scripts and the scripts themselves must be readable/writable only by owner (`0700`), which must be the same user that the `instrument_server` process runs as. The `instrument_server` process will exit with an error message alerting you to the fact that it cannot use the directory otherwise.

## Writing Plugin Scripts

A script may be a binary or shell script that exists in the scripts directory (`$HOME/.instrumental_scripts`). Each time the `instrument_server` process collects system metrics, it will also execute your script with the following arguments:

* **Argument 1:** The Unix timestamp of the last time this script had been executed, in seconds. If the process has not successfully run by `instrument_server` before, this value will be 0.
* **Argument 2:** The exit status of the process the last time this script had been executed. If the process has not successfully ran by `instrument_server` before, this value will not be present.
* **STDIN:**
 The `STDIN` pipe to your process will contain the output of your script the last time it had been executed. You may use this data to compute differences between the last time your script ran and the current execution. (_The [MySQL script](examples/mysql/mysql_status.rb) uses this to compute rate metrics_)
* Environment: Any environment variables set for the `instrument_server` process will be available to your process.

Your script is expected to output data in the following format on `STDOUT` in order to be sent back to Instrumental:

```
METRIC_NAME METRIC_VALUE
```

or

```
METRIC_NAME METRIC_VALUE UNIX_TIME_IN_SECONDS
```

For example, if a script named `application_load` were to report two metrics, `memory` and `load`, to the `instrument_server` process, its output should be:

```
memory 1024.0
load 0.7
```

The `instrument_server` process will submit each metric to Instrumental in the following form:

```
HOST_NAME.SCRIPT_NAME.METRIC_NAME
```

Using the previous example, if the `application_load` script ran on a host named `app-0001`, its `memory` and `load` metrics would be submitted to Instrumental as `app-0001.application_load.memory` and `app-0001.application_load.load`.

The optional third parameter of the above formats, `UNIX_TIME_IN_SECONDS`, represents the time under which the submitted metric should be measured. Generally you do not need to provide this value, as `instrument_server` will default to recording the time when it receives the metric from your script as the time under which the measurement should be recorded.

### Exit Codes

If you do not want the output of your script submitted to Instrumental, your process should exit with a non-zero exit code. Its `STDOUT` output will still be provided to your script on the next iteration.

### Errors

You may output error information on `STDERR` of your process, and it will be output to the `instrument_server` log to aid in debugging script behavior.

### Timeouts

Your script is responsible for managing timeouts. The `instrument_server` process will not attempt to terminate your process for you.

### Powershell Integration

Windows administrators may create Powershell scripts following the above guidelines. You should write your output to the STDOUT stream using `Write-Output`. The file extension of the Powershell script must be `.ps1` in order for it to be executd by the Instrument Server process.

### Unreleased
* Configurable pid and log file locations
* Pid and log file default to $HOME
* Process control commands do not require API key
* Omit "-d" in favor of "start" and "stop", "foreground" runs process in foreground
* Configurable reporting interval
* Custom scripts may be executed and have their output sent to Instrumental (See [CUSTOM_METRICS.md](CUSTOM_METRICS.md))

### 0.6.0 [August 11th, 2014]
* Don't report swap usage if it's zero (Patrick Wyatt)

### 0.5.8 [August 11th, 2014]
* Upgraded instrumental_agent gem to the latest version

### 0.5.7 [January 31st, 2014]
* tmpfs tracking actually works now!

### 0.5.6 [January 31st, 2014]
* Add tmpfs to disk stats

### 0.5.5 [April 30th, 2013]
* Update to latest instrumental_agent

### 0.5.4 [March 19th, 2013]
* Reduce polling frequency of instrument_server to every minute
* Remove gitstrumental

### 0.5.3 [November 5th, 2012]
* Upgraded instrumental_agent gem to the latest version

### 0.5.2 [April 19th, 2012]
* Check for existence of system commands prior to usage in instrument_server.

### 0.5.1 [February 9th, 2012]
* Removing symbol to proc use for compatibility with older version of Ruby

### 0.5.0 [January 16, 2012]
* Remove out-dated instrumental binary

### 0.4.2 [January 12, 2012]
* Limit IO monitoring to mounted devices

### 0.4.1 [January 11, 2012]
* README and --help improvements

### 0.4.0 [January 11, 2012]
* More capistrano tasks (Joel Meador)

### 0.3.2 [January 11, 2012]
* Fix disk IO calculation issue
* Remove depency on iostat

### 0.3.1 [January 11, 2012]
* Fixed critical issue with cpu.in_use metric on Linux

### 0.3.0 [January 11, 2012]
* Fix CPU usage calculation issue on Linux
* Configurable hostname reporting
* capistrano tasks for managing instrument_server (Joel Meador)

### 0.2.1 [December 28, 2011]
* Added missing runtime dependency for pidly

### 0.2.0 [December 27, 2011]
* Real command line options
* Daemonized instrument_server

### 0.1.1 [December 13, 2011]
* Fixed issue when collector was not supplied

### 0.1.0 [December 12, 2011]
* Initial release

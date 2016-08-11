# Instrumental Daemon Examples

Here you can find examples of custom plugin scripts and other bits for Instrumental Daemon.

## Plugin Script Examples

The following scripts are examples of how to monitor other parts of your system not natively supported by `instrumentald`.

#### Log Size

The [log size](plugin_scripts/log_size.sh) script simply monitors the size of logs in /var/log, so you can see if a log is failing to rotate or growing out of control.  It demonstrates using an executable shell script as a plugin script.

#### ISS Monitor

The [ISS Monitor](plugin_scripts/iss_monitor.rb) script monitors the distance between my current location and the international space station (or, more exactly, a point directly UNDER the international space station).  You can use environment variables to track the distance between your location and the ISS.

#### MySQL

The [MySQL](plugin_scripts/mysql.rb) script collects the following metrics:

* Queries - `Queries`
* Bytes Sent  - `Bytes_sent`
* Bytes Received - `Bytes_received`
* Connections - `Connections`
* Slow queries - `Slow_queries`

Additionally, it estimates the number received per second ( `Queries_per_second`, etc. ).

MySQL monitoring functionality is provided by default, but this script demonstrates advanced functionality, including receiving previous script output via STDIN and other advanced features.

You may either edit the values `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, `MYSQL_DEFAULTS_FILE` / `MYSQL_PASSWORD` in the [`mysql_status.rb`](mysql_status.rb) to reflect your server's information or provide them as environment variables to the `instrumentald` process. It is advisable that you use a MySQL CNF file to specify password information if your server uses password authentication. See [the MySQL page regarding password security](http://dev.mysql.com/doc/refman/5.0/en/password-security-user.html) for more information.

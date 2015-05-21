# MySQL Metrics

The MySQL metrics script collects the following metrics:

* Queries - `Queries`
* Bytes Sent  - `Bytes_sent`
* Bytes Received - `Bytes_received`
* Connections - `Connections`
* Slow queries - `Slow_queries`

Additionally, it estimates the number received per second ( `Queries_per_second`, etc. ).

You may either edit the values `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, `MYSQL_DEFAULTS_FILE` / `MYSQL_PASSWORD` in the [`mysql_status.rb`](mysql_status.rb) to reflect your server's information or provide them as environment variables to the `instrument_server` process. It is advisable that you use a MySQL CNF file to specify password information if your server uses password authentication. See [the MySQL page regarding password security](http://dev.mysql.com/doc/refman/5.0/en/password-security-user.html) for more information.

# Redis Metrics

The [`redis_info.sh`](redis_info.sh) script generates metrics from the `redis-cli info` command for a redis instance. The following metrics will be output for every collection in your system:

* `connected_clients` - Total currently connected clients
* `instantaneous_ops_per_sec` - Current operations per second

Additionally, the following database level metrics will be output:

* `dbDB_NUM_keys` - Count of keys in the DB_NUM database

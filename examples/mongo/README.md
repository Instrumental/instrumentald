# Mongo Metrics

The [`mongo_3.rb`](mongo_3.rb) script generates metrics from the `mongotop` and `mongostat` commands for a Mongo 3.0 database. The following metrics will be output for every collection in your system:

* `mongotop.COLLECTION.total_ms` - Total ms spent in collection
* `mongotop.COLLECTION.write_ms` - Write ms spent in collection
* `mongotop.COLLECTION.read_ms` - Read ms spent in collection

Additionally, the following database level metrics will be output:

* `mongostat.HOST.conn` - Current number of connections
* `mongostat.HOST.delete`- Delete commands issued
* `mongostat.HOST.faults` - Page faults occurred
* `mongostat.HOST.flushes` - Flushes performed
* `mongostat.HOST.getmore` - Get More commands issued
* `mongostat.HOST.idx_miss_pct` - Percentage of queries missing an index
* `mongostat.HOST.insert` - Insert commands issued
* `mongostat.HOST.mapped_mb` - Database files mapped into memory
* `mongostat.HOST.netIn_mb` -  Amount of network I/O received
* `mongostat.HOST.netOut_mb` - Amount of network I/O sent
* `mongostat.HOST.query` - Number of queries received
* `mongostat.HOST.res_mb` - Resident memory of db process
* `mongostat.HOST.update` - Number of update commands issued

These metrics can only be gathered using the 3.0 version of the Mongo command line tools.

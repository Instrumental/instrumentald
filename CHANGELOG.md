### 1.0.0 beta 4 [Oct 5, 2016]
 * Added a task to make yanking old versions (looking at you, beta3) easier
 * Filtered out default databases in postgresql configuration
 * Made multi-server configuration smarter for nginx and redis

### 1.0.0 beta 3 [Oct 4, 2016]
 * Made packages no longer auto-start
 * No longer automatically picks up config file changes, instead waits for explicit restart

### 1.0.0 beta 2 [Oct 2, 2016]
 * Improved configuration and naming for mongodb metrics

### 1.0.0 beta 1 [Sept 28, 2016]
#### New! Shiny! Different!
* forked from [instrumental_tools](https://github.com/Instrumental/instrumental_tools)
* [telegraf](https://github.com/influxdata/telegraf)-based metric collection
* refactored custom metric collection

See [the instrumental_tools CHANGELOG](https://github.com/Instrumental/instrumental_tools/blob/master/CHANGELOG.md) for the old history.

Notable differences include: no windows support and lots of new services out of the box.

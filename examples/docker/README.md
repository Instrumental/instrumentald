# Docker Metrics

This script will generate performance metrics for each running Docker container based on the name of that container. It will also output information regarding the number of running docker containers for that host.

Each Docker container will have the following metrics output:

* `CONTAINER_NAME.system_total` - Total system CPU time spent for container
* `CONTAINER_NAME.user_total` - Total user CPU time spent for container
* `CONTAINER_NAME.system` - Current percent usage of system time spent for container
* `CONTAINER_NAME.user` - Current percent usage of user time spent for container
* `CONTAINER_NAME.cache_mb` - Current cache memory allocated for container
* `CONTAINER_NAME.rss_mb` - Current resident memory allocated for container
* `CONTAINER_NAME.mapped_file_mb` - Current mapped memory allocated for container
* `CONTAINER_NAME.swap_mb` - Current swap memory allocated for container

The following metric will be output only once for the host:

* `running` - The total number of docker containers running on the host

This script will only work if the `docker ps` process is executable by the same user that is running `instrument_server`. You should ensure that the user that executes the `instrument_server` process belongs to the `docker` group on your system.

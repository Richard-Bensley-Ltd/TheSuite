# MariaDB monitoring

* Basic monitoring achieved by sending 200/503 responses to a socket responder in systemd to test for service availability.
* Metrics get and push to an API endpoint in JSON format.

## Usage

    usage: monitor.py [-h] [-c CONFIG_FILE] [-g CONFIG_GROUP] [-t TIMEOUT] [--ping-timer PING_TIMER] [--ping-host PING_HOST] [--ping-port PING_PORT] [--metrics-timer METRICS_TIMER] [--metrics-host METRICS_HOST] [--metrics-port METRICS_PORT] [--metrics-endpoint METRICS_ENDPOINT]

    options:
    -h, --help            show this help message and exit
    -c CONFIG_FILE, --config-file CONFIG_FILE
    -g CONFIG_GROUP, --config-group CONFIG_GROUP
    -t TIMEOUT, --timeout TIMEOUT
                            Connection timeout in seconds to MariaDB
    --ping-timer PING_TIMER
                            Seconds between pings to MariaDB
    --ping-host PING_HOST
    --ping-port PING_PORT
    --metrics-timer METRICS_TIMER
                            Time in seconds between metrics queries
    --metrics-host METRICS_HOST
    --metrics-port METRICS_PORT
    --metrics-endpoint METRICS_ENDPOINT

## Example

Example usage in user terminal:

    /usr/local/bin/monitor.py -c /etc/my.cnf

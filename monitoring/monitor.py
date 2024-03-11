#!/usr/bin/env python3

import os
import time
import json
import http.client
import socket
import pymysql
import argparse
import threading

DEFAULT_CONFIG_FILE = "~/.my.cnf"
DEFAULT_CONFIG_GROUP = "client"
DEFAULT_TIMEOUT = 3
DEFAULT_METRICS_TIMER = 15
DEFAULT_PING_TIMER = 5
DEFAULT_PING_HOST = "127.0.0.1"
DEFAULT_PING_PORT = 8080
DEFAULT_METRICS_HOST = "127.0.0.1"
DEFAULT_METRICS_PORT = 9090
DEFAULT_METRICS_EP = "/api/endpoint"

KEY_SLAVE_STATUS = "slave_status"
KEY_GLOBAL_STATUS = "global_status"
KEY_GLOBAL_VARS = "global_vars"


class Metrics:
    def __init__(
        self,
        config: str = DEFAULT_CONFIG_FILE,
        group: str = DEFAULT_CONFIG_GROUP,
        timeout: int = 5,
        metrics_timer: int = DEFAULT_METRICS_TIMER,
        ping_timer: int = DEFAULT_PING_TIMER,
        ping_host: str = DEFAULT_PING_HOST,
        ping_port: int = DEFAULT_PING_PORT,
        metrics_host: str = DEFAULT_METRICS_HOST,
        metrics_port: int = DEFAULT_METRICS_PORT,
        metrics_endpoint: str = DEFAULT_METRICS_EP,
    ):
        config_path = os.path.expanduser(config)
        self.config = config_path
        self.group = group
        self.timeout = timeout
        self.ping_timer = ping_timer
        self.ping_host = ping_host
        self.ping_port = ping_port
        self.metrics_timer = metrics_timer
        self.metrics_host = metrics_host
        self.metrics_port = metrics_port
        self.metrics_endpoint = metrics_endpoint
        self.metrics_data = {}

    def query(self, sql):
        try:
            c = pymysql.connect(
                read_default_file=self.config,
                read_default_group=self.group,
                connect_timeout=self.timeout,
                cursorclass=pymysql.cursors.DictCursor,
            )
            cur = c.cursor()
            cur.execute(sql)
            return cur.fetchall()
        except pymysql.Error:
            print("ERROR failed to connect!")
            return []

    def ping(self) -> bool:
        try:
            c = pymysql.connect(
                read_default_file=self.config,
                read_default_group=self.group,
                connect_timeout=self.timeout,
                cursorclass=pymysql.cursors.DictCursor,
            )
            c.ping(reconnect=False)
            c.close()
            return True
        except pymysql.Error:
            return False

    def mariadb_status(self):
        # Return the status of ping() to a socket
        while True:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind((self.ping_host, self.ping_port))
                s.listen()
                c, a = s.accept()
                with c:
                    if self.ping():
                        print("ping ok")
                        c.sendall(b"HTTP/1.1 200 MariaDB is up\n\n")
                    else:
                        print("no ping")
                        c.sendall(b"HTTP/1.1 503 MariaDB is Unavailable\n\n")
            time.sleep(self.ping_timer)

    def binary_global_value(self, s):
        try:
            return float(s)
        except ValueError:
            if isinstance(s, str):
                s = s.lower()
                if (
                    s == "yes"
                    or s == "connected"
                    or s == "primary"
                    or s == "ok"
                    or s == "on"
                ):
                    return 1
                if s == "no" or s == "disconnected" or s == "off":
                    return 0
                if s == "connecting" or s == "slave" or s == "secondary":
                    return 2
        return 0

    def show_slave_status(self):
        sql = "SHOW ALL SLAVES STATUS"
        rows = self.query(sql)
        if rows:
            self.metrics_data[KEY_SLAVE_STATUS] = rows

    def show_global(self, sql, key):
        result = self.query(sql)
        if not result:
            return
        global_status = {}
        for r in result:
            n = r["Variable_name"]
            v = r["Value"]
            v = self.binary_global_value(v)
            global_status[n] = v

        self.metrics_data[key] = global_status

    def show_global_status(self):
        sql = "SHOW GLOBAL STATUS"
        self.show_global(sql, KEY_GLOBAL_STATUS)

    def show_global_variables(self):
        sql = "SHOW GLOBAL VARIABLES"
        self.show_global(sql, KEY_GLOBAL_VARS)

    def metrics(self):
        while True:
            if not self.ping():
                print("No ping, no metrics")
            else:
                self.show_global_status()
                self.show_global_variables()
                self.show_slave_status()
                print("metrics ok")
            time.sleep(self.metrics_timer)

    def push(self):
        c = http.client.HTTPConnection(self.metrics_host, self.metrics_port)
        headers = {"Content-type": "application/json"}
        data = json.dumps(self.metrics_data)
        try:
            c.request("POST", self.metrics_endpoint, data, headers)
            resp = c.getresponse()
            if resp == "200":
                print("Metrics send to API Endpoint")
            else:
                print("ERROR could not send metrics to endpoint!")
        except Exception as e:
            print(f"Error sending metrics: {e}")
        finally:
            c.close()

    def __call__(self):
        p = threading.Thread(target=self.mariadb_status, name="ping_thread")
        m = threading.Thread(target=self.metrics, name="metrics_thread")
        p.start()
        m.start()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-c", "--config-file", default=DEFAULT_CONFIG_FILE)
    parser.add_argument("-g", "--config-group", default=DEFAULT_CONFIG_GROUP)
    parser.add_argument(
        "-t",
        "--timeout",
        default=DEFAULT_TIMEOUT,
        help="Connection timeout in seconds to MariaDB",
    )
    parser.add_argument(
        "--ping-timer",
        default=DEFAULT_PING_TIMER,
        help="Seconds between pings to MariaDB",
    )
    parser.add_argument("--ping-host", default=DEFAULT_PING_HOST)
    parser.add_argument("--ping-port", default=DEFAULT_PING_PORT)
    parser.add_argument(
        "--metrics-timer",
        default=DEFAULT_METRICS_TIMER,
        help="Time in seconds between metrics queries",
    )
    parser.add_argument("--metrics-host", default=DEFAULT_METRICS_HOST)
    parser.add_argument("--metrics-port", default=DEFAULT_METRICS_PORT)
    parser.add_argument("--metrics-endpoint", default=DEFAULT_METRICS_EP)

    args = parser.parse_args()

    m = Metrics(
        config=args.config_file,
        group=args.config_group,
        timeout=args.timeout,
        ping_timer=args.ping_timer,
        metrics_timer=args.metrics_timer,
        metrics_host=args.metrics_host,
        metrics_port=args.metrics_port,
        metrics_endpoint=args.metrics_endpoint,
    )
    m()

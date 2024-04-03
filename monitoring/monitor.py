#!/usr/bin/env python3

import os
import time
import pymysql
import argparse
import threading
import numpy as np

DEFAULT_CONFIG_FILE = "~/.my.cnf"
DEFAULT_TIMEOUT = 3
DEFAULT_METRICS_TIMER = 15
DEFAULT_METRICS_DB = "~/.metrics.db"

KEY_SLAVE_STATUS = "slave_status"
KEY_GLOBAL_STATUS = "global_status"
KEY_GLOBAL_VARS = "global_vars"


class Metrics:
    def __init__(
        self,
        group: str,
        config: str = DEFAULT_CONFIG_FILE,
        metrics_timer: int = DEFAULT_METRICS_TIMER,
        metrics_db: str = DEFAULT_METRICS_DB,
    ):
        config_path = os.path.expanduser(config)
        self.config = config_path
        self.group = group
        self.metrics_timer = metrics_timer
        self.metrics_db = metrics_db
        self.metrics_type = np.dtype(
            [
                ("timestamp", np.int64),
                ("server", "U32"),
                ("metric", "U64"),
                ("value", np.float64),
            ]
        )
        self.metrics = np.array([], dtype=self.metrics_type)

    def query(self, sql):
        try:
            c = pymysql.connect(
                read_default_file=self.config,
                read_default_group=self.group,
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

    def value_to_int(self, s):
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
            v = self.value_to_int(v)
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

    def __call__(self):
        m = threading.Thread(target=self.metrics, name="metrics_thread")
        m.start()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-c", "--config-file", default=DEFAULT_CONFIG_FILE)
    parser.add_argument("-g", "--config-groups")
    parser.add_argument("-t", "--metrics-timer", default=DEFAULT_METRICS_TIMER)
    parser.add_argument("-d", "--metrics-db", default=DEFAULT_METRICS_DB)

    args = parser.parse_args()

    groups = args.config_groups.split(",")
    servers = []
    for group_name in groups:
        if group_name != "" or group_name is not None:
            m = Metrics(
                config=args.config_file,
                group=group_name,
                metrics_timer=args.metrics_timer,
                metrics_db=args.metrics_db,
            )
    for server in servers:
        server()

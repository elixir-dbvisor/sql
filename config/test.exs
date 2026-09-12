# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

import Config

opts = [
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "sql_test#{System.get_env("MIX_TEST_PARTITION")}",
  adapter: SQL.Adapters.Postgres,
  ssl: false,
  size: 10,
  port: 5433
]

config :sql, pools: [
  default: opts,
  scram: Keyword.merge(opts, [size: 1, port: 5434]),
  md5: Keyword.merge(opts, [size: 1, port: 5436]),
  ssl: Keyword.merge(opts, [ssl: true, size: 1, port: 5435]),
]

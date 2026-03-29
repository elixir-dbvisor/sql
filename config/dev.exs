# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

import Config

config :sql, pools: [
  default: [
    username: "postgres",
    password: "postgres",
    hostname: "localhost",
    database: "sql_dev",
    adapter: SQL.Adapters.Postgres,
    ssl: false
  ]
]

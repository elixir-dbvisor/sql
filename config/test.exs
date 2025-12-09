# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

import Config

config :sql, pools: [
  default: %{
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "sql_test#{System.get_env("MIX_TEST_PARTITION")}",
  adapter: SQL.Adapters.Postgres,
  ssl: false}
]

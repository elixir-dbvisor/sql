# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

import Config

config :sql, env: config_env()

import_config "#{config_env()}.exs"

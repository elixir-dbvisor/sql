<!--
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor
-->

# Changelog

## v0.2.0 (TBA)

### Enhancement
 - SQL 2016 conformance [#6](https://github.com/elixir-dbvisor/sql/pull/6).
 - Lexer and Parser generated from the [SQL 2023 BNF](https://standards.iso.org/iso-iec/9075/-2/ed-6/en/) [#5](https://github.com/elixir-dbvisor/sql/pull/5).
 - Added SQL.Token behaviour used to implement adapters [#5](https://github.com/elixir-dbvisor/sql/pull/5).
 - ANSI adapter [#5](https://github.com/elixir-dbvisor/sql/pull/5).
 - MySQL adapter [#5](https://github.com/elixir-dbvisor/sql/pull/5).
 - PostgreSQL adapter [#5](https://github.com/elixir-dbvisor/sql/pull/5).
 - TDS adapter [#5](https://github.com/elixir-dbvisor/sql/pull/5).
 - Improve SQL generation with 4-600x compared to Ecto [#7](https://github.com/elixir-dbvisor/sql/pull/7).
 - Ensure inspect follows the standard [representation](https://hexdocs.pm/elixir/Inspect.html#module-inspect-representation) [#4](https://github.com/elixir-dbvisor/sql/pull/4)

### Deprecation
 - token_to_sql/2 is deprecated in favor of SQL.Token behaviour token_to_string/2 [#5](https://github.com/elixir-dbvisor/sql/pull/5).


## v0.1.0 (2025-03-01)

Initial release.

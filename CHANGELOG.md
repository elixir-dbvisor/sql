<!--
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor
-->

# Changelog

## v0.4.0 (2025-XX-XX)

### Enhancement
 - Improved SQL lexing performance with other 50%  [91dc464](https://github.com/elixir-dbvisor/sql/commit/91dc464242d2e644b8c7210ac79bcf5f94c35ed8).
 - Added warnings for unknown operators [5bd7ec3](https://github.com/elixir-dbvisor/sql/commit/5bd7ec391c028a592dc4c94ead7a8002113790b9).
 - Added SQL.map/2 and implemented enumerable for SQL [a646203](https://github.com/elixir-dbvisor/sql/commit/a646203da05bc1e59b8f0df65b1a285ab1740a6c).
 - Added SQL Mix.Task.Compiler for sql files [4ce5b24](https://github.com/elixir-dbvisor/sql/commit/4ce5b243d2ec36d51bc1a3e5a25802b2d4a18b79).

## v0.3.0 (2025-08-01)

### Enhancement
 - Improve SQL generation with over 100x compared to Ecto [#12](https://github.com/elixir-dbvisor/sql/pull/12), [#19](https://github.com/elixir-dbvisor/sql/pull/19).
 - Fix bug for complex CTE [#15](https://github.com/elixir-dbvisor/sql/pull/15). Thanks to @kafaichoi
 - Support for PostgresSQL GiST operators [#18](https://github.com/elixir-dbvisor/sql/pull/18). Thanks to @ibarchenkov
 - `float` and `integer` nodes have now become `numeric` with metadata to distinguish `sign`, `whole` and `fractional` [#19](https://github.com/elixir-dbvisor/sql/pull/19).
 - `keyword` nodes are now `ident` with metadata distinguish if it's a `keyword` [#19](https://github.com/elixir-dbvisor/sql/pull/19).
 - `SQL.Lexer.lex/4` now returns `{:ok, context, tokens}` [#19](https://github.com/elixir-dbvisor/sql/pull/19).
 - `SQL.Parser.parse/1` has become `SQL.Parser.parse/2` and takes `tokens` and `context` from `SQL.Lexer.lex/4` and returns `{:ok, context, tokens}` or raises an error [#19](https://github.com/elixir-dbvisor/sql/pull/19).
 - Support for compile time warnings on missing relations in a query. [#22](https://github.com/elixir-dbvisor/sql/pull/22)
 - `mix sql.get` creates a lock file which are used to generate warnings at compile time. [#22](https://github.com/elixir-dbvisor/sql/pull/22)
 - Support SQL formatting. [#22](https://github.com/elixir-dbvisor/sql/pull/22)

### Deprecation
 - token_to_string/2 is deprecated in favor of to_iodata/3 [#22](https://github.com/elixir-dbvisor/sql/pull/22).


## v0.2.0 (2025-05-04)

### Enhancement
 - SQL 2016 conformance [#6](https://github.com/elixir-dbvisor/sql/pull/6).
 - Lexer and Parser generated from the [SQL 2023 BNF](https://standards.iso.org/iso-iec/9075/-2/ed-6/en/) [#5](https://github.com/elixir-dbvisor/sql/pull/5).
 - Added SQL.Token behaviour used to implement adapters [#5](https://github.com/elixir-dbvisor/sql/pull/5).
 - ANSI adapter [#5](https://github.com/elixir-dbvisor/sql/pull/5).
 - MySQL adapter [#5](https://github.com/elixir-dbvisor/sql/pull/5).
 - PostgreSQL adapter [#5](https://github.com/elixir-dbvisor/sql/pull/5).
 - TDS adapter [#5](https://github.com/elixir-dbvisor/sql/pull/5).
 - Improve SQL generation with 57-344x compared to Ecto [#7](https://github.com/elixir-dbvisor/sql/pull/7) [#4](https://github.com/elixir-dbvisor/sql/pull/4).
 - Ensure inspect follows the standard [representation](https://hexdocs.pm/elixir/Inspect.html#module-inspect-representation) [#4](https://github.com/elixir-dbvisor/sql/pull/4).
 - Ensure storage is setup when running benchmarks [#5](https://github.com/elixir-dbvisor/sql/pull/5).

### Deprecation
 - token_to_sql/2 is deprecated in favor of SQL.Token behaviour token_to_string/2 [#11](https://github.com/elixir-dbvisor/sql/pull/11).

## v0.1.0 (2025-03-01)

Initial release.

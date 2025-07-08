<!--
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor
-->

# Changelog

## v0.3.0 (2025-08-01)

### Enhancement
 - Improve SQL generation with 57-344x compared to Ecto [#12](https://github.com/elixir-dbvisor/sql/pull/12).
 - Fix bug for complex CTE [#15](https://github.com/elixir-dbvisor/sql/pull/15). Thanks to @kafaichoi
 - Support for PostgresSQL GiST operators [#18](https://github.com/elixir-dbvisor/sql/pull/18). Thanks to @ibarchenkov
 - `float` and `integer` nodes have now become `numeric` with metadata to distinguish `sign`, `whole` and `fractional` [#19](https://github.com/elixir-dbvisor/sql/pull/19).
 - `keyword` nodes are now `ident` with metadata distinguish if it's a `keyword` [#19](https://github.com/elixir-dbvisor/sql/pull/19).
 - `SQL.Lexer.lex/4` now returns `{:ok, context, tokens}` [#19](https://github.com/elixir-dbvisor/sql/pull/19).
 - `SQL.Parser.parse/1` has become `SQL.Parser.parse/2` and takes `tokens` and `context` from `SQL.Lexer.lex/4` and returns `{:ok, context, tokens}` or raises an error [#19](https://github.com/elixir-dbvisor/sql/pull/19).


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

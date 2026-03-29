<!--
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor
-->

# Contributing to SQL

We invite contributions to SQL, in order for you to commit with confindance 
you can create the database with `mix sql.create` 
and explore the library in `iex -S mix`. 

For conformance testing you'll need to clone https://github.com/elliotchance/sqltest 
and run `mix sql.gen.test ../sqltest/standards/2016`.

You can run benchmarks with `mix sql.bench`, remember that performance can differ 
based on concurrency.

As we're pre 1.0, then breaking changes are allowed, although they will only be merged, if
they improve: userability, correctness and performance.

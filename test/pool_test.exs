# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

defmodule SQL.PoolTest do
  use ExUnit.Case, async: true

  describe "SQL.Pool struct" do
    test "has default values" do
      pool = %SQL.Pool{}
      assert pool.ssl == false
      assert pool.timeout == 15_000
      assert pool.name == :default
      assert pool.domain == :inet
      assert pool.type == :stream
      assert pool.protocol == :tcp
      assert pool.family == :inet
      assert pool.port == 5432
      assert pool.addr == {127, 0, 0, 1}
    end

    test "accepts custom values" do
      pool = %SQL.Pool{
        name: :custom_pool,
        port: 5433,
        timeout: 30_000,
        ssl: true
      }
      assert pool.name == :custom_pool
      assert pool.port == 5433
      assert pool.timeout == 30_000
      assert pool.ssl == true
    end

    test "has socket options" do
      pool = %SQL.Pool{}
      assert pool.socket[:keepalive] == true
      assert pool.socket[:linger][:onoff] == true
      assert pool.socket[:linger][:linger] == 5
    end

    test "has otp options" do
      pool = %SQL.Pool{}
      assert pool.otp[:rcvbuf] == {64_000, 128_000}
    end
  end

  describe "SQL.Pool inspect" do
    test "inspect hides sensitive fields" do
      pool = %SQL.Pool{username: "user", password: "secret"}
      result = inspect(pool)
      refute String.contains?(result, "secret")
      refute String.contains?(result, "password")
    end
  end
end

defmodule SQL.Case do
  use ExUnit.CaseTemplate

  using opts do
    quote do
      use ExUnit.Case, unquote(opts)
      import ExUnit.Case, except: [test: 2]
      import unquote(__MODULE__), only: [test: 2]
    end
  end

  defmacro test(description, do: block) do
    quote do
      ExUnit.Case.test unquote(description) do
        SQL.transaction do
          unquote(block)
        end
      end
    end
  end
end

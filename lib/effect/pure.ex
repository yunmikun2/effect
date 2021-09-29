defmodule Effect.Pure do
  @moduledoc false

  alias Effect.{Executable, Interpretable}

  defstruct [:value]

  def new(value) do
    %__MODULE__{value: value}
  end

  defimpl Executable do
    def execute(%{value: value}) do
      {:ok, value}
    end
  end

  defimpl Interpretable do
    def interpret(effect, _interpreter) do
      Executable.execute(effect)
    end
  end

  defimpl Inspect do
    def inspect(_effect, _) do
      "#Effect<>"
    end
  end
end

defmodule Effect.BindErr do
  @moduledoc false

  alias Effect.{Executable, Interpretable}

  @derive [Executable]
  defstruct [:effect, :fun]

  def new(effect, fun) do
    %__MODULE__{effect: effect, fun: fun}
  end

  defimpl Interpretable do
    def interpret(%{effect: effect, fun: fun}, interpreter) do
      with {:error, error} <- Interpretable.interpret(effect, interpreter) do
        Interpretable.interpret(fun.(error), interpreter)
      end
    end
  end

  defimpl Inspect do
    def inspect(_effect, _) do
      "#Effect<>"
    end
  end
end

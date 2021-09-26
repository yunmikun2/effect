defmodule Effect.Monad do
  @moduledoc """
  Provides a monadic interface for effects.
  """

  defmodule Pure do
    @moduledoc false
    defstruct [:value]
    def new(value), do: %__MODULE__{value: value}

    defimpl Effect do
      def execute(%{value: value}), do: {:ok, value}
    end
  end

  def return(value) do
    Pure.new(value)
  end

  defmodule Map do
    @moduledoc false
    defstruct [:effect, :fun]
    def new(effect, fun), do: %__MODULE__{effect: effect, fun: fun}

    defimpl Effect do
      def execute(%{effect: effect, fun: fun}) do
        with {:ok, result} <- Effect.execute(effect) do
          {:ok, fun.(result)}
        end
      end
    end
  end

  @spec map(Effect.t(), (term -> term)) :: Effect.t()
  def map(effect, fun) do
    Map.new(effect, fun)
  end

  defmodule Bind do
    @moduledoc false
    defstruct [:effect, :fun]
    def new(effect, fun), do: %__MODULE__{effect: effect, fun: fun}

    defimpl Effect do
      def execute(%{effect: effect, fun: fun}) do
        with {:ok, result} <- Effect.execute(effect) do
          Effect.execute(fun.(result))
        end
      end
    end
  end

  @spec bind(Effect.t(), (term -> Effect.t())) :: Effect.t()
  def bind(effect, fun) do
    Bind.new(effect, fun)
  end
end

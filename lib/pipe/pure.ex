defmodule Pipe.Pure do
  @moduledoc """
  Provides an `Pipe.Effect` with no real effect.

  Supposed to be used when instead of effect you need to provide
  a pure value.
  """

  defstruct [:value]

  def new(value), do: %__MODULE__{value: value}

  defimpl Pipe.Effect do
    def execute(%{value: value}), do: {:ok, value}
  end
end

defmodule Effect.Fail do
  @moduledoc false
  defstruct [:code]
  def new(code), do: %__MODULE__{code: code}

  defimpl Effect do
    def execute(%{code: code}), do: {:error, code}
  end
end

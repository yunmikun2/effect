defmodule Effect.Fail do
  @moduledoc false

  alias Effect.Executable

  defstruct [:code]

  def new(code) do
    %__MODULE__{code: code}
  end

  defimpl Executable do
    def execute(%{code: code}) do
      {:error, code}
    end
  end

  defimpl Inspect do
    def inspect(_effect, _) do
      "#Effect<>"
    end
  end
end

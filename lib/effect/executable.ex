defprotocol Effect.Executable do
  @moduledoc """
  Provides a way to execute an effect.
  """

  @spec execute(t) :: {:ok, term} | {:error, term}
  def execute(effect)
end

defimpl Effect.Executable, for: Any do
  alias Effect.{Executable, Interpretable}

  defmacro __deriving__(module, _struct, _opts) do
    quote do
      defimpl Effect.Executable, for: unquote(module) do
        def execute(effect) do
          Interpretable.interpret(effect, &Executable.execute/1)
        end
      end
    end
  end

  def execute(_effect) do
    raise "oops"
  end
end

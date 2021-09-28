defprotocol Effect.Interpretable do
  @moduledoc """
  Provides a way to "fold" composed actions.
  """

  @fallback_to_any true

  @type result :: {:ok, term} | {:error, term}

  @spec interpret(t, (t -> result)) :: result
  def interpret(effect, map)
end

defimpl Effect.Interpretable, for: Any do
  def interpret(effect, interpreter) do
    interpreter.(effect)
  end
end

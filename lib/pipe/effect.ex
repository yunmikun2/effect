defprotocol Pipe.Effect do
  @moduledoc """
  Provides a way to execute effects.
  """

  @doc """
  Execute the effect.
  """
  @spec execute(__MODULE__.t()) :: {:ok, term} | {:error, term}
  def execute(effect)
end

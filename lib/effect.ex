defprotocol Effect do
  @moduledoc """
  Provides an effect abstraction.
  """

  @spec execute(t) :: {:ok, term} | {:error, term}
  def execute(effect)
end

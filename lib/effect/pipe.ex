defmodule Effect.Pipe do
  @moduledoc """
  Provides composition of effects where result of each resulting
  action is assigned a key.
  """

  import Effect, only: [bind: 2, fail: 1, map: 2, or_else: 2, return: 1]

  @doc """
  Return an empty pipe with no actions.
  """
  @spec new :: Effect.t()
  def new do
    return(%{})
  end

  @doc """
  Return a pipe where the result of the `effect` is assigned the `key`.
  """
  @spec new(Effect.t(), atom) :: Effect.t()
  def new(effect, key) when is_atom(key) do
    then(new(), key, fn _ -> effect end)
  end

  @doc """
  Add new action to the pipe.
  """
  @spec then(Effect.t(), atom, (%{required(atom) => term} -> Effect.t())) :: Effect.t()
  def then(pipe, key, fun) do
    bind(pipe, fn state ->
      assert_key_not_used!(state, key)

      fun.(state)
      |> map(&Map.put(state, key, &1))
      |> or_else(fn error ->
        fail(%{results: state, error: %{key => error}})
      end)
    end)
  end

  defp assert_key_not_used!(state, key) do
    case state do
      %{^key => _} -> raise ArgumentError, "key #{key} already used"
      _ -> :ok
    end
  end
end

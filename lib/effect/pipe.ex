defmodule Effect.Pipe do
  @moduledoc """
  Provides composition of effects where result of each resulting
  action is assigned a key.
  """

  import Effect, only: [bind: 2, fail: 1, map: 2, or_else: 2, return: 1]

  @doc """
  Return an empty pipe with no actions.

  ## Example

      iex(1)> Effect.Pipe.new() |> Effect.execute()
      {:ok, %{}}
  """
  @spec new :: Effect.t()
  def new do
    return(%{})
  end

  @doc """
  Return a pipe where the result of the `effect` is assigned the `key`.

  ## Example

      iex(1)> Effect.return(1)
      ...(1)> |> Effect.Pipe.new(:x)
      ...(1)> |> Effect.execute()
      {:ok, %{x: 1}}
  """
  @spec new(Effect.t(), term) :: Effect.t()
  def new(effect, key) do
    then(new(), key, fn _ -> effect end)
  end

  @doc """
  Add new action to the pipe.

  ## Example

      iex(1)> Effect.Pipe.new()
      ...(1)> |> Effect.Pipe.then(:x, fn _ -> Effect.return(1) end)
      ...(1)> |> Effect.Pipe.then(:y, fn %{x: x} -> Effect.return(x + 1) end)
      ...(1)> |> Effect.execute()
      {:ok, %{x: 1, y: 2}}

  In case we meet an error, all results so far will be returned with
  an error and the key at which the error happened.

      iex(1)> Effect.Pipe.new()
      ...(1)> |> Effect.Pipe.then(:x, fn _ -> Effect.return(1) end)
      ...(1)> |> Effect.Pipe.then(:y, fn _ -> Effect.fail(:oops) end)
      ...(1)> |> Effect.execute()
      {:error, %{results: %{x: 1}, error: %{y: :oops}}}

  Note that duplicated keys are not allowed and an error will be
  raised in runtime.

      iex(1)> Effect.Pipe.new()
      ...(1)> |> Effect.Pipe.then(:x, fn _ -> Effect.return(1) end)
      ...(1)> |> Effect.Pipe.then(:x, fn %{x: x} -> Effect.return(x + 1) end)
      ...(1)> |> Effect.execute()
      ** (ArgumentError) key :x already used
  """
  @spec then(Effect.t(), term, (map -> Effect.t())) :: Effect.t()
  def then(pipe, key, fun) when is_function(fun, 1) do
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
      %{^key => _} -> raise ArgumentError, "key #{inspect(key)} already used"
      _ -> :ok
    end
  end
end

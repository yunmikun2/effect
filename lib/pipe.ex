defmodule Pipe do
  @moduledoc """
  Provides computation framework.

  ## Example

      iex(1)> Pipe.new()
      ...(1)> |> Pipe.then(:x, fn _ -> Pipe.Pure.new(2) end)
      ...(1)> |> Pipe.switch(fn %{x: x} ->
      ...(1)>   if rem(x, 2) == 0 do
      ...(1)>     Pipe.return(:half, x / 2)
      ...(1)>   else
      ...(1)>     Pipe.new
      ...(1)>   end
      ...(1)> end)
      ...(1)> |> Pipe.execute()
      {:ok, %{half: 1.0, x: 2}}
  """

  defstruct actions: []

  alias __MODULE__.{Effect, Error}

  @opaque t :: %__MODULE__{}

  @doc """
  Return an empty `Pipe`.
  """
  @spec new() :: t
  def new do
    %__MODULE__{}
  end

  @doc """
  Wrap the `value` into a `Pipe` under the specified `key`.
  """
  @spec return(atom, term) :: t
  def return(key, value) when is_atom(key) and not is_nil(key) do
    put(new(), key, {:value, fn -> value end})
  end

  @doc """
  Add a new continuation with the provided `key`
  """
  @spec then(t, atom, (map -> Effect.t())) :: t
  def then(%__MODULE__{} = this, key, action)
      when is_atom(key) and not is_nil(key) and is_function(action, 1) do
    put(this, key, {:map, action})
  end

  @doc """
  Add a new continuation that returns another `Pipe` under the
  specified `key`.
  """
  @spec switch(t, (map -> t)) :: t
  def switch(%__MODULE__{} = this, action) when is_function(action, 1) do
    put(this, nil, {:bind, action})
  end

  defp put(%__MODULE__{actions: actions}, key, fun) do
    %__MODULE__{actions: [{key, fun} | actions]}
  end

  @doc """
  Execute the pipeline.
  """
  @spec execute(t) :: {:ok, %{required(atom) => term}} | {:error, Error.t()}
  def execute(this, executor \\ &Effect.execute/1) do
    do_execute(this, %{}, executor)
  end

  defp do_execute(%__MODULE__{actions: actions}, state, executor) do
    result =
      actions
      |> Enum.reverse()
      |> Enum.reduce({:ok, state}, fn {key, action}, mstate ->
        with {:ok, state} <- mstate do
          handle_action(action, state, key, executor)
        end
      end)

    with {:error, {state, key, error}} <- result do
      {:error, %Error{errors: %{key => error}, results: state}}
    end
  end

  defp handle_action({:value, fun}, state, key, _executor) do
    assert_key_not_used!(key, state)
    {:ok, Map.put(state, key, fun.())}
  end

  defp handle_action({:map, fun}, state, key, executor) do
    assert_key_not_used!(key, state)

    case executor.(fun.(state)) do
      {:ok, result} -> {:ok, Map.put(state, key, result)}
      {:error, error} -> {:error, {state, key, error}}
    end
  end

  defp handle_action({:bind, fun}, state, _key, executor) do
    case fun.(state) do
      %__MODULE__{} = child ->
        do_execute(child, state, executor)

      unknown ->
        raise ArgumentError,
              "bind expected a function returning a `Pipe`," <>
                "got: #{inspect(unknown)}"
    end
  end

  defp assert_key_not_used!(key, actions) do
    case actions do
      %{^key => _} -> raise ArgumentError, "key #{key} was already used"
      _ -> :ok
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(pipe, opts) do
      actions =
        pipe.actions
        |> Enum.map(&elem(&1, 0))
        |> Enum.reject(&is_nil/1)
        |> Enum.reverse()

      container_doc("#Pipe<", actions, ">", opts, fn a, _ -> to_string(a) end)
    end
  end
end

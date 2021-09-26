defmodule Effect.Pipe do
  @moduledoc false

  defstruct keys: MapSet.new(), actions: []

  @opaque t :: %__MODULE__{}

  @spec new :: Effect.t()
  def new do
    %__MODULE__{}
  end

  @spec new(Effect.t(), atom) :: Effect.t()
  def new(effect, key) when is_atom(key) do
    then(new(), key, fn _ -> effect end)
  end

  @spec then(t, atom, (%{required(atom) => term} -> Effect.t())) :: Effect.t()
  def then(%__MODULE__{keys: keys, actions: actions} = pipe, key, fun) do
    if MapSet.member?(keys, key) do
      raise ArgumentError, "key #{key} already used"
    end

    %__MODULE__{pipe | keys: MapSet.put(keys, key), actions: [{key, fun} | actions]}
  end

  def reduce(%__MODULE__{actions: actions}, reducer) do
    actions
    |> Enum.reverse()
    |> Enum.reduce({:ok, %{}}, fn {key, fun}, mstate ->
      with {:ok, state} <- mstate do
        case reducer.(fun.(state)) do
          {:ok, result} -> {:ok, Map.put(state, key, result)}
          {:error, error} -> {:error, %{key => error}}
        end
      end
    end)
  end

  defimpl Effect do
    import Effect.Monad, only: [return: 1, bind: 2]

    alias Effect.Fail

    def execute(%{actions: actions}) do
      actions
      |> Enum.reverse()
      |> Enum.reduce(return(%{}), fn {key, fun}, effect ->
        bind(effect, fn state ->
          case Effect.execute(fun.(state)) do
            {:ok, result} -> return(Map.put(state, key, result))
            {:error, error} -> Fail.new(%{key => error})
          end
        end)
      end)
      |> Effect.execute()
    end
  end
end

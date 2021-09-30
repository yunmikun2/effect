defprotocol Effect.Interpretable do
  @moduledoc """
  Provides a way to execute composed actions with interpreter
  defferent from `Effect.Executable.execute/1`.

  > **Note:** Most likely you don't need to implement this protocol
  > unless you define an effect that wraps other effects.

  ## Effect composition

  While `Effect.Executable` enables us to define side-effects for
  an effect, this protocol provides a way to describe alternative way
  of execution for effects that wrap another effects. We have such
  effects in this library: `Effect.map/2`, `Effect.bind/2`,
  `Effect.lift2/3`, `Effect.or_else/2`, and `Effect.Pipe.then/3`
  produce new effects based on effects passed to them in arguments.
  So we need a way to go through all the real effects these effects
  hide inside (for example, when we don't need to execute side-effects
  in tests).

  This protocol is usefull when we need to define an effect that wraps
  other effects. It may be some alternative way of effect composition
  like `Effect.Pipe`, an effect that wraps another (compound)
  effect into a database transaction, or something else.

  > **Note:** When defining your own compositional effect, you may use
  > `Effect.Pipe` as a reference.

  > **Note:** The implementation of `Effect.Interpretable` must not
  > contain neither side-effects, nor `Effect.Executable.execute/1`
  > calls.

  ## Interpretable and Executable interchangability

  This protocol is autoimplemented for any structure, so if you define
  a simple effect that doesn't wrap any effects, you don't need to
  manually implement it.

  Also, you can derive `Effect.Executable` for a structure if it
  implements `Effect.Interpretable`.
  """

  @fallback_to_any true

  @type result :: {:ok, term} | {:error, term}

  @doc """
  Interpret the effect.

  It means that the effect will be executed with provided
  `interpreter` instead of `execute/1`.
  """
  @spec interpret(t, (t -> result)) :: result
  def interpret(effect, map)
end

defimpl Effect.Interpretable, for: Any do
  def interpret(effect, interpreter) do
    interpreter.(effect)
  end
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

  def execute(_effect), do: raise("oops")
end

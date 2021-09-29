defmodule Effect do
  @moduledoc """
  Functions to work with effects.
  """

  alias Effect.{Bind, BindErr, Executable, Fail, Interpretable, Map, Pure}

  @type t :: Executable.t() | Interpretable.t()
  @type t(_a) :: t

  @doc """
  Wrap a pure value into an effect.

  ## Example

      iex(1)> Effect.execute(Effect.return(1))
      {:ok, 1}

  > **Note:** While being an effect, the returned value isn't captured
  > by `Effect.Interpretable` protocol, because otherwise you would
  > need to know how the effect is implemented to get the pure value
  > from its insides.

      iex(1)> Effect.interpret(Effect.return(1), fn :unknown ->
      ...(1)>   {:error, :unknown}
      ...(1)> end)
      {:ok, 1}
  """
  @spec return(a) :: t(a) when a: term
  def return(value) do
    Pure.new(value)
  end

  @doc """
  Map a value that the effect returns to another pure value.

  ## Example

      iex(1)> Effect.return(1)
      ...(1)> |> Effect.map(fn x -> x + 1 end)
      ...(1)> |> Effect.execute()
      {:ok, 2}
  """
  @spec map(t(a), (a -> b)) :: t(b) when a: term, b: term
  def map(effect, fun) when is_function(fun, 1) do
    Map.new(effect, fun)
  end

  @doc """
  Pass the value returned from execution of the first effect into the
  provided function that returns another effect.

  ## Example

      iex(1)> Effect.return(1)
      ...(1)> |> Effect.bind(fn x -> Effect.return(x + 1) end)
      ...(1)> |> Effect.execute()
      {:ok, 2}
  """
  @spec bind(t(a), (a -> t(b))) :: t(b) when a: term, b: term
  def bind(effect, fun) when is_function(fun, 1) do
    Bind.new(effect, fun)
  end

  @doc """
  Catch an error and return new effect. It acts like `bind/2` but
  instead of ok-value it uses the error one.

  ## Example

      iex(1)> Effect.fail("oops")
      ...(1)> |> Effect.or_else(fn "oops" -> Effect.fail(:oops) end)
      ...(1)> |> Effect.execute()
      {:error, :oops}

      iex(1)> Effect.fail("oops")
      ...(1)> |> Effect.or_else(fn "oops" -> Effect.return(:phew) end)
      ...(1)> |> Effect.execute()
      {:ok, :phew}
  """
  @spec or_else(t(a), (term -> t(b))) :: t(a) when a: term, b: term
  def or_else(effect, fun) when is_function(fun, 1) do
    BindErr.new(effect, fun)
  end

  @doc """
  Merge two effects `ea` and `eb` with function `fun` that works on
  their results and produces another effect.

  ## Example

      iex(1)> a = Effect.return(1)
      iex(2)> b = Effect.return(2)
      iex(3)> Effect.lift2(a, b, &(&1 + &2))
      ...(3)> |> Effect.execute()
      {:ok, 3}

      iex(1)> a = Effect.return(1)
      iex(2)> b = Effect.fail("oops")
      iex(3)> Effect.lift2(a, b, &(&1 + &2))
      ...(3)> |> Effect.execute()
      {:error, "oops"}

      iex(1)> a = Effect.fail("oh no")
      iex(2)> b = Effect.fail("oops")
      iex(3)> Effect.lift2(a, b, &(&1 + &2))
      ...(3)> |> Effect.execute()
      {:error, "oh no"}
  """
  @spec lift2(t(a), t(b), (a, b -> c)) :: t(c) when a: term, b: term, c: term
  def lift2(ea, eb, fun) when is_function(fun, 2) do
    bind(ea, fn a ->
      map(eb, fn b ->
        fun.(a, b)
      end)
    end)
  end

  @doc """
  Wrap a pure value into a failing effect.

  ## Example

      iex(1)> Effect.execute(Effect.fail(:oops))
      {:error, :oops}

  > **Note:** While being an effect, the returned value isn't captured
  > by `Effect.Interpretable` protocol, because otherwise you would
  > need to know how the effect is implemented to get the pure value
  > from its insides.

      iex(1)> Effect.interpret(Effect.fail(:oops), fn :unknown ->
      ...(1)>   {:ok, :unknown}
      ...(1)> end)
      {:error, :oops}
  """
  @spec fail(term) :: t
  def fail(error) do
    Fail.new(error)
  end

  @type result :: {:ok, term} | {:error, term}

  @doc """
  Execute the effect.
  """
  @spec execute(t) :: result
  def execute(effect) do
    Executable.execute(effect)
  end

  @doc """
  Interpret the effect.

  It means that the effect will be executed with provided
  `interpreter` instead of `execute/1`.
  """
  @spec interpret(t, (t -> result)) :: result
  def interpret(effect, interpreter) when is_function(interpreter, 1) do
    Interpretable.interpret(effect, interpreter)
  end
end

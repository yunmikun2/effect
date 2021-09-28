defmodule Effect do
  @moduledoc """
  Provides an effect abstraction.
  """

  alias Effect.{Bind, BindErr, Executable, Fail, Interpretable, Map, Pure}

  @type t :: Executable.t() | Interpretable.t()
  @type t(_a) :: t

  @spec return(a) :: t(a) when a: term
  def return(value) do
    Pure.new(value)
  end

  @spec map(t(a), (a -> b)) :: t(b) when a: term, b: term
  def map(effect, fun) do
    Map.new(effect, fun)
  end

  @spec bind(t(a), (a -> t(b))) :: t(b) when a: term, b: term
  def bind(effect, fun) do
    Bind.new(effect, fun)
  end

  @spec or_else(t(a), (term -> t(b))) :: t(a) when a: term, b: term
  def or_else(effect, fun) do
    BindErr.new(effect, fun)
  end

  @spec lift(t(a), t(b), (a, b -> t(c))) :: t(c) when a: term, b: term, c: term
  def lift(ea, eb, fun) do
    bind(ea, fn a ->
      bind(eb, fn b ->
        fun.(a, b)
      end)
    end)
  end

  @spec fail(term) :: t
  def fail(error) do
    Fail.new(error)
  end

  @type result :: {:ok, term} | {:error, term}

  @spec execute(t) :: result
  def execute(effect) do
    Executable.execute(effect)
  end

  @spec interpret(t, (t -> result)) :: result
  def interpret(effect, interpreter) do
    Interpretable.interpret(effect, interpreter)
  end
end

# Effect

Elixir library that provides an abstraction for composable "effects".

## Introduction

The library is based on three decisions that influence its design:
  - side-effects are represented as data structures, so we execute
    them via a protocol;
  - no macros or DSLs that make Elixir a different language;
  - effects must be composable and reusable.

### Side-effects as data

We wanted a way to express any side-effect as data that can be
checked in tests without affecting the real world. So we have
`Effect.Executable` protocol with a function -- `execute/1` -- that
takes an arbitrary data that implements the protocol.

The implementation of the `execute/1` function must return either
`{:ok, term}`, or `{:error, term}` which may be considered standard
for almost every action we use in Elixir anyway.

```elixir
defmodule MyApp.LoggerEffect do
  defstruct [:msg]
  def new(msg), do: %__MODULE__{msg: msg}

  defimpl Effect.Executable do
    require Logger

    def execute(%{msg: msg}) do
      Logger.info(msg)
      # Note: We need an ok-tuple, so if our action returns nothing of
      # use, we return either `{:ok, nil}`, or `{:ok, :ok}`.
      {:ok, nil}
    end
  end
end
```

Now your logic code can return the data struct that implements
`Effect.Executable`, which can be checked in tests without running
actual side-effect. You just pass this value to `Effect.execute/1` and
go.

```elixir
defmodule MyApp.Add do
  def perform(a, b) do
    MyApp.LoggerEffect.new("#{a} + #{b} = #{a + b}")
  end
end

MyApp.Add.perform(2, 2) |> Effect.execute() # => "2 + 2 = 4"
```

### No sophisticated macros or DSLs

Elixir is similar to Lisp in its ability to extend the language so
that it's no more the language it was before. Some people see it
as an advantage, but, really, have you seen a code that abuses that
ability? At best it's just hard to read, at worst you need to learn a
complitely new language.

This library uses only mechanisms already existing in Elixir language:
structs, functions, and protocols. You don't need to learn new syntax,
only grasp a couple of simple concepts.

### Effects are composable

It would be pretty strange if your logic code always executed only one
side-effect per action. Usually we have to run multiple side-effects
on one action. Sometimes we need to run some side-effects on some
condition. Or we may want to run them in some kind of a loop. This
library provides a couple of ways to compose the effects.

#### Monad

Being an abstraction over imperative computations, effects can be
provided with a monad interface. There is nothing to be afraid of,
it's not rocket science. We just have five functions: `return/1`,
`fail/1`, `map/2`, and `bind/2`, `or_else/2` in `Effect` module.

`Effect.return/1` takes a pure value (e.g. a number) and returns
an effect. On its own this function isn't of any use, but it becomes
pretty usefull in combination with others.

`Effect.map/2` takes an effect and a function that maps
resulting value into another value, and returns an effect.

```elixir
iex(1)> import Effect, only: [return: 1, map: 2]
iex(2)> return(1) |> map(fn x -> x + 1 end) |> Effect.execute()
{:ok, 2}
```

`Effect.bind/2` allows real composition. It takes an effect and a
function that maps the returning value of the original effect into a
new effect.

```elixir
iex(1)> import Effect, only: [return: 1, bind: 2]
iex(2)> return(1) |> bind(fn x -> return(x + 1) end) |> Effect.execute()
{:ok, 2}
```

With the `bind/2` function you can compose effects into a sequence,
create conditional switching, and run effects in a loop.

`Effect.fail/1` allows you to stop computations and return an error.

```elixir
iex(1)> import Effect.Monad, only: [return: 1, bind: 2]
iex(2)> alias Effect.Fail
iex(3)> return(1)
...(3)> |> bind(fn _ -> Fail.new("something went wrong") end)
...(3)> |> Effect.execute()
{:error, "something went wrong"}
```

`Effect.or_else/2` allows you to catch an error and return an effect
(it may be another error or a successfull one).

#### Pipe

We understand that monads, being pretty nice abstraction that allows
you to do cool things, aren't really convinient for expressing your
logic in an understandable way. So we have another, for some more
familiar, way to compose effects: `Effect.Pipe`.

Its interface is similar to
[`Ecto.Multi`](https://hexdocs.pm/ecto/Ecto.Multi.html) or
[`Sage`](https://hexdocs.pm/sage), but it just composes effects,
nothing more. (Still, the database and other transactions may be
implemented as an effect that wraps actions; see
[effect_ecto](https://github.com/yunmikun2/effect_ecto) for details).

```elixir
iex(1)> import Effect.Monad, only: [return: 1]
iex(2)> alias Effect.Pipe
iex(3)> Pipe.new()
...(3)> |> Pipe.then(:x, fn _ -> return(1) end)
...(3)> |> Pipe.then(:y, fn %{x: x} -> return(x + 1) end)
...(3)> |> Effect.execute()
{:ok, %{x: 1, y: 2}}
```

As you can see, it's similar to `Effect.bind/2`, but it tags
results and collects them into a map that's returned after
execution. In case the pipeline fails, you get the name of a step it
failed at.

```elixir
iex(1)> import Effect.Monad, only: [fail: 1, return: 1]
iex(2)> alias Effect.Pipe
iex(3)> Pipe.new()
...(3)> |> Pipe.then(:x, fn _ -> return(1) end)
...(3)> |> Pipe.then(:y, fn %{x: x} -> fail("oops") end)
...(3)> |> Effect.execute()
{:error, %{y: "oops"}}
```

## Installation

```elixir
def deps do
  [
    {:effect, git: "https://github.com/yunmikun2/effect"}
  ]
end
```

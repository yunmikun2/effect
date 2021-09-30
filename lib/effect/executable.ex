defprotocol Effect.Executable do
  @moduledoc ~S"""
  Provides a way to execute an effect.

  Suppose you define an effect.

      defmodule MyApp.Log do
        defstruct [:msg]
      end

  Then we find a way to use it.

      defmodule MyApp.LogAction do
        def info(text) do
          msg = "INFO: #{text}"
          MyApp.Log{msg: msg}
        end
      end

  Now we define an implementation.

      defimpl Effect.Executable, for: MyApp.LogAction do
        def execute(%{msg: msg}) do
          IO.puts(msg)
          {:ok, :ok} # Note: We need to return ok-tuple.
        end
      end

  And you can execute this effect when calling it.

      defmodule MyAppWeb.LogController do
        # ...

        def create(conn, %{"msg" => msg}) do
          msg |> MyApp.LogAction.perform() |> Effect.execute()
          send_resp(conn, 200, "ok")
        end
      end

  And also you can test that the message that's going to be logged is
  the one you expect. And no side-effects!

      defmodule MyApp.LogActionTest do
        # ...

        test "appends INFO prefix to the message" do
          assert LogAction.perform("some text").msg == "INFO: some text"
        end
      end

  For effects composition you better look at functions in `Effect` and
  `Effect.Pipe`.

  When your effect need to wrap another effect, `Effect.Interpretable`
  will be of use.
  """

  @doc """
  Function that turns your effect data structure into a side-effect,
  i.e. executes it.
  """
  @spec execute(t) :: {:ok, term} | {:error, term}
  def execute(effect)
end

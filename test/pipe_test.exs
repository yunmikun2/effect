defmodule PipeTest do
  use ExUnit.Case
  doctest Pipe

  describe "then/3" do
    test "executes an effect returned from a function" do
      assert {:ok, %{x: 1}} =
               Pipe.new()
               |> Pipe.then(:x, fn _ -> Pipe.Pure.new(1) end)
               |> Pipe.execute()
    end

    test "raises a Protocol.UndefinedError if returned value doesn't implement Pipe.Effect" do
      assert_raise Protocol.UndefinedError, fn ->
        Pipe.new()
        |> Pipe.then(:x, fn _ -> {:ok, 1} end)
        |> Pipe.execute()
      end
    end

    test "raises an ArgumentError when using already used key" do
      assert_raise ArgumentError, fn ->
        Pipe.new()
        |> Pipe.then(:x, fn _ -> Pipe.Pure.new(1) end)
        |> Pipe.then(:x, fn _ -> Pipe.Pure.new(1) end)
        |> Pipe.execute()
      end
    end
  end

  describe "switch/2" do
    test "preserves results from both a first Pipe and an inner one" do
      assert {:ok, %{x: 1, y: 2}} =
               Pipe.new()
               |> Pipe.then(:x, fn _ -> Pipe.Pure.new(1) end)
               |> Pipe.switch(fn _ -> Pipe.return(:y, 2) end)
               |> Pipe.execute()
    end

    test "raises an ArgumentError if returned value isn't a Pipe" do
      assert_raise ArgumentError, fn ->
        Pipe.new()
        |> Pipe.switch(fn _ -> Pipe.Pure.new(1) end)
        |> Pipe.execute()
      end
    end

    test "raises an ArgumentError when using return/2 with already used key" do
      assert_raise ArgumentError, fn ->
        Pipe.new()
        |> Pipe.then(:x, fn _ -> Pipe.Pure.new(1) end)
        |> Pipe.switch(fn _ -> Pipe.return(:x, 1) end)
        |> Pipe.execute()
      end
    end
  end
end

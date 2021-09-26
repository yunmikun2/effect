defmodule Pipe.Error do
  @moduledoc """
  Represents an error returned from `Pipe.execute/1`.
  """

  defstruct errors: %{}, results: %{}

  @type t :: %__MODULE__{
          errors: %{required(atom) => term},
          results: %{required(atom) => term}
        }
end

defmodule Exsoda.User do
  alias Exsoda.Http

  defmodule Current do
    defstruct opts: []
  end

  def current(opts \\ []), do: %Current{opts: Http.options(opts)}
  def run(%Current{} = q), do: Http.get("/users/current", q)
end

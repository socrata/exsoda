defmodule Exsoda.User do
  alias Exsoda.Http

  defmodule Current do
    defstruct opts: []
  end

  defmodule ById do
    defstruct id: "", opts: []
  end

  def current(opts \\ []), do: %Current{opts: Http.options(opts)}
  def by_id(id, opts \\ []), do: %ById{id: id, opts: Http.options(opts)}

  def run(%Current{} = q), do: Http.get("/users/current", q)
  def run(%ById{id: id} = q), do: Http.get("/users/#{Http.encode(id)}", q)
end

defmodule Exsoda.Domain do
  alias Exsoda.Http

  defmodule Current do
    defstruct opts: []
  end

  defmodule ById do
    defstruct id: 0, opts: []
  end

  defmodule ByName do
    defstruct name: "", opts: []
  end

  defmodule Licenses do
    defstruct opts: []
  end

  def current(opts \\ []), do: %Current{opts: Http.options(opts)}

  def by_id(id, opts \\ []) when is_integer(id), do: %ById{id: id, opts: Http.options(opts)}

  def by_name(name, opts \\ []) when is_binary(name), do: %ByName{name: name, opts: Http.options(opts)}

  def licenses(opts \\ []), do: %Licenses{opts: Http.options(opts)}

  def run(%Current{} = q), do: Http.get("/domains", q)
  def run(%ById{id: id} = q), do: Http.get("/domains/#{Http.encode(id)}", q)
  def run(%ByName{name: name} = q), do: Http.get("/domains/#{Http.encode(name)}", q)
  def run(%Licenses{} = q), do: Http.get("/licenses", q)

end

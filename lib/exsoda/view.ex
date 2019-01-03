defmodule Exsoda.View do
  alias Exsoda.Http
  
  defstruct fourfour: nil,
    name: nil

  defmodule ByFourFour do
    defstruct fourfour: "", opts: []
  end

  def by_fourfour(fourfour, opts \\ []), do: %ByFourFour{fourfour: fourfour, opts: Http.options(opts)}

  def run(%ByFourFour{fourfour: fourfour} = q), do: Http.get("/views/#{Http.encode(fourfour)}", q)
end

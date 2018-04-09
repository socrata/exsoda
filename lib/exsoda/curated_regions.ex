defmodule Exsoda.CuratedRegions do
  alias Exsoda.Http

  defmodule Get do
    defstruct default_only: false,
      enabled_only: true,
      opts: []
  end

  def get_curated_regions(opts \\ []), do: %Get{opts: Http.options(opts)}

  defp camelized_get_config(:default_only), do: "defaultOnly"
  defp camelized_get_config(:enabled_only), do: "enabledOnly"

  def run(%Get{} = r) do
    query_str = r
    |> Map.from_struct
    |> Map.delete(:opts)
    |> Enum.map(fn {k, v} -> {camelized_get_config(k), v} end)
    |> URI.encode_query
    Http.get("/curated_regions?#{query_str}", r)
  end
end

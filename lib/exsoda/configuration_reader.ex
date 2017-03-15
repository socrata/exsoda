defmodule Exsoda.ConfigurationReader do
  alias Exsoda.Http
  alias Exsoda.Configuration

  defmodule GetConfig do
    defstruct type: nil,
      default_only: false,
      merge: false
  end

  defp camelized_get_config(:type), do: "type"
  defp camelized_get_config(:default_only), do: "defaultOnly"
  defp camelized_get_config(:merge), do: "merge"

  defmodule Query do
    defstruct opts: %{},
      operations: []
  end

  def query(opts \\ []) do
    %Query{
      opts: Http.options(opts),
    }
  end

  def get_config(%Query{} = r, type, %GetConfig{} = defaults \\ %GetConfig{}) do
    operation = %{defaults | type: type}
    %{r | operations: [operation | r.operations]}
  end

  def run(%Query{} = r) do
    # Should we use /batches
    # ..nah that's just evil
    Enum.reduce_while(Enum.reverse(r.operations), [], fn (op, acc) ->
      case do_run(op, r) do
        {:error, _} = err -> {:halt, [err | acc]}
        {:ok, _} = ok -> {:cont, [ok | acc]}
      end
    end) |> Enum.reverse
  end

  defp do_run(%GetConfig{} = fc, r) do
    query_str = fc
    |> Map.from_struct
    |> Enum.map(fn {k, v} -> {camelized_get_config(k), v} end)
    |> URI.encode_query
    get("/configurations?#{query_str}", r,
      as: [%Configuration{properties: [%Configuration.Property{}]}])
  end

  defp get(path, r, json_opts) do
    with {:ok, base} <- Http.base_url(r),
         {:ok, options} <- Http.opts(r) do
      HTTPoison.get(
        "#{base}#{path}",
        Http.headers(r),
        options
      ) |> Http.as_json(json_opts)
    end
  end
end

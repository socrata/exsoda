defmodule Exsoda.ConfigurationReader do
  alias Exsoda.Http
  alias Exsoda.Configuration

  defmodule GetConfig do
    defstruct type: nil,
      default_only: nil,
      merge: nil
  end

  defmodule Query do
    defstruct opts: %{},
      operations: []
  end

  def query(opts \\ []) do
    %Query{
      opts: Http.options(opts),
    }
  end

  def get_config_defaults, do: %GetConfig{default_only: false, merge: false}

  def get_config(%Query{} = r, type, %GetConfig{}=defaults \\ get_config_defaults) do
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
    # The !!s normalize a truthy value to boolean
    # it doesn't look like there's an easy way to do a form GET in httpoison..?
    get("/configurations?type=#{URI.encode(fc.type)}&defaultOnly=#{!!fc.default_only}&merge=#{!!fc.merge}", r,
      as: [%Configuration{properties: [%Configuration.Property{}]}])
  end

  defp get(path, r, json_opts) do
    with {:ok, base} <- Http.base_url(r) do
      HTTPoison.get(
        "#{base}#{path}",
        Http.headers(r),
        Http.opts(r)
      ) |> Http.as_json(json_opts)
    end
  end
end

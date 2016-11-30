defmodule Exsoda.Writer do
  alias Exsoda.{Http, View}

  defmodule CreateColumn do
    defstruct name: nil,
    fieldName: nil,
    type: nil,
    description: nil
  end

  defmodule CreateView do
    defstruct name: nil,
    properties: %{}
  end

  defmodule Write do
    defstruct domain: nil,
      host: nil,
      account: nil,
      password: nil,
      operations: []
  end

  def write(options \\ []) do
    %Write{
      domain:   Http.conf_fallback(options, :domain),
      account:  Http.conf_fallback(options, :account),
      password: Http.conf_fallback(options, :password),
      host:     Http.conf_fallback(options, :host)
    }
  end

  def create(%Write{} = w, name, data) do
    operation = %CreateView{name: name, properties: data}
    %{ w | operations: [operation | w.operations] }
  end

  defp do_run(%CreateView{} = cv, w) do
    data = Map.merge(cv.properties, %{name: cv.name})
    with {:ok, json} <- Poison.encode(data),
      {:ok, base} <- Http.base_url(w) do
      HTTPoison.post(
        "#{base}/views.json",
        json,
        Http.headers(w),
        Http.opts(w)
      ) |> Http.as_json
    end
  end

  def run(%Write{} = w) do
    Enum.reduce_while(w.operations, [], fn op, acc ->
        case do_run(op, w) do
          {:error, _} = err -> {:halt, [err | acc]}
          {:ok, _} = ok     -> {:cont, [ok  | acc]}
        end
    end)
    |> Enum.reverse
  end

  # def update(%Write{}) do
  #   {:error, "Cannot update view with nil fourfour"}
  # end
  # def update(%Write{fourfour: fourfour} = w) do
  #   with {:ok, json} <- Poison.encode(w.view),
  #     {:ok, base} <- Http.base_url(w) do
  #     HTTPoison.put(
  #       "#{base}/views/#{fourfour}.json",
  #       json,
  #       Http.headers(w),
  #       Http.opts(w)
  #     ) |> Http.as_json
  #   end
  # end
end

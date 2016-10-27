defmodule Exsoda.Writer do
  alias Exsoda.{Http, View}

  defmodule Write do
    defstruct fourfour: nil,
      domain: nil,
      account: nil,
      password: nil,
      host: nil,
      view: %View{}
  end

  def create(%Write{domain: domain} = w) do
    with {:ok, json} <- Poison.encode(w.view),
      {:ok, base} <- Http.base_url(w) do
      HTTPoison.post(
        "#{base}/views.json",
        json,
        Http.headers(w),
        Http.opts(w)
      ) |> Http.as_json
    end
  end

  def create(view, options \\ []) do
    create(%Write{
      domain:   Http.conf_fallback(options, :domain),
      account:  Http.conf_fallback(options, :account),
      password: Http.conf_fallback(options, :password),
      host:     Http.conf_fallback(options, :host),

      view: view
    })
  end

  def update(%Write{fourfour: nil}) do
    {:error, "Cannot update view with nil fourfour"}
  end
  def update(%Write{domain: domain, fourfour: fourfour} = w) do
    with {:ok, json} <- Poison.encode(w.view),
      {:ok, base} <- Http.base_url(w) do
      HTTPoison.put(
        "#{base}/views/#{fourfour}.json",
        json,
        Http.headers(w),
        Http.opts(w)
      ) |> Http.as_json
    end
  end

end
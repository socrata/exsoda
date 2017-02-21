defmodule Exsoda.Http do
  alias HTTPoison.Response
  alias Exsoda.Config

  def conf_fallback(options, key) do
    Keyword.get(options, key, Config.get(:exsoda, key))
  end

  def make_url(url) do
    proto = Config.get(:exsoda, :protocol, "https")
    api_root = Config.get(:exsoda, :api_root, "/api")
    "#{proto}://#{url}#{api_root}"
  end


  def base_url(%{opts: %{host: {:system, env_var, default}}}) do
    host_str = System.get_env(env_var) || default
    {:ok, make_url(host_str)}
  end
  def base_url(%{opts: %{host: host}}) when is_function(host, 0) do
    with {:ok, host_str} <- host.() do
      {:ok, make_url(host_str)}
    end
  end
  def base_url(%{opts: %{host: host}}) do
    {:ok, make_url(host)}
  end
  def base_url(%{opts: %{domain: domain}}) do
    {:ok, make_url(domain)}
  end


  def headers(%{opts: %{domain: domain}}) do
    [
      {"Content-Type", "application/json"},
      {"X-Socrata-Host", domain}
    ]
  end


  defp hackney_opts(%{cookie: cookie}) do
    [{:cookie, cookie} | Config.get(:exsoda, :hackney_opts, [])]
  end
  defp hackney_opts(%{account: account, password: password}) do
    [{:basic_auth, {account, password}} | Config.get(:exsoda, :hackney_opts, [])]
  end
  defp hackney_opts(_), do: Config.get(:exsoda, :hackney_opts, [])


  def opts(%{opts: options}) do
    [
      hackney: hackney_opts(options),
      timeout: options.timeout,
      recv_timeout: options.recv_timeout
    ]
  end

  defp add_opt(opts, user_opts, key, default) do
    case conf_fallback(user_opts, key) do
      nil -> Map.put(opts, key, default)
      value -> Map.put(opts, key, value)
    end
  end

  defp add_opt(opts, user_opts, key) do
    case conf_fallback(user_opts, key) do
      nil -> opts
      value -> Map.put(opts, key, value)
    end
  end

  def options(user_opts) do
    %{}
    |> add_opt(user_opts, :domain)
    |> add_opt(user_opts, :account)
    |> add_opt(user_opts, :password)
    |> add_opt(user_opts, :host)
    |> add_opt(user_opts, :cookie)
    |> add_opt(user_opts, :recv_timeout, 5_000)
    |> add_opt(user_opts, :timeout, 5_000)
  end

  def as_json(result, json_opts \\ [])

  def as_json({:ok, %Response{body: body, status_code: status}}, json_opts) when (status >= 200) and (status < 300)  do
    Poison.decode(body, json_opts)
  end

  def as_json({:ok, bad_status}, _json_opts) do
    {:error, bad_status}
  end

  def as_json(error, _json_opts), do: error

  def get(path, op) do
    with {:ok, base} <- base_url(op) do
      HTTPoison.get(
        "#{base}#{path}",
        headers(op),
        opts(op)
      )
      |> as_json
    end
  end

  def post(path, op, body) do
    with {:ok, base} <- base_url(op) do
      HTTPoison.post(
        "#{base}#{path}",
        body,
        headers(op),
        opts(op)
      )
      |> as_json
    end
  end

  def put(path, op, body) do
    with {:ok, base} <- base_url(op) do
      HTTPoison.put(
        "#{base}#{path}",
        body,
        headers(op),
        opts(op)
      )
      |> as_json
    end
  end

end

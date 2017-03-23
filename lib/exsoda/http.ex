defmodule Exsoda.Http do
  alias HTTPoison.Response
  alias Exsoda.Config
  require Logger

  def conf_fallback(options, key) do
    Keyword.get(options, key, Config.get(:exsoda, key))
  end

  defp make_url(url, api_root, proto) do
    "#{proto}://#{url}#{api_root}"
  end

  def base_url(%{opts: %{
      host: {:system, env_var, default},
      api_root: api_root,
      protocol: protocol
    }}) do

    host_str = System.get_env(env_var) || default
    {:ok, make_url(host_str, api_root, protocol)}
  end
  def base_url(%{opts: %{
      host: host,
      api_root: api_root,
      protocol: protocol
    }}) when is_function(host, 0) do
    with {:ok, host_str} <- host.() do
      {:ok, make_url(host_str, api_root, protocol)}
    end
  end
  def base_url(%{opts: %{host: host, api_root: api_root, protocol: protocol}}) do
    {:ok, make_url(host, api_root, protocol)}
  end
  def base_url(%{opts: %{domain: domain, api_root: api_root, protocol: protocol}}) do
    {:ok, make_url(domain, api_root, protocol)}
  end

  def headers(%{opts: %{domain: domain, user_agent: user_agent, request_id: request_id}}) do
    [
      {"User-Agent", user_agent},
      {"Content-Type", "application/json"},
      {"X-Socrata-Host", domain},
      {"X-Socrata-RequestId", request_id}
    ]
  end

  defp get_cookie(%{
    spoof: %{
      spoofee_email: spoofee_email,
      spoofer_email: spoofer_email,
      spoofer_password: spoofer_password
    },
    host: _host,
    domain: domain,
    request_id: request_id} = opts) do
    body = [{"username", "#{spoofee_email} #{spoofer_email}"}, {"password", "#{spoofer_password}"}]
    headers = [
      {"X-Socrata-Host", domain},
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"X-Socrata-RequestId", request_id}
    ]

    Logger.info("Authenticating with request id: #{request_id}")
    with {:ok, base} <- base_url(%{opts: opts}),
         auth_path <- "#{base}/authenticate",
         {:ok, %HTTPoison.Response{status_code: 200} = response} <- HTTPoison.post(auth_path, {:form, body}, headers) do

      Enum.find_value(response.headers, {:error, "There was no 'Set-Cookie' header in the authentication response."}, fn
        {"Set-Cookie", v} -> {:ok, v}
        _ -> false
      end)
    else
      {:ok, %HTTPoison.Response{} = non_200_resp} -> {:error, non_200_resp}
      other -> other
    end
  end

  defp hackney_opts(%{cookie: cookie}) do
    {:ok, [{:cookie, cookie} | Config.get(:exsoda, :hackney_opts, [])]}
  end
  defp hackney_opts(%{
    spoof: _spoof,
    host: _host,
  } = opts) do
    with {:ok, cookie} <- get_cookie(opts) do
      hackney_opts(%{cookie: cookie})
    end
  end
  defp hackney_opts(%{account: account, password: password}) do
    {:ok, [{:basic_auth, {account, password}} | Config.get(:exsoda, :hackney_opts, [])]}
  end
  defp hackney_opts(_), do: {:ok, Config.get(:exsoda, :hackney_opts, [])}

  def http_opts(%{opts: options}) do
    with {:ok, h_opts} <- hackney_opts(options) do
      {:ok,
      [
        hackney: h_opts,
        timeout: options.timeout,
        recv_timeout: options.recv_timeout
      ]
      }
    end
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

  @alphabet String.split("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "")
  @numbers String.split("0123456789", "")
  @valid (@alphabet ++ @numbers ++ Enum.map(@alphabet, &String.downcase/1))

  defp random_request_id(len \\ 32) do
    1..len
    |> Enum.map(fn _ -> Enum.random(@valid) end)
    |> Enum.join("")
  end

  def options(user_opts) do
    %{}
    |> add_opt(user_opts, :spoof)
    |> add_opt(user_opts, :domain)
    |> add_opt(user_opts, :account)
    |> add_opt(user_opts, :password)
    |> add_opt(user_opts, :host)
    |> add_opt(user_opts, :cookie)
    |> add_opt(user_opts, :user_agent, "exsoda")
    |> add_opt(user_opts, :request_id, random_request_id)
    |> add_opt(user_opts, :api_root, "/api")
    |> add_opt(user_opts, :protocol, "https")
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
    with {:ok, base} <- base_url(op),
         {:ok, http_options} <- http_opts(op) do
      Logger.debug("Getting with request_id: #{op.opts.request_id}")
      HTTPoison.get(
        "#{base}#{path}",
        headers(op),
        http_options
      )
      |> as_json
    end
  end

  def post(path, op, body) do
    with {:ok, base} <- base_url(op),
         {:ok, http_options} <- http_opts(op) do
      Logger.debug("Posting with request_id: #{op.opts.request_id}")
      HTTPoison.post(
        "#{base}#{path}",
        body,
        headers(op),
        http_options
      )
      |> as_json
    end
  end

  def put(path, op, body) do
    with {:ok, base} <- base_url(op),
         {:ok, http_options} <- http_opts(op) do
      Logger.debug("Putting with request_id: #{op.opts.request_id}")
      HTTPoison.put(
        "#{base}#{path}",
        body,
        headers(op),
        http_options
      )
      |> as_json
    end
  end

end

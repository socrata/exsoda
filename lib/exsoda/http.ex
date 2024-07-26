defmodule Exsoda.Http do
  alias HTTPoison.Response
  alias Exsoda.Config
  require Logger

  def conf_fallback(options, key) do
    Keyword.get(options, key, Config.get(:exsoda, key))
  end

  def encode(s) do
    URI.encode_www_form(to_string(s))
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
  def base_url(%{opts: %{
      host: {module, func, args},
      api_root: api_root,
      protocol: protocol
    }}) do
    with {:ok, host_str} <- apply(module, func, args) do
      {:ok, make_url(host_str, api_root, protocol)}
    end
  end

  def base_url(%{opts: %{host: host, api_root: api_root, protocol: protocol}}) do
    {:ok, make_url(host, api_root, protocol)}
  end
  def base_url(%{opts: %{domain: domain, api_root: api_root, protocol: protocol}}) do
    {:ok, make_url(domain, api_root, protocol)}
  end

  def headers(%{opts: %{domain: domain, user_agent: user_agent, request_id: request_id} = opts}) do

    headers = [
      {"User-Agent", user_agent},
      {"Content-Type", Map.get(opts, :content_type, "application/json")},
      {"X-Socrata-Host", domain},
      {"X-Socrata-RequestId", request_id}
    ]

    headers = case Map.get(opts, :filename) do
      nil -> headers
      filename -> [ {"X-File-Name", filename} | headers ]
    end

    headers = case Map.get(opts, :app_token) do
      nil -> headers
      app_token -> [ {"X-App-Token", app_token} | headers ]
    end

    headers
  end

  def get_cookie_impl(%{
    spoof: %{
      spoofee_email: spoofee_email,
      spoofer_email: spoofer_email,
      spoofer_password: spoofer_password
    },
    domain: _domain,
    request_id: request_id} = opts) do
    body = [{"username", "#{spoofee_email} #{spoofer_email}"}, {"password", "#{spoofer_password}"}]
    headers = [{"Content-Type", "application/x-www-form-urlencoded"} | headers(%{opts: opts})]

    Logger.info("Authenticating with request id: #{request_id}")
    with {:ok, base} <- base_url(%{opts: opts}),
         auth_path <- "#{base}/authenticate",
         {:ok, h_opts} <- hackney_opts(),
         {:ok, %HTTPoison.Response{status_code: 200} = response} <- HTTPoison.post(auth_path, {:form, body}, headers, [hackney: h_opts]) do

      Enum.find_value(response.headers, {:error, "There was no 'Set-Cookie' header in the authentication response."}, fn
        {"Set-Cookie", v} -> {:ok, v}
        _ -> false
      end)
    else
      {:ok, %HTTPoison.Response{} = non_200_resp} -> {:error, non_200_resp}
      other -> other
    end
  end

  def get_cookie(opts) do
    case Process.whereis(Exsoda.AuthServer) do
      nil -> get_cookie_impl(opts)
      _ -> Exsoda.AuthServer.get_cookie(opts)
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
  defp hackney_opts(), do: {:ok, Config.get(:exsoda, :hackney_opts, [])}

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
    r = case conf_fallback(user_opts, key) do
      nil -> default
      value -> value
    end
    Map.put(opts, key, r)
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
    |> String.downcase
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
    |> add_opt(user_opts, :request_id, random_request_id())
    |> add_opt(user_opts, :api_root, "/api")
    |> add_opt(user_opts, :protocol, "https")
    |> add_opt(user_opts, :app_token, nil)
    |> add_opt(user_opts, :recv_timeout, 5_000)
    |> add_opt(user_opts, :timeout, 5_000)
    |> add_opt(user_opts, :params, Keyword.get(user_opts, :params, []))
  end

  def as_json(result), do: as_json(result, [])

  # Core sometimes gives back empty responses
  def as_json({:ok, %Response{body: "", status_code: status}}, _json_opts) when (status >= 200) and (status < 300)  do
    {:ok, nil}
  end
  # Parse the body as json, return an error if we can't parse it
  def as_json({:ok, %Response{body: body, status_code: status} = resp}, json_opts) when (status >= 200) and (status < 300)  do
    with {:ok, body} <- Poison.decode(body, json_opts) do
      {:ok, %{resp | body: body}}
    end
  end
  # Convert bad statuses to error tuples
  def as_json({:ok, bad_status}, _json_opts), do: {:error, bad_status}
  # Leave connection errors unchanged
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

  def delete(path, op) do
    with {:ok, base} <- base_url(op),
         {:ok, http_options} <- http_opts(op) do
      Logger.debug("Getting with request_id: #{op.opts.request_id}")
      HTTPoison.delete(
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
      http_options_with_params = Keyword.put_new(http_options, :params, op.opts[:params])
      HTTPoison.post(
        "#{base}#{path}",
        body,
        headers(op),
        http_options_with_params
      )
      |> maybe_202(path, op, fn -> post(path, op, body) end)
    end
  end

  defp poll202(path, op, ticket, redo) do
    :timer.sleep(10000) # should this be configurable?

    with {:ok, base} <- base_url(op),
         {:ok, http_options} <- http_opts(op) do
      Logger.debug("Polling a 202 with request_id: #{op.opts.request_id} and ticket #{ticket}")

      if ticket do
        unticketed_url = "#{base}#{path}"
        sep = if String.contains?(unticketed_url, "?") do "&" else "?" end
        url = "#{unticketed_url}#{sep}ticket=#{encode(ticket)}"

        HTTPoison.get(
          url,
          headers(op),
          http_options
        ) |> maybe_202(path, op, redo)
      else
        redo.()
      end

    end
  end

  defp maybe_202({:ok, %Response{body: body, status_code: 202}}, path, op, redo) do
    case Poison.decode(body) do
      {:ok, %{"ticket" => ticket}} ->
        poll202(path, op, ticket, redo)
      {:ok, _} ->
        poll202(path, op, nil, redo)
      other ->
        other
    end
  end
  defp maybe_202(resp, _path, _op, _redo) do
    as_json(resp)
  end

  def put(path, op, body \\ "{}") do
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

  def patch(path, op, body \\ "{}") do
    with {:ok, base} <- base_url(op),
         {:ok, http_options} <- http_opts(op) do
      Logger.debug("Patching with request_id: #{op.opts.request_id}")
      HTTPoison.patch(
        "#{base}#{path}",
        body,
        headers(op),
        http_options
      )
      |> as_json
    end
  end
end

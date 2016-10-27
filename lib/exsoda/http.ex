defmodule Exsoda.Http do
  alias HTTPoison.Response

  def conf_fallback(options, key) do
    Keyword.get(options, key, Application.get_env(:exsoda, key))
  end

  def make_url(url) do
    proto = Application.get_env(:exsoda, :protocol, "https")
    "#{proto}://#{url}/api"
  end

  def base_url(%{host: nil} = opts) do
    {:ok, make_url(Map.get(opts, :domain))}
  end

  def base_url(%{host: host}) when is_function(host, 0) do
    with {:ok, host_str} <- host.() do
      {:ok, make_url(host_str)}
    end
  end

  def base_url(%{host: host}) do
    {:ok, make_url(host)}
  end

  def headers(%{domain: domain}) do
    [
      {"Content-Type", "application/json"},
      {"X-Socrata-Host", domain}
    ]
  end

  defp hackney_opts(account, password) when (is_binary(account) and is_binary(password)) do
    [basic_auth: {account, password}] ++ Application.get_env(:exsoda, :hackney_opts, [])
  end
  defp hackney_opts(_, _), do: Application.get_env(:exsoda, :hackney_opts, [])


  def opts(%{account: account, password: password}) do
    [
      hackney: hackney_opts(account, password),
      timeout: Application.get_env(:exsoda, :timeout, 8000),
      recv_timeout: Application.get_env(:exsoda, :recv_timeout, 5000)
    ]
  end

  def as_json({:ok, %Response{body: body, status_code: status}}) when (status >= 200) and (status < 300)  do
    Poison.decode(body)
  end

  def as_json({:ok, bad_status}) do
    {:error, bad_status}
  end

  def as_json(error), do: error

end
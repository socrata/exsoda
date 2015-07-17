defmodule Exsoda.Reader do
  @operations [:where, :order, :limit, :offset, :group, :q]

  defp to_response(%HTTPotion.Response{status_code: status} = response) do
    case response.body |> Poison.decode do
      {:ok, _} = js when status < 300 -> js
      {:ok, parsed} -> {:error, {status, parsed}}
      {:error, _reason} -> {:error, {status, response.body}}
    end
  end

  defp conf_fallback(options, key) do
    Keyword.get(options, key, Application.get_env(:soda, key))
  end

  def get(resource, soql, options) do
    domain = conf_fallback(options, :domain)
    account = conf_fallback(options, :account)
    password = conf_fallback(options, :password)

    query = URI.encode_query(soql)
    url = "https://#{domain}/api/resource/#{resource}.json?#{query}"

    HTTPotion.get(url, basic_auth: {account, password}) |> to_response
  end

  Enum.each(@operations, fn param -> 
    def unquote(param)(query, column, opts \\ []), do: Enum.into(query, unquote(String.to_atom("#{param}_todict"))(column, opts))
    defp unquote(String.to_atom("#{param}_todict"))(column, []), do: %{unquote("$#{Atom.to_string(param)}") => column}
  end)

  defp order_todict(column, direction: :asc), do: order_todict("#{column} ASC", [])
  defp order_todict(column, direction: :desc), do: order_todict("#{column} DESC", [])

  def select(:all), do: %{}
  def select(columns) do
    %{"$select" => Enum.join(columns, ", ")}
  end

  defmacro read(resource, options \\ [], body) do
    quote do
      soql = unquote(body[:do])
      Exsoda.Reader.get(unquote(resource), soql, unquote(options))
    end
  end
end
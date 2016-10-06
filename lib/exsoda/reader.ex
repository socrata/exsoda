defmodule Exsoda.Reader do
  alias Exsoda.Soql
  alias HTTPoison.{AsyncResponse, Response, AsyncStatus, AsyncHeaders, AsyncChunk, AsyncEnd}
  alias NimbleCSV.RFC4180, as: CSV

  @operations [:where, :order, :limit, :offset, :group, :q]

  defp to_response(%HTTPoison.Response{status_code: status} = response) do
    case response.body |> Poison.decode do
      {:ok, _} = js when status < 300 -> js
      {:ok, parsed} -> {:error, {status, parsed}}
      {:error, _reason} -> {:error, {status, response.body}}
    end
  end

  defp conf_fallback(options, key) do
    Keyword.get(options, key, Application.get_env(:soda, key))
  end

  defp get_columns(domain, resource) do
    result = "https://#{domain}/api/views/#{resource}.json"
    |> HTTPoison.get()

    with {:ok, %Response{body: body}} <- result,
      {:ok, decoded} <- Poison.decode(body) do

      columns = decoded
      |> Map.get("columns", [])
      |> Enum.map(fn column ->
        {column["name"], column["dataTypeName"]}
      end)
      |> Enum.into(%{})

      {:ok, columns}
    end
  end

  def get(resource, soql, options) do
    domain = conf_fallback(options, :domain)
    # account = conf_fallback(options, :account)
    # password = conf_fallback(options, :password)

    with {:ok, columns} <- get_columns(domain, resource) do

      query = URI.encode_query(soql)

      stream = "https://#{domain}/api/resource/#{resource}.csv?#{query}"
      |> IO.inspect
      |> HTTPoison.get(%{}, stream_to: self)
      |> as_stream
      |> CSV.parse_stream(headers: false)
      |> Stream.transform(nil,
        fn
          header, nil ->
            {[], header}
          row, header ->
            converted_row = Enum.zip(header, row)
            |> Enum.map(fn {column_name, datum} ->
              type = Map.get(columns, column_name)
              {column_name, Soql.from_string(type, datum)}
            end)

            {[converted_row], header}
        end
      )

      {:ok, stream}
    end

  end

  defp as_stream({:ok, %AsyncResponse{id: ref}}) do
    Stream.resource(
      fn -> :ok end,
      fn state ->
        receive do
          %AsyncStatus{id: ^ref, code: _}     -> {[], state}
          %AsyncHeaders{id: ^ref, headers: _} -> {[], state}
          %AsyncEnd{id: ^ref}                 -> {:halt, state}
          %AsyncChunk{id: ^ref, chunk: c}     ->
            lines = c
            |> String.split("\n")
            |> Enum.reject(fn
              "" -> true
              _ -> false
            end)
            {lines, state}
        end
      end,
      fn _state -> :ok end
    )
  end

  defp as_stream(failure), do: failure



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
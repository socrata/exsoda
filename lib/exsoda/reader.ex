defmodule Exsoda.Reader do
  alias Exsoda.Soql
  alias HTTPoison.{AsyncResponse, Response, AsyncStatus, AsyncHeaders, AsyncChunk, AsyncEnd}
  alias NimbleCSV.RFC4180, as: CSV
  require Logger

  defmodule Query do
    defstruct fourfour: nil, domain: nil, account: nil, password: nil, query: %{}
  end

  defp conf_fallback(options, key) do
    Keyword.get(options, key, Application.get_env(:exsoda, key))
  end

  defp basic_auth(%Query{account: account, password: password}) do
    if account && password do
      [basic_auth: {account, password}]
    else
      []
    end
  end

  defp view_columns(decoded) do
    columns = decoded
    |> Map.get("columns", [])
    |> Enum.map(fn column ->
      {column["name"], column["dataTypeName"]}
    end)
    |> Enum.into(%{})

    {:ok, columns}
  end

  def get_view(%Query{domain: domain, fourfour: fourfour} = state) do
    hackney_opts = basic_auth(state)
    result =  HTTPoison.get("https://#{domain}/api/views/#{fourfour}.json", %{}, hackney: hackney_opts)
    case result do
      {:ok, %Response{body: body, status_code: 200}} ->
        Poison.decode(body)
      {:ok, non_200} ->
        {:error, non_200}
      error ->
        error
    end
  end

  defp get_columns(query) do
    with {:ok, view} <- get_view(query) do
      view_columns(view)
    end
  end

  def query(fourfour, options \\ []) do
    %Query{
      fourfour: fourfour,
      domain: conf_fallback(options, :domain),
      account: conf_fallback(options, :account),
      password: conf_fallback(options, :password),

      query: %{}
    }
  end

  def run(%Query{} = state) do

    domain = state.domain || Application.get_env(:exsoda, :domain)
    hackney_opts = basic_auth(state)

    with {:ok, columns} <- get_columns(state) do

      query = URI.encode_query(state.query)

      Logger.debug("Exsoda Query #{query} https://#{domain}/api/resource/#{state.fourfour}.csv?#{query}")

      stream = "https://#{domain}/api/resource/#{state.fourfour}.csv?#{query}"
      |> HTTPoison.get(%{}, stream_to: self, hackney: hackney_opts)
      |> as_line_stream
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

  defp as_line_stream({:ok, %AsyncResponse{id: ref}}) do
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

  defp as_line_stream(failure), do: failure

  @operations [:where, :limit, :offset, :group, :q]

  defp put_q(%Query{} = state, name, value) do
    query = Map.put(state.query, name, value)
    struct(state, query: query)
  end

  def order(state, expr , :asc) do
    order(state, expr <> " ASC")
  end
  def order(state, expr , :desc) do
    order(state, expr <> " DESC")
  end
  def order(state, expr) do
    put_q(state, "$order", expr)
  end


  Enum.each(@operations, fn param ->
    def unquote(param)(state, expr) do
      put_q(state, "$" <> Atom.to_string(unquote(param)), expr)
    end
  end)

  def select(state, columns) do
    put_q(state, "$select", Enum.join(columns, ", "))
  end
end
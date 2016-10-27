defmodule Exsoda.Reader do
  alias Exsoda.{Soql, Http}
  alias HTTPoison.{AsyncResponse, AsyncStatus, AsyncHeaders, AsyncChunk, AsyncEnd}
  alias NimbleCSV.RFC4180, as: CSV
  require Logger

  defmodule Query do
    defstruct fourfour: nil, domain: nil, account: nil, password: nil, host: nil, query: %{}
  end

  def query(fourfour, options \\ []) do
    %Query{
      fourfour: fourfour,
      domain: Http.conf_fallback(options, :domain),
      account: Http.conf_fallback(options, :account),
      password: Http.conf_fallback(options, :password),
      host:     Http.conf_fallback(options, :host),

      query: %{}
    }
  end

  defp view_columns(decoded) do
    columns = decoded
    |> Map.get("columns", [])
    |> Enum.map(fn column -> {column["name"], column["dataTypeName"]} end)
    |> Enum.into(%{})

    {:ok, columns}
  end

  def get_view(%Query{fourfour: fourfour} = state) do
    with {:ok, base} <- Http.base_url(state) do
      "#{base}/views/#{fourfour}.json"
      |> HTTPoison.get(%{}, Http.opts(state))
      |> Http.as_json
    end
  end

  defp get_columns(query) do
    with {:ok, view} <- get_view(query) do
      view_columns(view)
    end
  end

  def run(%Query{} = state) do
    domain = state.domain || Application.get_env(:exsoda, :domain)

    with {:ok, columns} <- get_columns(state),
      {:ok, base} <- Http.base_url(state) do

      query = URI.encode_query(state.query)

      Logger.debug("Exsoda Query #{query} https://#{domain}/api/resource/#{state.fourfour}.csv?#{query}")
      stream = "#{base}/resource/#{state.fourfour}.csv?#{query}"
      |> HTTPoison.get(%{}, [{:stream_to, self} | Http.opts(state)])
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
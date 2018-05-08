defmodule Exsoda.Reader do
  alias Exsoda.{Soql, Http}
  alias HTTPoison.{AsyncResponse, AsyncStatus, AsyncHeaders, AsyncChunk, AsyncEnd}
  alias NimbleCSV.RFC4180, as: CSV
  require Logger

  defmodule Query do
    defstruct fourfour: nil,
      opts: [],
      query: %{}
  end

  def query(fourfour, options \\ []) do
    %Query{
      fourfour: fourfour,
      opts: Http.options(options),
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
    with {:ok, base} <- Http.base_url(state),
         {:ok, options} <- Http.http_opts(state) do
      "#{base}/views/#{Http.encode(fourfour)}.json"
      |> HTTPoison.get(Http.headers(state), options)
      |> Http.as_json
    end
  end

  def get_unpublished_copy(%Query{fourfour: fourfour} = state) do
    with {:ok, base} <- Http.base_url(state),
         {:ok, options} <- Http.http_opts(state) do
      "#{base}/views/#{Http.encode(fourfour)}.json?method=getPublicationGroup&stage=unpublished"
      |> HTTPoison.get(Http.headers(state), options)
      |> Http.as_json
    end
  end

  def get_published_copy(%Query{fourfour: fourfour} = state) do
    with {:ok, base} <- Http.base_url(state),
         {:ok, options} <- Http.http_opts(state) do
      "#{base}/views/#{Http.encode(fourfour)}.json?method=getPublicationGroup&stage=published"
      |> HTTPoison.get(Http.headers(state), options)
      |> Http.as_json
    end
  end

  def replication(%Query{fourfour: fourfour} = state) do
    with {:ok, base} <- Http.base_url(state),
         {:ok, options} <- Http.http_opts(state) do
      "#{base}/views/#{Http.encode(fourfour)}/replication.json"
      |> HTTPoison.get(Http.headers(state), options)
      |> Http.as_json
    end
  end

  defp get_columns(query) do
    with {:ok, view} <- get_view(query) do
      view_columns(view)
    end
  end

  def run(%Query{} = state) do
    with {:ok, columns} <- get_columns(state),
         {:ok, base} <- Http.base_url(state),
         {:ok, options} <- Http.http_opts(state) do

      query = URI.encode_query(state.query)

      stream = "#{base}/id/#{Http.encode(state.fourfour)}.csv?#{query}"
      |> HTTPoison.get(Http.headers(state), [{:stream_to, self()} | options])
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

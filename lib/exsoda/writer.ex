defmodule Exsoda.Writer do
  alias Exsoda.Http

  defmodule CreateColumn do
    defstruct name: nil,
    dataTypeName: nil,
    fourfour: nil,
    properties: %{} # description, fieldName
  end

  defmodule CreateView do
    defstruct name: nil,
    properties: %{}
  end

  defmodule UpdateView do
    defstruct fourfour: nil,
    properties: %{}
  end

  defmodule Upsert do
    defstruct fourfour: nil,
    rows: []
  end


  defmodule Write do
    defstruct opts: %{},
      operations: []
  end

  def write(options \\ []) do
    %Write{
      opts: Http.options(options)
    }
  end

  def create(%Write{} = w, name, properties) do
    operation = %CreateView{name: name, properties: properties}
    %{ w | operations: [operation | w.operations] }
  end

  def update(%Write{} = w, fourfour, properties) do
    operation = %UpdateView{fourfour: fourfour, properties: properties}
    %{ w | operations: [operation | w.operations] }
  end

  def create_column(%Write{} = w, fourfour, name, type, properties) do
    operation = %CreateColumn{name: name, dataTypeName: type, fourfour: fourfour, properties: properties}
    %{ w | operations: [operation | w.operations] }
  end

  # a row looks like: {fieldName: value, fieldName: value}
  def upsert(%Write{} = w, fourfour, rows) do
    operation = %Upsert{fourfour: fourfour, rows: rows}
    %{ w | operations: [operation | w.operations] }
  end

  defp do_run(%CreateView{} = cv, w) do
    data = Map.merge(cv.properties, %{name: cv.name})
    with {:ok, json} <- Poison.encode(data) do
      Http.post("/views.json", w, json)
    end
  end

  defp do_run(%UpdateView{} = uv, w) do
    with {:ok, json} <- Poison.encode(uv.properties) do
      Http.put("/views/#{uv.fourfour}.json", w, json)
    end
  end

  defp do_run(%CreateColumn{} = cc, w) do
    data = Map.take(cc, [:dataTypeName, :name])
    |> Map.merge(cc.properties)

    with {:ok, json} <- Poison.encode(data) do
      Http.post("/views/#{cc.fourfour}/columns", w, json)
    end
  end

  defp do_run(%Upsert{rows: rows} = u, w) when is_list(rows) do
    with {:ok, json} <- Poison.encode(rows) do
      Http.post("/id/#{u.fourfour}.json", w, json)
    end
  end
  defp do_run(%Upsert{rows: rows} = u, w) do
    with_commas = Stream.transform(rows, false, fn
      row, false -> {[Poison.encode!(row)], true}
      row, true  -> {[",\n" <> Poison.encode!(row)], true}
    end)

    json_stream = Stream.concat(
      ["["],
      with_commas
    )
    |> Stream.concat(["]"])

    Http.post("/id/#{u.fourfour}.json", w, {:stream, json_stream})
  end

  def run(%Write{} = w) do
    Enum.reduce_while(Enum.reverse(w.operations), [], fn op, acc ->
        case do_run(op, w) do
          {:error, _} = err -> {:halt, [err | acc]}
          {:ok, _} = ok     -> {:cont, [ok  | acc]}
        end
    end)
    |> Enum.reverse
  end

end

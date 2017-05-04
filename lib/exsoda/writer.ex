defmodule Exsoda.Writer do
  alias Exsoda.Http

  @column_create_optimization false

  defmodule CreateColumn do
    defstruct name: nil,
    dataTypeName: nil,
    fourfour: nil,
    properties: %{} # description, fieldName
  end

  defmodule CreateColumns do
    defstruct columns: []
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
    mode: nil,
    rows: []
  end

  defmodule Write do
    defstruct opts: %{},
      operations: []
  end

  defmodule Publish do
    defstruct fourfour: nil
  end

  defmodule Permission do
    defstruct fourfour: nil,
      mode: nil
  end

  defmodule PrepareDraftForImport do
    defstruct fourfour: nil
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
    operation = %Upsert{fourfour: fourfour, rows: rows, mode: :append}
    %{ w | operations: [operation | w.operations] }
  end

  def replace(%Write{} = w, fourfour, rows) do
    operation = %Upsert{fourfour: fourfour, rows: rows, mode: :replace}
    %{ w | operations: [operation | w.operations] }
  end

  def publish(%Write{} = w, fourfour) do
    operation = %Publish{fourfour: fourfour}
    %{ w | operations: [operation | w.operations]}
  end

  def permission(%Write{} = w, fourfour, :public) do
    operation = %Permission{fourfour: fourfour, mode: "public.read"}
    %{ w | operations: [operation | w.operations]}
  end

  def permission(%Write{} = w, fourfour, :private) do
    operation = %Permission{fourfour: fourfour, mode: "private"}
    %{ w | operations: [operation | w.operations]}
  end

  def prepare_draft_for_import(%Write{} = w, fourfour) do
    operation = %PrepareDraftForImport{fourfour: fourfour}
    %{ w | operations: [operation | w.operations]}
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
    data = merge_column(cc)

    with {:ok, json} <- Poison.encode(data) do
      Http.post("/views/#{cc.fourfour}/columns", w, json)
    end
  end

  defp do_run(%CreateColumns{columns: ccs}, w) do
    data = %{"columns" => Enum.map(ccs, &merge_column/1)}

    with {:ok, json} <- Poison.encode(data) do
      case Http.post("/views/#{hd(ccs).fourfour}/columns?method=multiCreate", w, json) do
        {:ok, list} -> Enum.map(list, fn result -> {:ok, result} end)
        {:error, _} = err -> Enum.map(ccs, fn _ -> err end)
      end
    end
  end

  defp do_run(%Upsert{rows: rows} = u, w) when is_list(rows) do
    with {:ok, json} <- Poison.encode(rows) do
      case u.mode do
        :append -> Http.post("/id/#{u.fourfour}.json", w, json)
        :replace -> Http.put("/id/#{u.fourfour}.json", w, json)
      end
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

    case u.mode do
      :append -> Http.post("/id/#{u.fourfour}.json", w, {:stream, json_stream})
      :replace -> Http.put("/id/#{u.fourfour}.json", w, {:stream, json_stream})
    end
  end

  defp do_run(%Publish{fourfour: fourfour}, w) do
    with {:ok, json} <- Poison.encode(%{}) do
      Http.post("/views/#{fourfour}/publication", w, json)
    end
  end

  defp do_run(%Permission{fourfour: fourfour, mode: mode}, w) do
    with {:ok, json} <- Poison.encode(mode) do
      Http.put("/views/#{fourfour}?method=setPermission", w, json)
    end
  end

  defp do_run(%PrepareDraftForImport{fourfour: fourfour}, w) do
    with {:ok, json} <- Poison.encode(%{}) do
      Http.patch("/views/#{fourfour}?method=prepareDraftForImport", w, json)
    end
  end

  defp merge_column(%CreateColumn{} = cc), do: Map.take(cc, [:dataTypeName, :name]) |> Map.merge(cc.properties)

  defp collapse_column_create([]), do: []
  defp collapse_column_create([%CreateColumn{fourfour: fourfour} = cc | ccs]) do
    if @column_create_optimization do
      {ccs, remainder} = Enum.split_while(ccs, fn
        %CreateColumn{fourfour: ^fourfour} -> true
        _ -> false
      end)
      [%CreateColumns{columns: [cc | ccs]} | collapse_column_create(remainder)]
    else
      [cc | ccs]
    end
  end
  defp collapse_column_create([h | t]), do: [h | collapse_column_create(t)]

  def run(%Write{} = w) do
    w.operations
    |> Enum.reverse
    |> collapse_column_create
    |> Enum.reduce_while([], fn op, acc ->
      Enum.reduce_while(List.wrap(do_run(op, w)), {:cont, acc}, fn result, {_, acc} ->
        case result do
          {:error, _} = err -> {:halt, {:halt, [err | acc]}}
          {:ok, _} = ok     -> {:cont, {:cont, [ok  | acc]}}
        end
      end)
    end)
    |> Enum.reverse
  end
end

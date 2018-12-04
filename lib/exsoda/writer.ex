defmodule Exsoda.Writer do
  alias Exsoda.Http

  @column_create_optimization false

  defmodule CreateColumn do
    defstruct name: nil,
    dataTypeName: nil,
    fourfour: nil,
    properties: %{} # description, fieldName
  end

  defmodule UpdateColumn do
    defstruct fieldName: nil,
      fourfour: nil,
      properties: %{} # description, fieldName
  end

  defmodule CreateColumns do
    defstruct columns: []
  end

  defmodule DropColumn do
    defstruct field_name: nil,
    fourfour: nil,
    properties: %{}
  end

  defmodule DropWorkingCopy do
    defstruct fourfour: nil
  end

  defmodule DeleteApprovalsSubmissions do
    defstruct fourfour: nil,
    catalog_revision_id: nil
  end

  defmodule CreateView do
    defstruct name: nil,
    properties: %{}
  end

  defmodule UpdateView do
    defstruct fourfour: nil,
    properties: %{},
    validate_only: nil
  end

  defmodule ValidateView do
    defstruct fourfour: nil,
    properties: %{}
  end

  defmodule Upsert do
    defstruct fourfour: nil,
    mode: nil,
    options: nil,
    rows: []
  end

  defmodule Write do
    defstruct opts: %{},
      operations: []
  end

  defmodule Copy do
    defstruct fourfour: nil,
      copy_data: true
  end

  defmodule Publish do
    defstruct fourfour: nil
  end

  defmodule Permission do
    defstruct fourfour: nil,
      mode: nil
  end

  defmodule Permissions do
    defstruct fourfour: nil,
      blob: nil
  end

  defmodule PrepareDraftForImport do
    defstruct fourfour: nil,
      nbe: nil
  end

  defmodule SetBlobForDraft do
    defstruct fourfour: nil,
    filename: nil,
    file_path: nil,
    byte_stream: nil
  end

  defmodule ReplaceBlob do
    defstruct fourfour: nil,
    filename: nil,
    file_path: nil,
    byte_stream: nil
  end

  defmodule UploadAttachment do
    defstruct [:fourfour, :byte_stream, :filename]
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

  def update(%Write{} = w, fourfour, properties, validate_only \\ false) do
    operation = %UpdateView{fourfour: fourfour, properties: properties, validate_only: validate_only}
    %{ w | operations: [operation | w.operations] }
  end

  def validate(%Write{} = w, fourfour, properties) do
    operation = %ValidateView{fourfour: fourfour, properties: properties}
    %{ w | operations: [operation | w.operations] }
  end

  def create_column(%Write{} = w, fourfour, name, type, properties) do
    operation = %CreateColumn{name: name, dataTypeName: type, fourfour: fourfour, properties: properties}
    %{ w | operations: [operation | w.operations] }
  end

  def update_column(%Write{} = w, fourfour, field_name, properties) do
    operation = %UpdateColumn{fourfour: fourfour, fieldName: field_name, properties: properties}
    %{ w | operations: [operation | w.operations] }
  end

  def drop_column(%Write{} = w, fourfour, field_name, properties) do
    operation = %DropColumn{field_name: field_name, fourfour: fourfour, properties: properties}
    %{ w | operations: [operation | w.operations] }
  end

  def drop_working_copy(%Write{} = w, fourfour) do
    operation = %DropWorkingCopy{fourfour: fourfour}
    %{ w | operations: [operation | w.operations] }
  end

  def delete_approvals_submissions(%Write{} = w, fourfour, revision_id) do
    operation = %DeleteApprovalsSubmissions{fourfour: fourfour, catalog_revision_id: "#{fourfour}:#{revision_id}"}
    %{ w | operations: [operation | w.operations] }
  end

  # a row looks like: {fieldName: value, fieldName: value}
  def upsert(%Write{} = w, fourfour, rows, options \\ nil) do
    operation = %Upsert{fourfour: fourfour, rows: rows, mode: :append, options: options}
    %{ w | operations: [operation | w.operations] }
  end

  def replace(%Write{} = w, fourfour, rows) do
    operation = %Upsert{fourfour: fourfour, rows: rows, mode: :replace}
    %{ w | operations: [operation | w.operations] }
  end

  def copy(%Write{} = w, fourfour, copy_data \\ true) do
    operation = %Copy{fourfour: fourfour, copy_data: copy_data}
    %{ w | operations: [operation | w.operations] }
  end

  def publish(%Write{} = w, fourfour) do
    operation = %Publish{fourfour: fourfour}
    %{ w | operations: [operation | w.operations] }
  end

  def permission(%Write{} = w, fourfour, :public) do
    operation = %Permission{fourfour: fourfour, mode: "public.read"}
    %{ w | operations: [operation | w.operations] }
  end

  def permission(%Write{} = w, fourfour, :private) do
    operation = %Permission{fourfour: fourfour, mode: "private"}
    %{ w | operations: [operation | w.operations] }
  end

  def permissions(%Write{} = w, fourfour, blob) when is_map(blob) do
    operation = %Permissions{fourfour: fourfour, blob: blob}
    %{ w | operations: [operation | w.operations] }
  end

  def prepare_draft_for_import(%Write{} = w, fourfour, nbe \\ false) do
    operation = %PrepareDraftForImport{fourfour: fourfour, nbe: nbe}
    %{ w | operations: [operation | w.operations] }
  end

  def set_blob_for_draft(%Write{} = w, fourfour, file_path) when is_binary(file_path) do
    operation = %SetBlobForDraft{fourfour: fourfour, file_path: file_path}
    %{ w | operations: [operation | w.operations] }
  end
  def set_blob_for_draft(%Write{} = w, fourfour, byte_stream, filename) when is_map(byte_stream) do
    operation = %SetBlobForDraft{fourfour: fourfour, byte_stream: byte_stream, filename: filename}
    %{ w | operations: [operation | w.operations] }
  end

  def replace_blob(%Write{} = w, fourfour, file_path) when is_binary(file_path) do
    operation = %ReplaceBlob{fourfour: fourfour, file_path: file_path}
    %{ w | operations: [operation | w.operations] }
  end
  def replace_blob(%Write{} = w, fourfour, byte_stream, filename) when is_map(byte_stream) do
    operation = %ReplaceBlob{fourfour: fourfour, byte_stream: byte_stream, filename: filename}
    %{ w | operations: [operation | w.operations] }
  end

  def upload_attachment(%Write{} = w, fourfour, byte_stream, filename) do
    operation = %UploadAttachment{fourfour: fourfour, byte_stream: byte_stream, filename: filename}
    %{w | operations: [operation | w.operations]}
  end

  defp do_run(%CreateView{} = cv, w) do
    data = Map.merge(cv.properties, %{name: cv.name})
    with {:ok, json} <- Poison.encode(data) do
      Http.post("/views.json", w, json)
    end
  end

  defp do_run(%UpdateView{validate_only: nil} = uv, w) do
    with {:ok, json} <- Poison.encode(uv.properties) do
      Http.put("/views/#{Http.encode(uv.fourfour)}.json", w, json)
    end
  end
  defp do_run(%UpdateView{validate_only: validate_only} = uv, w) do
    with {:ok, json} <- Poison.encode(uv.properties) do
      Http.put("/views/#{Http.encode(uv.fourfour)}.json?validateOnly=#{Http.encode(validate_only)}", w, json)
    end
  end

  defp do_run(%ValidateView{} = uv, w) do
    with {:ok, json} <- Poison.encode(uv.properties) do
      Http.put("/views/#{Http.encode(uv.fourfour)}.json?method=validate", w, json)
    end
  end

  defp do_run(%CreateColumn{} = cc, w) do
    data = merge_column(cc)

    with {:ok, json} <- Poison.encode(data) do
      Http.post("/views/#{Http.encode(cc.fourfour)}/columns", w, json)
    end
  end

  defp do_run(%CreateColumns{columns: ccs}, w) do
    data = %{"columns" => Enum.map(ccs, &merge_column/1)}

    with {:ok, json} <- Poison.encode(data) do
      case Http.post("/views/#{Http.encode(hd(ccs).fourfour)}/columns?method=multiCreate", w, json) do
        {:ok, list} -> Enum.map(list, fn result -> {:ok, result} end)
        {:error, _} = err -> Enum.map(ccs, fn _ -> err end)
      end
    end
  end

  defp do_run(%UpdateColumn{} = cc, w) do
    with {:ok, json} <- Poison.encode(cc.properties) do
      Http.put("/views/#{Http.encode(cc.fourfour)}/columns/#{Http.encode(cc.fieldName)}", w, json)
    end
  end

  defp do_run(%DropColumn{} = dc, w) do
    Http.delete("/views/#{Http.encode(dc.fourfour)}/columns/#{Http.encode(dc.field_name)}", w)
  end

  defp do_run(%DropWorkingCopy{fourfour: fourfour}, w) do
    Http.delete("/views/#{Http.encode(fourfour)}", w)
  end

  defp do_run(%DeleteApprovalsSubmissions{} = das, w) do
    Http.delete("/views/#{Http.encode(das.fourfour)}/approvals/#{Http.encode(das.catalog_revision_id)}?method=deleteExternalAssetSubmissions", w)
  end

  defp do_run(%Upsert{rows: rows} = u, w) when is_list(rows) do
    url = case u.options do
      %{} = params ->
        "/id/#{Http.encode(u.fourfour)}.json?" <> Plug.Conn.Query.encode(params)
      _ ->
        "/id/#{Http.encode(u.fourfour)}.json"
    end

    with {:ok, json} <- Poison.encode(rows) do
      case u.mode do
        :append -> Http.post(url, w, json)
        :replace -> Http.put(url, w, json)
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

    url = case u.options do
      %{} = params ->
        "/id/#{Http.encode(u.fourfour)}.json?" <> Plug.Conn.Query.encode(params)
      _ ->
        "/id/#{Http.encode(u.fourfour)}.json"
    end

    case u.mode do
      :append -> Http.post(url, w, {:stream, json_stream})
      :replace -> Http.put(url, w, {:stream, json_stream})
    end
  end

  defp do_run(%Copy{fourfour: fourfour, copy_data: copy_data}, w) do
    with {:ok, json} <- Poison.encode(%{}) do
      url =
        if copy_data do
          "/views/#{Http.encode(fourfour)}/publication?method=copy"
        else
          "/views/#{Http.encode(fourfour)}/publication?method=copySchema"
        end
      Http.post(url, w, json)
    end
  end


  defp do_run(%Publish{fourfour: fourfour}, w) do
    with {:ok, json} <- Poison.encode(%{}) do
      Http.post("/views/#{Http.encode(fourfour)}/publication", w, json)
    end
  end

  defp do_run(%Permission{fourfour: fourfour, mode: mode}, w) do
    with {:ok, json} <- Poison.encode(mode) do
      Http.put("/views/#{Http.encode(fourfour)}?method=setPermission", w, json)
    end
  end

  defp do_run(%Permissions{fourfour: fourfour, blob: blob}, w) do
    with {:ok, json} <- Poison.encode(blob) do
      Http.put("/views/#{fourfour}/permissions", w, json)
    end
  end

  defp do_run(%PrepareDraftForImport{fourfour: fourfour, nbe: nil}, w) do
    with {:ok, json} <- Poison.encode(%{}) do
      Http.patch("/views/#{Http.encode(fourfour)}?method=prepareDraftForImport", w, json)
    end
  end
  defp do_run(%PrepareDraftForImport{fourfour: fourfour, nbe: nbe}, w) do
    with {:ok, json} <- Poison.encode(%{}) do
      Http.patch("/views/#{Http.encode(fourfour)}?method=prepareDraftForImport&nbe=#{Http.encode(nbe)}", w, json)
    end
  end

  defp do_run(%SetBlobForDraft{fourfour: fourfour, byte_stream: byte_stream, filename: filename}, w) do
    body = {:stream, byte_stream}
    headers = %{content_type: "application/octet-stream", filename: filename}
    ops = %{opts: Map.merge(w.opts, headers)}
    url = "/imports2?method=setBlobForDraft&saveUnderViewUid=#{Http.encode(fourfour)}"
    Http.post(url, ops, body)
  end
  defp do_run(%SetBlobForDraft{fourfour: fourfour, file_path: file_path}, w) do
    body = {:multipart, [file: file_path]}
    url = "/imports2?method=setBlobForDraft&saveUnderViewUid=#{Http.encode(fourfour)}"
    Http.post(url, w, body)
  end

  defp do_run(%ReplaceBlob{fourfour: fourfour, byte_stream: byte_stream, filename: filename}, w) do
    body = {:stream, byte_stream}
    headers = %{content_type: "application/octet-stream", filename: filename}
    ops = %{opts: Map.merge(w.opts, headers)}
    url = "/views/#{Http.encode(fourfour)}?method=replaceBlob"
    Http.post(url, ops, body)
  end
  defp do_run(%ReplaceBlob{fourfour: fourfour, file_path: file_path}, w) do
    body = {:multipart, [file: file_path]}
    url = "/views/#{Http.encode(fourfour)}?method=replaceBlob"
    Http.post(url, w, body)
  end

  defp do_run(%UploadAttachment{fourfour: fourfour, byte_stream: byte_stream, filename: filename}, w) do
    body = {:stream, byte_stream}
    headers = %{content_type: "application/octet-stream", filename: filename}
    ops = %{opts: Map.merge(w.opts, headers)}
    url = "/views/#{Http.encode(fourfour)}/files.txt"
    Http.post(url, ops, body)
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

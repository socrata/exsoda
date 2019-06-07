defmodule Exsoda.Writer do
  alias Exsoda.Http
  alias Exsoda.Runner
  alias Exsoda.Runner.{Operations, Execute}
  import Exsoda.Runner, only: [prepend: 2]


  defmodule CreateColumn do
    defstruct name: nil, dataTypeName: nil, fourfour: nil, properties: %{} # description, fieldName

    defimpl Execute, for: __MODULE__ do
      import Exsoda.Util.Column, only: [merge_column: 1]

      def run(cc, o) do
        with {:ok, json} <- Poison.encode(merge_column(cc)) do
          Http.post("/views/#{Http.encode(cc.fourfour)}/columns", o, json)
        end
      end
    end
  end

  defmodule UpdateColumn do
    defstruct fieldName: nil, fourfour: nil, properties: %{} # description, fieldName

    defimpl Execute, for: __MODULE__ do
      def run(uc, o) do
        with {:ok, json} <- Poison.encode(uc.properties) do
          Http.put("/views/#{Http.encode(uc.fourfour)}/columns/#{Http.encode(uc.fieldName)}", o, json)
        end
      end
    end
  end

  defmodule CreateColumns do
    defstruct columns: []

    defimpl Execute, for: __MODULE__ do
      import Exsoda.Util.Column, only: [merge_column: 1]
      def run(ccs, o) do

        data = %{"columns" => Enum.map(ccs, &merge_column/1)}

        with {:ok, json} <- Poison.encode(data) do
          case Http.post("/views/#{Http.encode(hd(ccs).fourfour)}/columns?method=multiCreate", o, json) do
            {:ok, list} -> Enum.map(list, fn result -> {:ok, result} end)
            {:error, _} = err -> Enum.map(ccs, fn _ -> err end)
          end
        end
      end
    end
  end

  defmodule DropColumn do
    defstruct field_name: nil, fourfour: nil, properties: %{}

    defimpl Execute, for: __MODULE__ do
      def run(dc, o) do
        Http.delete("/views/#{Http.encode(dc.fourfour)}/columns/#{Http.encode(dc.field_name)}", o)
      end
    end
  end

  defmodule DropView do
    defstruct fourfour: nil

    defimpl Execute, for: __MODULE__ do
      def run(dv, o) do
        Http.delete("/views/#{Http.encode(dv.fourfour)}", o)
      end
    end
  end

  defmodule DropWorkingCopy do
    defstruct fourfour: nil

    defimpl Execute, for: __MODULE__ do
      def run(dc, o) do
        Http.delete("/views/#{Http.encode(dc.fourfour)}", o)
      end
    end
  end

  defmodule CreateView do
    defstruct name: nil, properties: %{}

    defimpl Execute, for: __MODULE__ do
      def run(cv, o) do
        data = Map.merge(cv.properties, %{name: cv.name})
        with {:ok, json} <- Poison.encode(data) do
          Http.post("/views.json", o, json)
        end
      end
    end
  end

  defmodule UpdateView do
    defstruct fourfour: nil, properties: %{}, validate_only: nil

    defimpl Execute, for: __MODULE__ do
      def run(%UpdateView{validate_only: nil} = vv, o) do
        with {:ok, json} <- Poison.encode(vv.properties) do
          Http.put("/views/#{Http.encode(vv.fourfour)}.json", o, json)
        end
      end


      def run(%UpdateView{validate_only: validate_only} = vv, o) do
        with {:ok, json} <- Poison.encode(vv.properties) do
          Http.put("/views/#{Http.encode(vv.fourfour)}.json?validateOnly=#{Http.encode(validate_only)}", o, json)
        end
      end
    end
  end

  defmodule ValidateView do
    defstruct fourfour: nil, properties: %{}

    defimpl Execute, for: __MODULE__ do
      def run(uv, o) do
        with {:ok, json} <- Poison.encode(uv.properties) do
          Http.put("/views/#{Http.encode(uv.fourfour)}.json?method=validate", o, json)
        end
      end
    end
  end

  defmodule Upsert do
    defstruct fourfour: nil, mode: nil, rows: [], options: nil

    defimpl Execute, for: __MODULE__ do
      def run(%Upsert{rows: rows, mode: mode, fourfour: fourfour, options: options}, o) when is_list(rows) do
        with {:ok, json} <- Poison.encode(rows) do
          url = case options do
            %{} = params ->
              "/id/#{Http.encode(fourfour)}.json?" <> Plug.Conn.Query.encode(params)
            _ ->
              "/id/#{Http.encode(fourfour)}.json"
          end

          case mode do
            :append -> Http.post(url, o, json)
            :replace -> Http.put(url, o, json)
          end
        end
      end

      def run(%Upsert{rows: rows, mode: mode, fourfour: fourfour, options: options}, o) do
        with_commas = Stream.transform(rows, false, fn
          row, false -> {[Poison.encode!(row)], true}
          row, true  -> {[",\n" <> Poison.encode!(row)], true}
        end)

        json_stream = Stream.concat(
          ["["],
          with_commas
        )
        |> Stream.concat(["]"])

        url = case options do
          %{} = params ->
            "/id/#{Http.encode(fourfour)}.json?" <> Plug.Conn.Query.encode(params)
          _ ->
            "/id/#{Http.encode(fourfour)}.json"
        end

        case mode do
          :append -> Http.post(url, o, {:stream, json_stream})
          :replace -> Http.put(url, o, {:stream, json_stream})
        end
      end
    end
  end

  defmodule Copy do
    defstruct fourfour: nil, copy_data: true

    defimpl Execute, for: __MODULE__ do
      def run(%Copy{copy_data: copy_data} = copy, o) do
        json = Poison.encode!(%{})
        url =
          if copy_data do
            "/views/#{Http.encode(copy.fourfour)}/publication?method=copy"
          else
            "/views/#{Http.encode(copy.fourfour)}/publication?method=copySchema"
          end
        Http.post(url, o, json)
      end
    end
  end

  defmodule Publish do
    defstruct fourfour: nil

    defimpl Execute, for: __MODULE__ do
      def run(p, o) do
        json = Poison.encode!(%{})
        Http.post("/views/#{Http.encode(p.fourfour)}/publication", o, json)
      end
    end
  end

  defmodule Permission do
    defstruct fourfour: nil, mode: nil

    defimpl Execute, for: __MODULE__ do
      def run(%Permission{fourfour: fourfour, mode: mode}, o) do
        with {:ok, json} <- Poison.encode(mode) do
          Http.put("/views/#{Http.encode(fourfour)}?method=setPermission", o, json)
        end
      end
    end
  end

  defmodule Permissions do
    defstruct fourfour: nil, blob: nil

    defimpl Execute, for: __MODULE__ do
      def run(%Permissions{fourfour: fourfour, blob: blob}, o) do
        with {:ok, json} <- Poison.encode(blob) do
          Http.put("/views/#{fourfour}/permissions", o, json)
        end
      end
    end
  end

  defmodule PrepareDraftForImport do
    defstruct fourfour: nil, nbe: nil

    defimpl Execute, for: __MODULE__ do
      def run(%PrepareDraftForImport{fourfour: fourfour, nbe: nil}, o) do
        json = Poison.encode!(%{})
        Http.patch("/views/#{Http.encode(fourfour)}?method=prepareDraftForImport", o, json)
      end

      def run(%PrepareDraftForImport{fourfour: fourfour, nbe: nbe}, o) do
        json = Poison.encode!(%{})
        Http.patch("/views/#{Http.encode(fourfour)}?method=prepareDraftForImport&nbe=#{Http.encode(nbe)}", o, json)
      end
    end
  end

  defmodule SetBlobForDraft do
    defstruct fourfour: nil, filename: nil, file_path: nil, byte_stream: nil

    defimpl Execute, for: __MODULE__ do
      def run(%SetBlobForDraft{fourfour: fourfour, file_path: file_path}, o) when is_binary(file_path) do
        body = {:multipart, [file: file_path]}
        url = "/imports2?method=setBlobForDraft&saveUnderViewUid=#{Http.encode(fourfour)}"
        Http.post(url, o, body)
      end

      def run(%SetBlobForDraft{fourfour: fourfour, byte_stream: byte_stream, filename: filename}, o) do
        body = {:stream, byte_stream}
        headers = %{content_type: "application/octet-stream", filename: filename}
        ops = %{opts: Map.merge(o.opts, headers)}
        url = "/imports2?method=setBlobForDraft&saveUnderViewUid=#{Http.encode(fourfour)}"
        Http.post(url, ops, body)
      end
    end
  end

  defmodule ReplaceBlob do
    defstruct fourfour: nil, filename: nil, file_path: nil, byte_stream: nil

    defimpl Execute, for: __MODULE__ do
      def run(%ReplaceBlob{fourfour: fourfour, file_path: file_path}, o) when is_binary(file_path) do
        body = {:multipart, [file: file_path]}
        url = "/views/#{Http.encode(fourfour)}?method=replaceBlob"
        Http.post(url, o, body)
      end
      def run(%ReplaceBlob{fourfour: fourfour, byte_stream: byte_stream, filename: filename}, o) do
        body = {:stream, byte_stream}
        headers = %{content_type: "application/octet-stream", filename: filename}
        ops = %{opts: Map.merge(o.opts, headers)}
        url = "/views/#{Http.encode(fourfour)}?method=replaceBlob"
        Http.post(url, ops, body)
      end
    end
  end

  defmodule UploadAttachment do
    defstruct [:fourfour, :byte_stream, :filename]

    defimpl Execute, for: __MODULE__ do
      def run(%UploadAttachment{fourfour: fourfour, byte_stream: byte_stream, filename: filename}, o) do
        body = {:stream, byte_stream}
        headers = %{content_type: "application/octet-stream", filename: filename}
        ops = %{opts: Map.merge(o.opts, headers)}
        url = "/views/#{Http.encode(fourfour)}/files.txt"
        Http.post(url, ops, body)
      end
    end
  end

  # For backwards compat
  def write(options \\ []), do: Runner.new(options)

  def new(options \\ []), do: Runner.new(options)
  def run(operations), do: Runner.run(operations)

  def create(%Operations{} = o, name, properties) do
    prepend(%CreateView{name: name, properties: properties}, o)
  end

  def update(%Operations{} = o, fourfour, properties, validate_only \\ false) do
    prepend(%UpdateView{fourfour: fourfour, properties: properties, validate_only: validate_only}, o)
  end

  def validate(%Operations{} = o, fourfour, properties) do
    prepend(%ValidateView{fourfour: fourfour, properties: properties}, o)
  end

  def create_column(%Operations{} = o, fourfour, name, type, properties) do
    prepend(%CreateColumn{name: name, dataTypeName: type, fourfour: fourfour, properties: properties}, o)
  end

  def update_column(%Operations{} = o, fourfour, field_name, properties) do
    prepend(%UpdateColumn{fourfour: fourfour, fieldName: field_name, properties: properties}, o)
  end

  def drop_column(%Operations{} = o, fourfour, field_name, properties) do
    prepend(%DropColumn{field_name: field_name, fourfour: fourfour, properties: properties}, o)
  end

  def drop_view(%Operations{} = o, fourfour) do
    prepend(%DropView{fourfour: fourfour}, o)
  end

  def drop_working_copy(%Operations{} = o, fourfour) do
    prepend(%DropWorkingCopy{fourfour: fourfour}, o)
  end

  # a row looks like: {fieldName: value, fieldName: value}
  def upsert(%Operations{} = o, fourfour, rows, options \\ nil) do
    prepend(%Upsert{fourfour: fourfour, rows: rows, mode: :append, options: options}, o)
  end

  def replace(%Operations{} = o, fourfour, rows, options \\ nil) do
    prepend(%Upsert{fourfour: fourfour, rows: rows, mode: :replace, options: options}, o)
  end

  def copy(%Operations{} = o, fourfour, copy_data \\ true) do
    prepend(%Copy{fourfour: fourfour, copy_data: copy_data}, o)
  end

  def publish(%Operations{} = o, fourfour) do
    prepend(%Publish{fourfour: fourfour}, o)
  end

  def permission(%Operations{} = o, fourfour, :public) do
    prepend(%Permission{fourfour: fourfour, mode: "public.read"}, o)
  end

  def permission(%Operations{} = o, fourfour, :private) do
    prepend(%Permission{fourfour: fourfour, mode: "private"}, o)
  end

  def permissions(%Operations{} = o, fourfour, blob) when is_map(blob) do
    prepend(%Permissions{fourfour: fourfour, blob: blob}, o)
  end

  def prepare_draft_for_import(%Operations{} = o, fourfour, nbe \\ false) do
    prepend(%PrepareDraftForImport{fourfour: fourfour, nbe: nbe}, o)
  end

  def set_blob_for_draft(%Operations{} = o, fourfour, file_path) when is_binary(file_path) do
    prepend(%SetBlobForDraft{fourfour: fourfour, file_path: file_path}, o)
  end
  def set_blob_for_draft(%Operations{} = o, fourfour, byte_stream, filename) when is_map(byte_stream) do
    prepend(%SetBlobForDraft{fourfour: fourfour, byte_stream: byte_stream, filename: filename}, o)
  end

  def replace_blob(%Operations{} = o, fourfour, file_path) when is_binary(file_path) do
    prepend(%ReplaceBlob{fourfour: fourfour, file_path: file_path}, o)
  end
  def replace_blob(%Operations{} = o, fourfour, byte_stream, filename) when is_map(byte_stream) do
    prepend(%ReplaceBlob{fourfour: fourfour, byte_stream: byte_stream, filename: filename}, o)
  end

  def upload_attachment(%Operations{} = o, fourfour, byte_stream, filename) do
    prepend(%UploadAttachment{fourfour: fourfour, byte_stream: byte_stream, filename: filename}, o)
  end
end

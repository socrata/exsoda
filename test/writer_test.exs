defmodule ExsodaTest.Writer do
  use ExUnit.Case, async: true
  alias HTTPoison.Response
  alias Exsoda.Config
  alias Exsoda.Writer
  alias Exsoda.Reader
  alias Exsoda.Writer.{
    CreateView,
    UpdateView,
    CreateColumn,
    Permission,
    Publish,
    PrepareDraftForImport,
    SetBlobForDraft,
    ReplaceBlob,
    UploadAttachment
  }

  def wait_for_replication(fourfour, attempts_left \\ 10) do
    {:ok, %HTTPoison.Response{body: body}} = Reader.query(fourfour) |>  Reader.replication
    case body do
      %{"read_replication_up_to_date" => true} ->
          :done
      %{"read_replication_up_to_date" => false} ->
          :timer.sleep(500) # wait half a second
          wait_for_replication(fourfour, attempts_left - 1)
    end
  end

  test "can create a create_view operation" do
    w = Writer.write()
    |> Writer.create("a name", %{description: "describes"})

    assert w.operations == [%CreateView{
      name: "a name",
      properties: %{description: "describes"}
    }]
  end

  test "can write with a timeout set" do
    options = Writer.write(recv_timeout: 8000, timeout: 2000)
    |> Writer.create("a name", %{description: "describes"})
    |> Map.get(:opts)

    assert options.recv_timeout == 8000
    assert options.timeout == 2000
  end

  test "can write with parameters" do
    options = Writer.write([params: %{"k1" => "v1", "k2" => "v2"}, recv_timeout: 8000, timeout: 2000])
              |> Writer.create("a name", %{description: "describes"})
              |> Map.get(:opts)

    assert options.recv_timeout == 8000
    assert options.timeout == 2000
    assert options.params == %{"k1" => "v1", "k2" => "v2"}
  end

  test "running CreateView returns list of results" do
    results = Writer.write()
    |> Writer.create("a name", %{description: "describes"})
    |> Writer.run

    assert [{:ok, _}] = results
  end

  test "running drop_view drops the view" do
    [{:ok, %{body: %{"id" => id}}}] = Writer.write()
    |> Writer.create("a name", %{description: "describes"})
    |> Writer.run

    assert [{:ok, _}] = Writer.write()
    |> Writer.drop_view(id)
    |> Writer.run
  end

  test "running CreateView with no name causes an error" do
    results = Writer.write()
    |> Writer.create("", %{description: "describes"})
    |> Writer.run

    assert [{:error, _}] = results
  end

  test "can create an UpdateView operation" do
    w = Writer.write()
    |> Writer.update("meow-meow", %{description: "describes"}, false)

    assert w.operations == [%UpdateView{
      fourfour: "meow-meow",
      properties: %{description: "describes"},
      validate_only: false
    }]
  end

  test "can run an UpdateView operation" do
    [{:ok, %Response{body: %{"id" => fourfour}}}] = Writer.write()
    |> Writer.create("a name", %{description: "describes"})
    |> Writer.run

    results = Writer.write()
    |> Writer.update(fourfour, %{description: "does not describe"}, false)
    |> Writer.run

    assert [{:ok, _}] = results

    {:ok, %Response{body: view}} = Reader.query(fourfour)
    |> Reader.get_view

    assert "does not describe" == Map.get(view, "description", nil)
  end

  test "can create an UpdateView operation that only validates" do
    w = Writer.write()
    |> Writer.update("bark-bark", %{description: "describes"}, true)

    assert w.operations == [%UpdateView{
      fourfour: "bark-bark",
      properties: %{description: "describes"},
      validate_only: true
    }]
  end

  test "can create a CreateColumn operation" do
    w = Writer.write()
    |> Writer.create_column("meow-meow", "a name", "text", %{})

    assert w.operations == [%CreateColumn{
      name: "a name",
      dataTypeName: "text",
      fourfour: "meow-meow",
      properties: %{}
    }]
  end

  test "running two CreateColumn ops returns list of results" do
    [{:ok, %Response{body: %{"id" => fourfour}}}] = Writer.write()
    |> Writer.create("a name", %{description: "describes"})
    |> Writer.run

    results = Writer.write()
    |> Writer.create_column(fourfour, "a name", "text", %{})
    |> Writer.create_column(fourfour, "a number", "number", %{})
    |> Writer.run

    assert [{:ok, _}, {:ok, _}] = results

    {:ok, %Response{body: view}} = Reader.query(fourfour)
    |> Reader.get_view

    col_tuples = view
    |> Map.get("columns", [])
    |> Enum.map(fn column -> {column["name"], column["dataTypeName"]} end)

    assert col_tuples == [
      {"a name", "text"},
      {"a number", "number"}
    ]
  end

  test "running CreateColumn with a bad type causes an error" do
    [{:ok, %Response{body: %{"id" => fourfour}}}] = Writer.write()
    |> Writer.create("a name", %{description: "describes"})
    |> Writer.run

    results = Writer.write()
    |> Writer.create_column(fourfour, "name", "not a type", %{})
    |> Writer.run
    assert [{:error, _}] = results
  end

  test "can create Upsert operation" do
    [{:ok, %Response{body: %{"id" => fourfour}}}] = Writer.write()
    |> Writer.create("a name", %{description: "describes"})
    |> Writer.run

    [{:ok, _}] = Writer.write()
    |> Writer.create_column(fourfour, "text column", "text", %{})
    |> Writer.run

    results = Writer.write()
    |> Writer.upsert(
      fourfour,
      [%{text_column: "a text value"}, %{text_column: "a second text value"}]
    )
    |> Writer.run

    assert [{:ok, _}] = results
    :done = wait_for_replication(fourfour)

    {:ok, rows_stream} = Reader.query(fourfour)
    |> Reader.run

    assert Enum.into(rows_stream, []) == [[{"text_column", "a text value"}], [{"text_column", "a second text value"}]]
  end

  test "can add options to Upsert operation" do
    [{:ok, %Response{body: %{"id" => fourfour}}}] = Writer.write()
    |> Writer.create("a name", %{description: "describes"})
    |> Writer.run

    [{:ok, _}] = Writer.write()
    |> Writer.create_column(fourfour, "text column", "text", %{})
    |> Writer.run

    results = Writer.write()
    |> Writer.upsert(
      fourfour,
      [%{text_column: "a text value"}, %{text_column: "a second text value"}],
      %{"this_is_an_option" => true}
    )
    |> Writer.run

    assert [{:ok, _}] = results

    [{:ok, results}] = results

    assert String.contains?(results.request_url, "this_is_an_option=true")
  end

  test "can do a streaming replace" do
    [{:ok, %Response{body: %{"id" => fourfour}}}] = Writer.write()
    |> Writer.create("a name", %{description: "describes"})
    |> Writer.run

    [{:ok, _}] = Writer.write()
    |> Writer.create_column(fourfour, "text column", "text", %{})
    |> Writer.run

    results = Writer.write()
    |> Writer.upsert(
      fourfour,
      Stream.map(0..8, fn i ->
        %{text_column: "value #{i}"}
      end)
    )
    |> Writer.run

    assert [{:ok, _}] = results

    :done = wait_for_replication(fourfour)

    {:ok, rows_stream} = Reader.query(fourfour)
    |> Reader.run

    assert Enum.into(rows_stream, []) == [
      [{"text_column", "value 0"}],
      [{"text_column", "value 1"}],
      [{"text_column", "value 2"}],
      [{"text_column", "value 3"}],
      [{"text_column", "value 4"}],
      [{"text_column", "value 5"}],
      [{"text_column", "value 6"}],
      [{"text_column", "value 7"}],
      [{"text_column", "value 8"}]
    ]
  end

  test "can create replace operation" do
    [{:ok, %Response{body: %{"id" => fourfour}}}] = Writer.write()
    |> Writer.create("a name", %{description: "describes"})
    |> Writer.run

    [{:ok, _}] = Writer.write()
    |> Writer.create_column(fourfour, "text column", "text", %{})
    |> Writer.run

    results = Writer.write()
    |> Writer.replace(
      fourfour,
      [%{text_column: "a text value"}, %{text_column: "a second text value"}]
    )
    |> Writer.run

    assert [{:ok, _}] = results
    :done = wait_for_replication(fourfour)

    {:ok, rows_stream} = Reader.query(fourfour)
    |> Reader.run

    assert Enum.into(rows_stream, []) == [[{"text_column", "a text value"}], [{"text_column", "a second text value"}]]
  end

  test "can do a streaming upsert" do
    [{:ok, %Response{body: %{"id" => fourfour}}}] = Writer.write()
    |> Writer.create("a name", %{description: "describes"})
    |> Writer.run

    [{:ok, _}] = Writer.write()
    |> Writer.create_column(fourfour, "text column", "text", %{})
    |> Writer.run

    results = Writer.write()
    |> Writer.replace(
      fourfour,
      Stream.map(0..8, fn i ->
        %{text_column: "value #{i}"}
      end)
    )
    |> Writer.run

    assert [{:ok, _}] = results

    :done = wait_for_replication(fourfour)

    {:ok, rows_stream} = Reader.query(fourfour)
    |> Reader.run

    assert Enum.into(rows_stream, []) == [
      [{"text_column", "value 0"}],
      [{"text_column", "value 1"}],
      [{"text_column", "value 2"}],
      [{"text_column", "value 3"}],
      [{"text_column", "value 4"}],
      [{"text_column", "value 5"}],
      [{"text_column", "value 6"}],
      [{"text_column", "value 7"}],
      [{"text_column", "value 8"}]
    ]
  end

  test "can create a Publish operation" do
    w = Writer.write()
    |> Writer.publish("cafe-cafe")

    assert w.operations == [
      %Publish{
        fourfour: "cafe-cafe"
      }]
  end

  test "running Publish succeeds" do
    results = Writer.write()
    |> Writer.create("a name", %{description: "describes"})
    |> Writer.run

    [{:ok, %Response{body: %{"id" => id}}}] = results

    results = Writer.write()
    |> Writer.publish(id)
    |> Writer.run

    assert [{:ok, %Response{body: %{"id" => ^id,
                    "publicationStage" => "published"}}}] = results
  end

  test "can create a public Permission operation" do
    w = Writer.write()
    |> Writer.permission("cafe-cafe", :public)

    assert w.operations == [
      %Permission{
        fourfour: "cafe-cafe",
        mode: "public.read"
      }]
  end

  test "setting Permission succeeds" do
    results = Writer.write()
    |> Writer.create("a name", %{description: "describes"})
    |> Writer.run

    [{:ok, %Response{body: %{"id" => id} = view}}] = results

    assert !Map.has_key?(view, "grants")

    results = Writer.write()
    |> Writer.permission(id, :public)
    |> Writer.run

    assert [{:ok, _}] = results

    # TODO: this broke??
    # {:ok, %Response{body: view}} = Reader.query(id)
    # |> Reader.get_view
    # assert %{"grants" => [%{"flags" => ["public"]}]} = view

    results = Writer.write()
    |> Writer.permission(id, :private)
    |> Writer.run

    assert [{:ok, _}] = results

    {:ok, view} = Reader.query(id)
    |> Reader.get_view

    assert !Map.has_key?(view, "grants")
  end

  test "setting the Permissions blob succeeds" do
    results = Writer.write()
    |> Writer.create("a name", %{description: "describes"})
    |> Writer.run

    [{:ok, %Response{body: %{"id" => id} = view}}] = results

    assert !Map.has_key?(view, "grants")

    results = Writer.write()
    |> Writer.permissions(id, %{scope: "public"})
    |> Writer.run

    assert [{:ok, resp}] = results
    assert resp.status_code == 200

    assert {:ok, %{body: %{"pendingGrants" => [%{"flags" => ["public"]}]}}} = Reader.query(id)
    |> Reader.get_view

  end

  test "can create a PrepareDraftForImport operation" do
    w = Writer.write()
    |> Writer.prepare_draft_for_import("meow-meow")

    assert w.operations == [
      %PrepareDraftForImport{
        fourfour: "meow-meow",
        nbe: false
      }]
  end

  test "can create a SetBlobForDraft operation" do
    w = Writer.write()
    |> Writer.set_blob_for_draft("meow-meow", "/path/to/file.jpg")

    assert w.operations == [
      %SetBlobForDraft{
        fourfour: "meow-meow",
        file_path: "/path/to/file.jpg"
      }]
  end
  test "can create a SetBlobForDraft operation with a byte stream" do
    byte_stream = File.stream!("/path/to/file.jpg", [], 20)
    filename = "filename.jpg"
    w = Writer.write()
    |> Writer.set_blob_for_draft("meow-meow", byte_stream, filename)

    assert w.operations == [
      %SetBlobForDraft{
        fourfour: "meow-meow",
        byte_stream: byte_stream,
        filename: filename,
        content_type: "application/octet-stream"
      }]
  end

  test "can create a replaceBlob operation with a byte stream" do
    byte_stream = File.stream!("/path/to/file.jpg", [], 20)
    filename = "filename.jpg"
    w = Writer.write()
    |> Writer.replace_blob("meow-meow",  byte_stream, filename)

    assert w.operations == [
      %ReplaceBlob{
        fourfour: "meow-meow",
        byte_stream: byte_stream,
        filename: filename,
        content_type: "application/octet-stream"
      }]
  end

  test "can create an attachment with a byte stream" do
    byte_stream = File.stream!("/path/to/file.jpg", [], 20)
    filename = "filename.jpg"
    w = Writer.write()
    |> Writer.upload_attachment("meow-meow",  byte_stream, filename)

    assert w.operations == [
      %UploadAttachment{
        fourfour: "meow-meow",
        byte_stream: byte_stream,
        filename: filename,
        content_type: "application/octet-stream"
      }]
  end

  # This test requires being on the us-west-2 VPN to pass
  @tag external: true
  test "running PrepareDraftForImport succeeds" do
    results = Writer.write()
    |> Writer.create("a name", %{description: "describes", displayType: "draft"})
    |> Writer.run

    [{:ok, %{"id" => id}}] = results

    [{:ok, _}] = Writer.write()
    |> Writer.prepare_draft_for_import(id)
    |> Writer.run
  end

  # This test requires being on the us-west-2 VPN to pass
  @tag external: true
  test "can spoof a user during a write request" do
    spoofee_email = "test-viewer@socrata.com"
    spoof = %{
      spoofee_email: spoofee_email,
      spoofer_email: Config.get(:exsoda, :account),
      spoofer_password: Config.get(:exsoda, :password)
    }
    opts = [{:spoof, spoof}, {:host, "lb-vip.aws-us-west-2-staging.socrata.net:8081"}, {:api_root, ""}, {:protocol, "http"}]

    [{:error, response}] = Writer.write(opts)
    |> Writer.create("a name", %{description: "describes"})
    |> Writer.run

    assert {:ok, %{"code" => "permission_denied", "error" => true}} = Poison.decode(response.body)
    assert 403 == response.status_code
  end
end

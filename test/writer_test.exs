defmodule ExsodaTest.Writer do
  use ExUnit.Case
  alias Exsoda.Writer
  alias Exsoda.Writer.{CreateView, CreateColumn}

  test "can create a create_view operation" do
    w = Writer.write()
    |> Writer.create("a name", %{description: "describes"})

    assert w.operations == [%CreateView{
      name: "a name",
      properties: %{description: "describes"}
    }]
  end

  test "running CreateView returns list of results" do
    results = Writer.write()
    |> Writer.create("a name", %{description: "describes"})
    |> Writer.run

    assert [{:ok, _}] = results
  end

  test "running CreateView with no name causes an error" do
    results = Writer.write()
    |> Writer.create("", %{description: "describes"})
    |> Writer.run

    assert [{:error, _}] = results
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
    [{:ok, %{"id" => fourfour}}] = Writer.write()
    |> Writer.create("a name", %{description: "describes"})
    |> Writer.run

    results = Writer.write()
    |> Writer.create_column(fourfour, "a name", "text", %{})
    |> Writer.create_column(fourfour, "a number", "number", %{})
    |> Writer.run

    assert [{:ok, _}, {:ok, _}] = results
  end

  test "running CreateColumn with a bad type causes an error" do
    [{:ok, %{"id" => fourfour}}] = Writer.write()
    |> Writer.create("a name", %{description: "describes"})
    |> Writer.run

    results = Writer.write()
    |> Writer.create_column(fourfour, "name", "not a type", %{})
    |> Writer.run
    assert [{:error, _}] = results
  end

end

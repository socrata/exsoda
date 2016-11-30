defmodule ExsodaTest.Writer do
  use ExUnit.Case
  alias Exsoda.Writer
  alias Exsoda.Writer.CreateView

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

end

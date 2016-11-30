defmodule ExsodaTest.Writer do
  use ExUnit.Case
  alias Exsoda.Writer

  test "can add some data" do
    {:ok, view} = Writer.create(%{
      "name" => "foo foo"
    })

    assert view["name"] == "foo foo"
  end


end

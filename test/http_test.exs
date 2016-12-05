defmodule ExsodaTest.Http do
  use ExUnit.Case
  alias Exsoda.Http

  test "can make a base url" do
    actual = Http.base_url(%{opts: %{domain: "foo"}})
    assert actual == {:ok, "https://foo/api"}
  end

  test "can make a base url with explicit host" do
    actual = Http.base_url(%{opts: %{host: "foo"}})
    assert actual == {:ok, "https://foo/api"}
  end

  test "can make a base url with function as host" do
    actual = Http.base_url(%{opts: %{host: fn -> {:ok, "foo"} end}})
    assert actual == {:ok, "https://foo/api"}
  end
end

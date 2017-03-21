defmodule ExsodaTest.Http do
  use ExUnit.Case
  alias Exsoda.Http

  test "can make a base url" do
    actual = Http.base_url(%{opts: %{domain: "foo", api_root: "/api", protocol: "https"}})
    assert actual == {:ok, "https://foo/api"}
  end

  test "can make a base url with explicit host" do
    actual = Http.base_url(%{opts: %{host: "foo", api_root: "/api", protocol: "https"}})
    assert actual == {:ok, "https://foo/api"}
  end

  test "can make a base url with function as host" do
    actual = Http.base_url(%{opts: %{host: fn -> {:ok, "foo"} end, api_root: "/api", protocol: "https"}})
    assert actual == {:ok, "https://foo/api"}
  end

  test "respects the api_root passed in" do
    actual = Http.base_url(%{opts: %{host: "foo", api_root: "", protocol: "https"}})
    assert actual == {:ok, "https://foo"}
  end

  test "respects the protocol passed in" do
    actual = Http.base_url(%{opts: %{host: "foo", api_root: "", protocol: "http"}})
    assert actual == {:ok, "http://foo"}
  end

  test "can override user_agent and request_id options" do
    overriden_options = Http.options([{:user_agent, "test-agent"}, {:request_id, "different-fake-uuid"}])
    assert overriden_options.user_agent == "test-agent"
    assert overriden_options.request_id == "different-fake-uuid"

  end
end

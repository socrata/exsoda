defmodule ExsodaTest.ConfigurationReader do
  use ExUnit.Case, async: true
  alias Exsoda.Config
  alias Exsoda.ConfigurationReader
  alias Exsoda.Configuration
  alias HTTPoison.Response

  defp expected_state(query) do
    %ConfigurationReader.Query{
      opts: %{
        password: Config.get(:exsoda, :password),
        account: Config.get(:exsoda, :account),
        domain: "cheetah.test-socrata.com",
        recv_timeout: 5000,
        timeout: 5000,
        api_root: "/api",
        protocol: "https",
        user_agent: "exsoda",
        request_id: "fake_request_id",
        app_token: nil,
        params: []
      },
      operations: [query]
    }
  end

  test "can make a config query" do
    result = ConfigurationReader.query
    |> ConfigurationReader.get_config("bleh", %ConfigurationReader.GetConfig{default_only: 5,
                                                                             merge: "haha"})
    assert result == expected_state(%ConfigurationReader.GetConfig{type: "bleh",
                                                                   default_only: 5,
                                                                   merge: "haha"})
  end

  test "can query a config" do
    [ok: %Response{body: body}] = ConfigurationReader.query
    |> ConfigurationReader.get_config("view_categories", %ConfigurationReader.GetConfig{merge: true})
    |> ConfigurationReader.run

    assert [
      %Configuration{id: 1, name: "View categories", type: "view_categories"},
      %Configuration{id: 897, name: "View categories", type: "view_categories"}
    ] = body
  end
end

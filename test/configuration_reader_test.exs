defmodule ExsodaTest.ConfigurationReader do
  use ExUnit.Case, async: true
  alias Exsoda.Config
  alias Exsoda.ConfigurationReader
  alias Exsoda.Configuration

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
        request_id: "fake_request_id"
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
    [ok: response] = ConfigurationReader.query
    |> ConfigurationReader.get_config("view_categories", %ConfigurationReader.GetConfig{merge: true})
    |> ConfigurationReader.run

    assert response == [%Configuration{id: 1,
                                       name: "View categories",
                                       properties: [%Configuration.Property{name: "government",
                                                                            value: %{"enabled" => true}},
                                                    %Configuration.Property{name: "education",
                                                                            value: %{"enabled" => true}},
                                                    %Configuration.Property{name: "business",
                                                                            value: %{"enabled" => true}},
                                                    %Configuration.Property{name: "personal",
                                                                            value: %{"enabled" => true}},
                                                    %Configuration.Property{name: "fun",
                                                                            value: %{"enabled" => true}}],
                                       type: "view_categories"},
                        %Configuration{id: 897,
                                       name: "View categories",
                                       properties: [%Exsoda.Configuration.Property{name: "education", value: %{"enabled" => true}},
                                                    %Exsoda.Configuration.Property{name: "government", value: %{"enabled" => true}},
                                                    %Exsoda.Configuration.Property{name: "business", value: %{"enabled" => true}},
                                                    %Exsoda.Configuration.Property{name: "Hidden", value: %{"enabled" => false, "locale_strings" => %{"en" => "Hidden", "es" => ""}}},
                                                    %Exsoda.Configuration.Property{name: "personal", value: %{"enabled" => true}},
                                                    %Exsoda.Configuration.Property{name: "fun", value: %{"enabled" => true}}],
                                      type: "view_categories"}]
  end
end

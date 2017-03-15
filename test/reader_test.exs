defmodule ExsodaTest.Reader do
  use ExUnit.Case, async: true
  import Exsoda.Reader
  alias Exsoda.Config


  defp expected_state(query) do
    %Exsoda.Reader.Query{
      opts: %{
        password: Config.get(:exsoda, :password),
        account: Config.get(:exsoda, :account),
        domain: "cheetah.test-socrata.com",
        recv_timeout: 5000,
        timeout: 5000,
        api_root: "/api",
        protocol: "https"
      },
      fourfour: "four-four",
      query: query}
  end

  test "can make a selection" do
    result = query("four-four")
    |> select([:region, :magnitude])

    assert result == expected_state(%{"$select" => "region, magnitude"})
  end

  test "can make a where" do
    result = query("four-four")
    |> select([:region, :magnitude])
    |> where("magnitude > 4.0")

    assert result == expected_state(%{
      "$select" => "region, magnitude",
      "$where" => "magnitude > 4.0"
    })
  end

  test "can make an order" do
    result = query("four-four")
    |> select([:region, :magnitude])
    |> where("magnitude > 4.0")
    |> order("region")

    assert result == expected_state(%{
      "$select" => "region, magnitude",
      "$where" => "magnitude > 4.0",
      "$order" => "region"
    })
  end

  test "can make an ascending order" do
    result = query("four-four")
    |> select([:region, :magnitude])
    |> where("magnitude > 4.0")
    |> order("region", :asc)

    assert result == expected_state(%{
      "$select" => "region, magnitude",
      "$where" => "magnitude > 4.0",
      "$order" => "region ASC"
    })
  end

  test "can make a descending order" do
    result = query("four-four")
    |> select([:region, :magnitude])
    |> where("magnitude > 4.0")
    |> order("region", :desc)

    assert result == expected_state(%{
      "$select" => "region, magnitude",
      "$where" => "magnitude > 4.0",
      "$order" => "region DESC"
    })
  end


  test "can make an limit" do
    result = query("four-four")
    |> select([:region, :magnitude])
    |> where("magnitude > 4.0")
    |> order("region")
    |> limit(5)

    assert result == expected_state(%{
      "$select" => "region, magnitude",
      "$where" => "magnitude > 4.0",
      "$order" => "region",
      "$limit" => 5
    })
  end

  test "can make an offset" do
    result = query("four-four")
    |> select([:region, :magnitude])
    |> where("magnitude > 4.0")
    |> order("region")
    |> limit(5)
    |> offset(5)

    assert result == expected_state(%{
      "$select" => "region, magnitude",
      "$where" => "magnitude > 4.0",
      "$order" => "region",
      "$limit" => 5,
      "$offset" => 5
    })
  end


  test "can make a group" do
    result = query("four-four")
    |> select([:region, :magnitude])
    |> where("magnitude > 4.0")
    |> order("region")
    |> offset(5)
    |> limit(5)
    |> group("foo")

    assert result == expected_state(%{
      "$select" => "region, magnitude",
      "$where" => "magnitude > 4.0",
      "$order" => "region",
      "$limit" => 5,
      "$offset" => 5,
      "$group" => "foo"
    })
  end

  test "can make a fulltext query" do
    result = query("four-four")
    |> select([:region, :magnitude])
    |> q("foobar")

    assert result == expected_state(%{
      "$select" => "region, magnitude",
      "$q" => "foobar"
    })
  end

  # ¯\_(ツ)_/¯  These tests actually make http requests ¯\_(ツ)_/¯

  @tag timeout: 10_000
  test "can actually make a query" do
    {:ok, stream} = query("upuy-x277")
    |> select([:region, :magnitude])
    |> where("magnitude > 4.0")
    |> order("region")
    |> limit(10)
    |> offset(5)
    |> run

    result = Enum.into(stream, [])

    assert result == [
      [{"Region", "0km SE of Sakai, Japan"}, {"Magnitude", 4.6}],
      [{"Region", "0km SE of Sakai, Japan"}, {"Magnitude", 4.6}],
      [{"Region", "0km SE of Sakai, Japan"}, {"Magnitude", 4.6}],
      [{"Region", "0km SE of Sakai, Japan"}, {"Magnitude", 4.6}],
      [{"Region", "0km SE of Sakai, Japan"}, {"Magnitude", 4.6}],
      [{"Region", "100km E of Ile Hunter, New Caledonia"}, {"Magnitude", 5.6}],
      [{"Region", "100km E of Ile Hunter, New Caledonia"}, {"Magnitude", 5.6}],
      [{"Region", "100km E of Ile Hunter, New Caledonia"}, {"Magnitude", 5.6}],
      [{"Region", "100km E of Ile Hunter, New Caledonia"}, {"Magnitude", 5.6}],
      [{"Region", "100km E of Ile Hunter, New Caledonia"}, {"Magnitude", 5.6}]
    ]
  end

  @tag timeout: 10_000
  test "can query with alt credentials not set via config" do
    {:error, response} = query("upuy-x277", domain: "google.com", account: "nope", password: "hunter2")
    |> select([:region, :magnitude])
    |> where("magnitude > 4.0")
    |> order("region")
    |> limit(5)
    |> offset(5)
    |> run

    assert response.status_code == 404
  end

  @tag timeout: 10_000
  test "can query with host from environment variables" do
    {:error, response} = query("upuy-x277", host: {:system, "FOOFOO", "blah"})
    |> select([:region, :magnitude])
    |> where("magnitude > 4.0")
    |> order("region")
    |> limit(5)
    |> offset(5)
    |> run

    assert %HTTPoison.Error{reason: :nxdomain} = response
  end


  @tag timeout: 10_000
  test "can get a view" do
    {:ok, view} = query("upuy-x277")
    |> get_view

    assert view["id"] == "upuy-x277"
  end


end

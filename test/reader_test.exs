defmodule ExsodaTest.Reader do
  use ExUnit.Case
  import Exsoda.Reader


  test "can make a selection" do
    assert select([:region, :magnitude]) == %{
      "$select" => "region, magnitude"
    }
  end

  test "can make a where" do
    assert select([:region, :magnitude]) 
    |> where("magnitude > 4.0") == %{
      "$select" => "region, magnitude", 
      "$where" => "magnitude > 4.0"
    }
  end

  test "can make an order" do
    assert select([:region, :magnitude]) 
    |> where("magnitude > 4.0")
    |> order("region") == %{
      "$select" => "region, magnitude", 
      "$where" => "magnitude > 4.0",
      "$order" => "region"
    }
  end

  test "can make an ascending order" do
    assert select([:region, :magnitude]) 
    |> where("magnitude > 4.0")
    |> order("region", direction: :asc) == %{
      "$select" => "region, magnitude", 
      "$where" => "magnitude > 4.0",
      "$order" => "region ASC"
    }
  end

  test "can make a descending order" do
    assert select([:region, :magnitude]) 
    |> where("magnitude > 4.0")
    |> order("region", direction: :desc) == %{
      "$select" => "region, magnitude", 
      "$where" => "magnitude > 4.0",
      "$order" => "region DESC"
    }
  end


  test "can make an limit" do
    assert select([:region, :magnitude]) 
    |> where("magnitude > 4.0")
    |> order("region") 
    |> limit(5) == %{
      "$select" => "region, magnitude", 
      "$where" => "magnitude > 4.0",
      "$order" => "region",
      "$limit" => 5
    }
  end

  test "can make an offset" do
    assert select([:region, :magnitude]) 
    |> where("magnitude > 4.0")
    |> order("region") 
    |> limit(5)
    |> offset(5) == %{
      "$select" => "region, magnitude", 
      "$where" => "magnitude > 4.0",
      "$order" => "region",
      "$limit" => 5,
      "$offset" => 5
    }
  end


  test "can make an group" do
    assert select([:region, :magnitude]) 
    |> where("magnitude > 4.0")
    |> order("region") 
    |> offset(5)
    |> limit(5)
    |> group("foo") == %{
      "$select" => "region, magnitude", 
      "$where" => "magnitude > 4.0",
      "$order" => "region",
      "$limit" => 5,
      "$offset" => 5,
      "$group" => "foo"
    }
  end

  test "can make a fulltext query" do
    assert select([:region, :magnitude]) 
    |> q("foobar") == %{
      "$select" => "region, magnitude",
      "$q" => "foobar"
    }
  end


  #This is a shitty test
  @tag timeout: 10_000
  test "can actually make a query" do
    results = read "4tka-6guv" do
      select([:region, :magnitude]) 
      |> where("magnitude > 4.0")
      |> order("region") 
      |> limit(5)
      |> offset(5)
    end

    assert results == {:ok, [
      %{"magnitude" => "4.6", "region" => "103km ESE of Madang, Papua New Guinea"},
      %{"magnitude" => "4.3", "region" => "103km NNW of Nome, Alaska"},
      %{"magnitude" => "4.6", "region" => "103km WNW of Iquique, Chile"},
      %{"magnitude" => "4.7", "region" => "103km WNW of Kota Ternate, Indonesia"},
      %{"magnitude" => "4.5", "region" => "103km WSW of Kota Ternate, Indonesia"}
    ]}
  end

  @tag timeout: 10_000
  test "can query with alt credentials not set via config" do
    {:error, {status, _body}} = read "4tka-6guv", domain: "google.com", account: "nope", password: "hunter2" do
      select([:region, :magnitude]) 
      |> where("magnitude > 4.0")
      |> order("region") 
      |> limit(5)
      |> offset(5)
    end

    assert status == 404
  end
end

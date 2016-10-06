# exsoda [![Build Status](https://travis-ci.org/rozap/exsoda.svg?branch=master)](https://travis-ci.org/rozap/exsoda)

## What
This is a tiny wrapper for the socrata Soda2 open data API. It returns datasets as elixir streams for lazy evaluation.


## usage
```elixir


## Play around in the console

iex(1)> import Exsoda.Reader
iex(8)> with {:ok, stream} <- query("4tka-6guv", domain: "soda.demo.socrata.com") |> select([:region, :magnitude]) |> where("magnitude > 4.0") |> run do
...(8)>     Enum.take(stream, 2)
...(8)> end
[[{"Region", "south of the Fiji Islands"}, {"Magnitude", 4.6}],
 [{"Region", "Northern California"}, {"Magnitude", 4.4}]]


## Or elsewhere

result = query("4tka-6guv", )
|> select([:region, :magnitude])
|> where("magnitude > 4.0")
|> order("region")
|> limit(10)
|> offset(5)
|> run

with {:ok, row_stream} <- result do
  Stream.map(row_stream, fn row ->
    IO.inspect row
  end)
end

# This will print something like the following to the console:
[{"Region", "0km SE of Sakai, Japan"}, {"Magnitude", 4.6}]
[{"Region", "0km SE of Sakai, Japan"}, {"Magnitude", 4.6}]
[{"Region", "0km SE of Sakai, Japan"}, {"Magnitude", 4.6}]
[{"Region", "0km SE of Sakai, Japan"}, {"Magnitude", 4.6}]
[{"Region", "0km SE of Sakai, Japan"}, {"Magnitude", 4.6}]
[{"Region", "100km E of Ile Hunter, New Caledonia"}, {"Magnitude", 5.6}]
[{"Region", "100km E of Ile Hunter, New Caledonia"}, {"Magnitude", 5.6}]
[{"Region", "100km E of Ile Hunter, New Caledonia"}, {"Magnitude", 5.6}]
[{"Region", "100km E of Ile Hunter, New Caledonia"}, {"Magnitude", 5.6}]
[{"Region", "100km E of Ile Hunter, New Caledonia"}, {"Magnitude", 5.6}]


```

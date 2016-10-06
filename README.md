# exsoda [![Build Status](https://travis-ci.org/rozap/exsoda.svg?branch=master)](https://travis-ci.org/rozap/exsoda)


## usage
```elixir

#Get some earthquakes

result = query("4tka-6guv")
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

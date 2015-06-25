# exsoda


## usage
```elixir

#Get some earthquakes
results = query "4tka-6guv" do
  select([:region, :magnitude]) 
  |> where("magnitude > 4.0")
  |> order("region") 
  |> limit(5)
  |> offset(5)
end

#result might look like:
{:ok, [
      %{"magnitude" => "4.6", "region" => "103km ESE of Madang, Papua New Guinea"},
      %{"magnitude" => "4.3", "region" => "103km NNW of Nome, Alaska"},
      %{"magnitude" => "4.6", "region" => "103km WNW of Iquique, Chile"},
      %{"magnitude" => "4.7", "region" => "103km WNW of Kota Ternate, Indonesia"},
      %{"magnitude" => "4.5", "region" => "103km WSW of Kota Ternate, Indonesia"}
]}

```

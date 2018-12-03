defmodule Exsoda.Util.Column do
  def merge_column(cc), do: Map.take(cc, [:dataTypeName, :name]) |> Map.merge(cc.properties)
  # @column_create_optimization false
  # def collapse_column_create([]), do: []
  # def collapse_column_create([%CreateColumn{fourfour: fourfour} = cc | ccs]) do
  #   if @column_create_optimization do
  #     {ccs, remainder} = Enum.split_while(ccs, fn
  #       %CreateColumn{fourfour: ^fourfour} -> true
  #       _ -> false
  #     end)
  #     [%CreateColumns{columns: [cc | ccs]} | collapse_column_create(remainder)]
  #   else
  #     [cc | ccs]
  #   end
  # end
  # def collapse_column_create([h | t]), do: [h | collapse_column_create(t)]

end
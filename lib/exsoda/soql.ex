defmodule Exsoda.Soql do

  def from_string("number", number) do
    case Float.parse(number) do
      :error -> "from_string/2 :: Cannot convert #{number} to number"
      {floaty, _remainder} -> floaty
    end
  end

  def from_string("text", text), do: text

  def from_string(type, value) do
    {:error, "from_string/2 :: Cannot convert #{value} to #{type}"}
  end
end
defmodule Exsoda.Configuration do
  @derive [Poison.Encoder]
  @derive [Poison.Decoder]
  defstruct id: nil, name: nil, type: nil, properties: nil, domainCName: nil

  defmodule Property do
    defstruct name: nil, value: nil
  end
end

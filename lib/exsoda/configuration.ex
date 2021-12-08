defmodule Exsoda.Configuration do
  @derive [Poison.Encoder]
  defstruct id: nil, name: nil, type: nil, properties: nil, domainCName: nil

  @derive [Poison.Decoder]
  defmodule Property do
    defstruct name: nil, value: nil
  end
end

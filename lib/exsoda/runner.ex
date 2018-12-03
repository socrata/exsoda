defmodule Exsoda.Runner do
  alias Exsoda.Http

  defprotocol Execute do
  	def run(operation, operations)
  end

	defmodule Operations do
		defstruct opts: %{}, operations: []
	end

	def new(options \\ []) do
		%Operations{
			opts: Http.options(options)
		}
	end

	def prepend(operation, %Operations{} = o) do
		%Operations{ o | operations: [ operation | o.operations ]}
	end

	def run(%Operations{} = o) do
    o.operations
    |> Enum.reverse
    |> Enum.reduce_while([], fn op, acc ->
    	Execute.run(op, o)
    	|> List.wrap
    	|> Enum.reduce_while({:cont, acc}, fn result, {_, acc} ->
        case result do
          {:error, _} = err -> {:halt, {:halt, [err | acc]}}
          {:ok, _} = ok     -> {:cont, {:cont, [ok  | acc]}}
        end
      end)
    end)
    |> Enum.reverse
  end
end
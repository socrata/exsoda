defmodule Exsoda.Archives do
  alias Exsoda.Http
  alias Exsoda.Runner
  alias Exsoda.Runner.{Operations, Execute}
  import Exsoda.Runner, only: [prepend: 2]

  defmodule StartJob do
    @enforce_keys [:fourfour, :data_version]
    defstruct @enforce_keys

    defimpl Execute, for: __MODULE__ do
      def run(%StartJob{fourfour: fourfour, data_version: data_version}, o) do
        Http.put("/archival/job/#{fourfour}/#{data_version}", o)
      end
    end
  end

  defmodule JobStatus do
    @enforce_keys [:fourfour, :data_version]
    defstruct @enforce_keys

    defimpl Execute, for: __MODULE__ do
      def run(%JobStatus{fourfour: fourfour, data_version: data_version}, o) do
        Http.get("/archival/job/#{fourfour}/#{data_version}", o)
      end
    end
  end

  def new(options \\ []), do: Runner.new(options)
  def run(operations), do: Runner.run(operations)
  def start_job(%Operations{} = o, fourfour, data_version) do
    prepend(%StartJob{fourfour: fourfour, data_version: data_version}, o)
  end
  def job_status(%Operations{} = o, fourfour, data_version) do
    prepend(%JobStatus{fourfour: fourfour, data_version: data_version}, o)
  end
end

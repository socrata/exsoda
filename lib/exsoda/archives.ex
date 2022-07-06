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
        q = URI.encode_query(%{
          method: "createArchive",
          id: fourfour,
          version: data_version
        })
        Http.put("/archival?#{q}", o)
      end
    end
  end

  defmodule JobStatus do
    @enforce_keys [:fourfour, :data_version]
    defstruct @enforce_keys

    defimpl Execute, for: __MODULE__ do
      def run(%JobStatus{fourfour: fourfour, data_version: data_version}, o) do
        q = URI.encode_query(%{
          method: "status",
          id: fourfour,
          version: data_version
        })
        Http.get("/archival?#{q}", o)
      end
    end
  end

  defmodule ListArchives do
    @enforce_keys [:fourfour]
    defstruct @enforce_keys

    defimpl Execute, for: __MODULE__ do
      def run(%ListArchives{fourfour: fourfour}, o) do
        q = URI.encode_query(%{
          id: fourfour
        })
        Http.get("/archival?#{q}", o)
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

  def list_archives(%Operations{} = o, fourfour) do
    prepend(%ListArchives{fourfour: fourfour}, o)
  end
end

defmodule Exsoda.Approvals do
  alias Exsoda.Http
  alias Exsoda.Runner
  alias Exsoda.Runner.{Operations, Execute}
  import Exsoda.Runner, only: [prepend: 2]


  defmodule Guidance do
    @enforce_keys [:fourfour, :catalog_revision_id]
    defstruct [:fourfour, :catalog_revision_id]

    defimpl Execute, for: __MODULE__ do
      def run(%Guidance{} = gu, o) do
        query = URI.encode_query(%{
            method: "guidance",
            assetId: gu.catalog_revision_id
        })
        Http.get("/views/#{Http.encode(gu.fourfour)}/approvals/?#{query}", o)
      end
    end
  end

  defmodule StartWorkflowSubmission do
    @enforce_keys [:fourfour, :submission]
    defstruct [:fourfour, :submission]

    defimpl Execute, for: __MODULE__ do
      def run(%StartWorkflowSubmission{} = sas, o) do
        with {:ok, json} <- Jason.encode(sas.submission) do
          Http.post("/views/#{Http.encode(sas.fourfour)}/approvals/?method=startWorkflowSubmission", o, json)
        end
      end
    end
  end

  defmodule DeleteApprovalsSubmissions do
    @enforce_keys [:fourfour, :catalog_revision_id]
    defstruct [:fourfour, :catalog_revision_id]

    defimpl Execute, for: __MODULE__ do
      def run(%DeleteApprovalsSubmissions{} = das, o) do
        Http.delete("/views/#{Http.encode(das.fourfour)}/approvals/#{Http.encode(das.catalog_revision_id)}?method=deleteExternalAssetSubmissions", o)
      end
    end
  end

  defmodule UpdateApprovalOutcomeStart do
    @enforce_keys [:fourfour, :submission_id]
    defstruct [:fourfour, :submission_id]

    defimpl Execute, for: __MODULE__ do
      def run(%UpdateApprovalOutcomeStart{} = uas, o) do
        Http.put("/views/#{Http.encode(uas.fourfour)}/approvals/#{Http.encode(uas.submission_id)}?method=updateOutcomeStart", o)
      end
    end
  end

  defmodule UpdateApprovalOutcomeEnd do
    @enforce_keys [:fourfour, :submission_id, :status]
    defstruct [:fourfour, :submission_id, :status]

    defimpl Execute, for: __MODULE__ do
      def run(%UpdateApprovalOutcomeEnd{} = uae, o) do
        query = URI.encode_query(%{
            method: "updateOutcomeEnd",
            status: uae.status
        })
        Http.put("/views/#{Http.encode(uae.fourfour)}/approvals/#{Http.encode(uae.submission_id)}?#{query}", o)
      end
    end
  end

  def new(options \\ []), do: Runner.new(options)
  def run(operations), do: Runner.run(operations)

  def guidance(%Operations{} = o, fourfour, revision_id) do
    prepend(%Guidance{fourfour: fourfour, catalog_revision_id: "#{fourfour}:#{revision_id}"}, o)
  end

  def start_workflow_submission(%Operations{} = o, fourfour, submission) do
    prepend(%StartWorkflowSubmission{fourfour: fourfour, submission: submission}, o)
  end

  def delete_approvals_submissions(%Operations{} = o, fourfour, revision_id) do
    prepend(%DeleteApprovalsSubmissions{fourfour: fourfour, catalog_revision_id: "#{fourfour}:#{revision_id}"}, o)
  end

  def update_approval_outcome_start(%Operations{} = o, fourfour, submission_id) do
    prepend(%UpdateApprovalOutcomeStart{fourfour: fourfour, submission_id: submission_id}, o)
  end

  def update_approval_outcome_end(%Operations{} = o, fourfour, submission_id, status) do
    prepend(%UpdateApprovalOutcomeEnd{fourfour: fourfour, submission_id: submission_id, status: status}, o)
  end
end

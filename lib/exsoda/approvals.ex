defmodule Exsoda.Approvals do
  alias Exsoda.Http

  defmodule Guidance do
    defstruct fourfour: nil,
    catalog_revision_id: nil
  end

  defmodule DeleteApprovalsSubmissions do
    defstruct fourfour: nil,
    catalog_revision_id: nil
  end

  defmodule UpdateApprovalOutcomeStart do
    defstruct fourfour: nil,
    submission_id: nil
  end

  defmodule UpdateApprovalOutcomeEnd do
    defstruct fourfour: nil,
    submission_id: nil,
    status: nil
  end

  def guidance(fourfour, revision_id) do
    %Guidance{fourfour: fourfour, catalog_revision_id: "#{fourfour}:#{revision_id}"}
  end

  def delete_approvals_submissions(%Write{} = w, fourfour, revision_id) do
    operation = %DeleteApprovalsSubmissions{fourfour: fourfour, catalog_revision_id: "#{fourfour}:#{revision_id}"}
    %{ w | operations: [operation | w.operations] }
  end

  def update_approval_outcome_start(%Write{} = w, fourfour, submission_id) do
    operation = %UpdateApprovalOutcomeStart{fourfour: fourfour, submission_id: submission_id}
    %{ w | operations: [operation | w.operations] }
  end

  def update_approval_outcome_end(%Write{} = w, fourfour, submission_id, status) do
    operation = %UpdateApprovalOutcomeEnd{fourfour: fourfour, submission_id: submission_id, status: status}
    %{ w | operations: [operation | w.operations] }
  end

  def run(%Guidance{fourfour: fourfour, catalog_revision_id: catalog_revision_id} = q) do
    query = URI.encode_query(%{
        method: "guidance"
        assetId: catalog_revision_id
    })
    Http.get("/views/#{Http.encode(fourfour)}/approvals/?#{query}", q)
  end

  defp do_run(%DeleteApprovalsSubmissions{} = das, w) do
    Http.delete("/views/#{Http.encode(das.fourfour)}/approvals/#{Http.encode(das.catalog_revision_id)}?method=deleteExternalAssetSubmissions", w)
  end

  defp do_run(%UpdateApprovalOutcomeStart{} = uas, w) do
    with {:ok, json} <- Poison.encode(%{}) do
      Http.put("/views/#{Http.encode(uas.fourfour)}/approvals/#{Http.encode(uas.submission_id)}?method=updateOutcomeStart", w, json)
    end
  end

  defp do_run(%UpdateApprovalOutcomeEnd{} = uae, w) do
    with {:ok, json} <- Poison.encode(%{}) do
      Http.put("/views/#{Http.encode(uae.fourfour)}/approvals/#{Http.encode(uae.submission_id)}?method=updateOutcomeEnd&status=#{Http.encode(uae.status)}", w, json)
    end
  end
end

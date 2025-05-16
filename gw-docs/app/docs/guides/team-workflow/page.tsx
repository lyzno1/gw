import type { Metadata } from "next"
import { useTranslation } from "@/hooks/use-translation"
import { DocContent } from "@/components/doc-content"

export const metadata: Metadata = {
  title: "Team Workflow | GW Documentation",
  description: "Learn how to use GW in a team environment",
}

export default function TeamWorkflowPage() {
  const { t } = useTranslation()

  return (
    <DocContent title={t("sidebar.teamWorkflow")} description="Best practices for using GW in a team environment">
      <div className="space-y-10">
        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Standardizing Workflows</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            One of GW's key benefits is standardizing Git workflows across your team. This reduces confusion, minimizes
            errors, and makes onboarding new team members easier.
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Team Adoption Steps</h3>
          <ol className="my-6 ml-6 list-decimal [&>li]:mt-2">
            <li>Install GW for all team members</li>
            <li>Create a team workflow document based on GW commands</li>
            <li>Conduct a brief training session</li>
            <li>Set up CI checks to enforce workflow standards</li>
          </ol>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Feature Branch Workflow</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            A common team workflow using GW follows the feature branch model, where each feature, bugfix, or task is
            developed in its own branch.
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Workflow Steps</h3>
          <ol className="my-6 ml-6 list-decimal [&>li]:mt-2">
            <li>
              <strong>Start a feature:</strong> <code>gw start feature/new-feature</code>
            </li>
            <li>
              <strong>Make changes and commit regularly:</strong> <code>gw save -m "Add feature X"</code>
            </li>
            <li>
              <strong>Keep in sync with main:</strong> <code>gw update</code> (daily)
            </li>
            <li>
              <strong>Push changes for backup or sharing:</strong> <code>gw push</code>
            </li>
            <li>
              <strong>Submit for review:</strong> <code>gw submit --pr</code>
            </li>
            <li>
              <strong>Address review feedback:</strong> Make changes, <code>gw save</code>, <code>gw push</code>
            </li>
            <li>
              <strong>After merge, clean up:</strong> <code>gw clean feature/new-feature</code>
            </li>
          </ol>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Code Review Process</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            GW can streamline your code review process by ensuring branches are properly prepared before review.
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Pre-Review Checklist</h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>
              Update branch with latest main: <code>gw update</code>
            </li>
            <li>Ensure all tests pass</li>
            <li>Clean up commit history if needed</li>
            <li>
              Submit with descriptive PR title: <code>gw submit --pr</code>
            </li>
          </ul>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Reviewer Workflow</h3>
          <ol className="my-6 ml-6 list-decimal [&>li]:mt-2">
            <li>
              Check out the PR branch: <code>gw checkout feature/to-review</code>
            </li>
            <li>Review code, run tests, etc.</li>
            <li>Provide feedback on the PR</li>
            <li>Approve and merge when ready</li>
          </ol>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Release Management</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            GW can help manage releases by providing a consistent workflow for release branches.
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Release Branch Workflow</h3>
          <ol className="my-6 ml-6 list-decimal [&>li]:mt-2">
            <li>
              Create a release branch: <code>gw start release/v1.0.0</code>
            </li>
            <li>
              Make final adjustments: <code>gw save -m "Prepare v1.0.0 release"</code>
            </li>
            <li>
              Tag the release: <code>git tag -a v1.0.0 -m "Version 1.0.0"</code>
            </li>
            <li>
              Push the tag: <code>git push origin v1.0.0</code>
            </li>
            <li>
              Merge back to main: <code>gw checkout main && gw merge release/v1.0.0</code>
            </li>
            <li>
              Clean up: <code>gw clean release/v1.0.0</code>
            </li>
          </ol>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Handling Hotfixes</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            When critical issues need to be fixed in production, GW provides a consistent hotfix workflow.
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Hotfix Workflow</h3>
          <ol className="my-6 ml-6 list-decimal [&>li]:mt-2">
            <li>
              Create a hotfix branch from the production tag:{" "}
              <code>git checkout v1.0.0 && gw start hotfix/critical-bug</code>
            </li>
            <li>
              Fix the issue: <code>gw save -m "Fix critical bug"</code>
            </li>
            <li>
              Create a new patch version tag: <code>git tag -a v1.0.1 -m "Version 1.0.1"</code>
            </li>
            <li>
              Push the fix and tag: <code>gw push && git push origin v1.0.1</code>
            </li>
            <li>
              Merge back to main: <code>gw checkout main && gw merge hotfix/critical-bug</code>
            </li>
            <li>
              Clean up: <code>gw clean hotfix/critical-bug</code>
            </li>
          </ol>
        </div>
      </div>
    </DocContent>
  )
}

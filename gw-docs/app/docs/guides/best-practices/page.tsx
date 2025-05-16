import type { Metadata } from "next"
import { useTranslation } from "@/hooks/use-translation"
import { DocContent } from "@/components/doc-content"

export const metadata: Metadata = {
  title: "Best Practices | GW Documentation",
  description: "Learn about best practices when using GW",
}

export default function BestPracticesPage() {
  const { t } = useTranslation()

  return (
    <DocContent title={t("sidebar.bestPractices")} description="Recommended practices for getting the most out of GW">
      <div className="space-y-10">
        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Branch Naming Conventions</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Consistent branch naming helps team members understand the purpose of each branch at a glance.
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Recommended Pattern</h3>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">&lt;type&gt;/&lt;description&gt;</code>
          </pre>
          <p className="leading-7 [&:not(:first-child)]:mt-6">Common types include:</p>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>
              <code>feature</code>: New functionality
            </li>
            <li>
              <code>bugfix</code>: Bug fixes
            </li>
            <li>
              <code>hotfix</code>: Urgent fixes for production
            </li>
            <li>
              <code>refactor</code>: Code improvements without changing functionality
            </li>
            <li>
              <code>docs</code>: Documentation changes
            </li>
            <li>
              <code>test</code>: Adding or improving tests
            </li>
          </ul>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Examples</h3>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              gw start feature/user-authentication gw start bugfix/login-error gw start refactor/api-client
            </code>
          </pre>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Commit Message Guidelines</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Well-structured commit messages make your repository history more useful and readable.
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Conventional Commits</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">Consider using the Conventional Commits format:</p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">&lt;type&gt;[(scope)]: &lt;description&gt;</code>
          </pre>
          <p className="leading-7 [&:not(:first-child)]:mt-6">For example:</p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              gw save -m "feat(auth): implement OAuth login" gw save -m "fix(ui): correct button alignment on mobile" gw
              save -m "docs: update installation instructions"
            </code>
          </pre>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Commit Message Structure</h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>Use the imperative mood ("Add feature" not "Added feature")</li>
            <li>Keep the first line under 50 characters</li>
            <li>Add detailed explanation in the commit body if needed</li>
            <li>Reference issue numbers when applicable</li>
          </ul>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Regular Updates</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Keeping your feature branches up to date with the main branch reduces merge conflicts and integration
            issues.
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Update Frequency</h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>Update your feature branch at least once a day</li>
            <li>Always update before submitting a pull request</li>
            <li>Update after significant changes to the main branch</li>
          </ul>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              # Start your day by updating your branch gw update # Before submitting your work gw update && gw submit
              --pr
            </code>
          </pre>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Clean History</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Maintaining a clean, linear history makes it easier to understand the project's evolution and find bugs.
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Tips for Clean History</h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>Use GW's default rebase strategy when updating branches</li>
            <li>
              Consider squashing commits before merging to main (e.g., <code>gw submit --squash</code>)
            </li>
            <li>Keep commits focused on a single logical change</li>
            <li>Use interactive rebase to clean up your branch before submitting</li>
          </ul>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Example Workflow</h3>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              # Make multiple small commits while working gw save -m "WIP: initial implementation" # ... more work ...
              gw save -m "WIP: fix edge case" # Clean up commits before submitting git rebase -i HEAD~3 # Submit with
              clean history gw submit --pr
            </code>
          </pre>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Branch Cleanup</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Regularly cleaning up merged branches keeps your repository tidy and focused.
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Cleanup Strategies</h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>Clean up branches immediately after they're merged</li>
            <li>Periodically review and clean up all merged branches</li>
            <li>Consider using automatic branch deletion after merge</li>
          </ul>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              # Clean up a specific branch gw clean feature/completed-feature # Clean up all merged branches gw rm all #
              Submit with automatic branch deletion gw submit --pr --delete-branch-after-merge
            </code>
          </pre>
        </div>
      </div>
    </DocContent>
  )
}

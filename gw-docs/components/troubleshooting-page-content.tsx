"use client";

import { useTranslation } from "@/hooks/use-translation";
import { DocContent } from "@/components/doc-content";

interface TroubleshootingPageContentProps {
  // lang: string;
}

export function TroubleshootingPageContent(props: TroubleshootingPageContentProps) {
  const { t } = useTranslation();

  return (
    <DocContent title={t("sidebar.troubleshooting")} description="Solutions for common issues when using GW">
      <div className="space-y-10">
        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Common Issues</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Here are solutions to some common issues you might encounter when using GW.
          </p>

          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Command Not Found</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            If you see "command not found" when trying to use GW, check your installation:
          </p>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>
              Verify that the script has execute permissions: <code>{'chmod +x /path/to/git_workflow.sh'}</code>
            </li>
            <li>Check that your alias is correctly set in your shell configuration file</li>
            <li>
              Make sure you've sourced your updated shell configuration: <code>{'source ~/.bashrc'}</code> or{" "}
              <code>{'source ~/.zshrc'}</code>
            </li>
          </ul>

          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Merge Conflicts</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            When <code>gw update</code> results in merge conflicts:
          </p>
          <ol className="my-6 ml-6 list-decimal [&>li]:mt-2">
            <li>Resolve the conflicts in your editor</li>
            <li>
              Mark files as resolved: <code>{'git add <resolved-files>'}</code>
            </li>
            <li>
              Continue the rebase: <code>gw rebase --continue</code>
            </li>
            <li>
              If you need to abort: <code>gw rebase --abort</code>
            </li>
          </ol>

          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Network Issues</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            If you're experiencing network-related failures despite GW's retry mechanism:
          </p>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>Check your internet connection</li>
            <li>Verify your SSH keys or credentials are set up correctly</li>
            <li>
              Try increasing the retry count: <code>{'export MAX_ATTEMPTS=5'}</code> before running GW commands
            </li>
            <li>Check if you can access the remote repository directly with Git</li>
          </ul>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Recovering from Mistakes</h2>

          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Undoing the Last Commit</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">If you need to undo your last commit:</p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              {'# Keep changes in working directory\ngw undo\n# Keep changes staged\ngw undo --soft\n# Discard changes completely\ngw undo --hard'}
            </code>
          </pre>

          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Recovering Deleted Branches</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">If you accidentally deleted a branch:</p>
          <ol className="my-6 ml-6 list-decimal [&>li]:mt-2">
            <li>
              Find the commit hash of the branch tip: <code>git reflog</code>
            </li>
            <li>
              Recreate the branch: <code>{'git checkout -b branch-name <commit-hash>'}</code>
            </li>
          </ol>

          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Fixing a Bad Rebase</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">If a rebase went wrong and you need to start over:</p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              {'# Find the commit hash before the rebase\ngit reflog\n# Reset to that commit\ngit reset --hard <commit-hash>'}
            </code>
          </pre>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Environment Variables</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            GW's behavior can be customized with environment variables:
          </p>

          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Available Variables</h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>
              <code>MAIN_BRANCH</code>: Default main branch name (default: main or master)
            </li>
            <li>
              <code>REMOTE_NAME</code>: Default remote name (default: origin)
            </li>
            <li>
              <code>MAX_ATTEMPTS</code>: Number of retry attempts for network operations (default: 3)
            </li>
            <li>
              <code>DELAY_SECONDS</code>: Delay between retry attempts in seconds (default: 2)
            </li>
          </ul>

          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Setting Variables</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            You can set these variables in your shell configuration file or before running a command:
          </p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              {'# In your .bashrc or .zshrc\nexport MAIN_BRANCH="develop"\nexport MAX_ATTEMPTS=5\n# Or for a single command\nMAIN_BRANCH="develop" gw start feature/new-feature'}
            </code>
          </pre>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Debugging GW</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">If you need to troubleshoot GW itself:</p>

          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Enable Debug Mode</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">Run GW with bash's debug mode to see what's happening:</p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">{'bash -x /path/to/git_workflow.sh command [args...]'}</code>
          </pre>

          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Check GW Configuration</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">View your current GW configuration:</p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">{'gw config list'}</code>
          </pre>

          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Check Script Permissions</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">Ensure all scripts have the correct permissions:</p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              {'ls -la /path/to/gw/git_workflow.sh\nls -la /path/to/gw/actions/\nls -la /path/to/gw/core_utils/'}
            </code>
          </pre>
        </div>
      </div>
    </DocContent>
  );
}
import type { Metadata } from "next"
// import { useTranslation } from "@/hooks/use-translation" // Removed
import { DocContent } from "@/components/doc-content"

// export const metadata: Metadata = { // Temporarily commented out
//   title: "Extending GW | GW Documentation",
//   description: "Learn how to extend GW with custom commands and functionality",
// }

export default function ExtendingPage({ params }: { params: { lang: string } }) { // Added params
  // const { t } = useTranslation() // Removed

  // TODO: Replace with server-side translation later
  const title = params.lang === 'zh' ? "扩展 GW" : "Extending GW";

  return (
    <DocContent
      title={title} // Used placeholder/static title
      description="Extend GW with custom commands and functionality"
    >
      <div className="space-y-10">
        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Adding Custom Commands</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            GW's modular design makes it easy to add your own custom commands.
          </p>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Creating a Command File</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Create a new file in the <code>actions/</code> directory:
          </p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              {'#!/bin/bash\n# File: actions/my_custom_command.sh\n# ... (rest of script content)'}
            </code>
          </pre>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Registering the Command</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Add your command to <code>git_workflow.sh</code>:
          </p>
          <ol className="my-6 ml-6 list-decimal [&>li]:mt-2">
            <li>Source your command file near the top with the other actions</li>
            <li>Add your command to the case statement in the main function</li>
          </ol>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              {'# In git_workflow.sh\n# 1. Source your command file\n# ... (rest of script content)'}
            </code>
          </pre>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Making It Executable</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Make your command file executable:
          </p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">{'chmod +x actions/my_custom_command.sh'}</code>
          </pre>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Using Your Command</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Now you can use your custom command:
          </p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">{'gw custom [parameters]'}</code>
          </pre>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Command Best Practices</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Follow these best practices when creating custom commands:
          </p>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Structure and Documentation</h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>Start with a clear comment header explaining the command's purpose</li>
            <li>List dependencies and required environment</li>
            <li>Use the <code>cmd_</code> prefix for your main function</li>
            <li>Add your command to the help text in <code>actions/show_help.sh</code></li>
          </ul>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Error Handling</h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>Check for required parameters</li>
            <li>Validate input before proceeding</li>
            <li>Use the utility functions for common checks</li>
            <li>Provide clear error messages</li>
            <li>Return appropriate exit codes</li>
          </ul>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              {'# Example error handling\n# ... (rest of script content)'}
            </code>
          </pre>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">User Feedback</h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>Use color coding consistently (see <code>core_utils/colors.sh</code>)</li>
            <li>Provide progress information for long-running operations</li>
            <li>Confirm successful completion</li>
            <li>Consider adding a --verbose flag for detailed output</li>
          </ul>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Utility Functions</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            GW provides several utility functions you can use in your custom commands.
          </p>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Common Utilities</h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li><code>check_git_repo</code>: Ensures the current directory is a Git repository</li>
            <li><code>check_remote_exists</code>: Checks if a remote exists</li>
            <li><code>check_branch_exists</code>: Verifies if a branch exists</li>
            <li><code>get_current_branch</code>: Gets the name of the current branch</li>
            <li><code>has_uncommitted_changes</code>: Checks for uncommitted changes</li>
            <li><code>confirm_action</code>: Prompts the user for confirmation</li>
          </ul>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Example Usage</h3>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              {'# Check if we\'re in a Git repo\n# ... (rest of script content)'}
            </code>
          </pre>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Advanced Extensions</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Beyond simple commands, you can extend GW in more advanced ways.
          </p>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Git Hooks Integration</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Create commands that install or manage Git hooks:
          </p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              {'cmd_install_hooks() {\n# ... (rest of script content)\n}'}
            </code>
          </pre>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Project Templates</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Create commands for initializing projects with standard files:
          </p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              {'cmd_init_project() {\n# ... (rest of script content)\n}'}
            </code>
          </pre>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Integration with Other Tools</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Create
            {/* Ensure the rest of the content is here if any, or close tags properly */}
          </p>
        </div>
      </div>
    </DocContent>
  );
}

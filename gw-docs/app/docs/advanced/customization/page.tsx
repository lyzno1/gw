import type { Metadata } from "next"
import { useTranslation } from "@/hooks/use-translation"
import { DocContent } from "@/components/doc-content"

export const metadata: Metadata = {
  title: "Customization | GW Documentation",
  description: "Learn how to customize GW for your specific needs",
}

export default function CustomizationPage() {
  const { t } = useTranslation()

  return (
    <DocContent
      title={t("sidebar.customization")}
      description="Customize GW to fit your team's specific workflow needs"
    >
      <div className="space-y-10">
        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Configuration Options</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            GW can be customized through environment variables and configuration files to match your team's workflow.
          </p>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Environment Variables</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Set these in your shell configuration file (.bashrc, .zshrc) for persistent customization:
          </p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              # Main branch name (default: main or master) export MAIN_BRANCH="develop" # Default remote name (default:
              origin) export REMOTE_NAME="upstream" # Network retry settings export MAX_ATTEMPTS=5 export
              DELAY_SECONDS=3
            </code>
          </pre>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Editor Configuration</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Configure your preferred editor for commit messages:
          </p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              # Set VS Code as your editor gw ide vscode # Set Vim as your editor gw ide vim # Set a custom editor
              command gw ide "code --wait"
            </code>
          </pre>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Customizing Core Files</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            For more advanced customization, you can modify GW's core files directly.
          </p>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Configuration Variables</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Edit <code>core_utils/config_vars.sh</code> to change default settings:
          </p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              # Example modifications # Change default branch name DEFAULT_MAIN_BRANCH="develop" # Change default remote
              DEFAULT_REMOTE_NAME="upstream" # Modify retry behavior DEFAULT_MAX_ATTEMPTS=5 DEFAULT_DELAY_SECONDS=3
            </code>
          </pre>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Command Behavior</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Modify command implementations in the <code>actions/</code> directory:
          </p>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li><code>actions/start_branch.sh</code>: Customize branch creation behavior</li>
            <li><code>actions/save_changes.sh</code>: Modify how changes are saved</li>
            <li><code>actions/update_branch.sh</code>: Change how branches are updated</li>
            <li><code>actions/submit_work.sh</code>: Customize the submission process</li>
          </ul>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Always make a backup before modifying these files!
          </p>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Custom Commit Templates</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Create custom commit message templates to standardize your team's commit messages.
          </p>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Creating a Template</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Create a file with your template:
          </p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              # ~/.gitmessage.txt # &lt;type&gt;(&lt;scope&gt;): &lt;subject&gt; # # [optional body] # #
              [optional footer(s)] # # Types: feat, fix, docs, style, refactor, test, chore # Scope: component affected
              # Subject: imperative, start with lowercase, no period at end # # Example: feat(auth): add OAuth login
              functionality
            </code>
          </pre>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Configuring Git to Use the Template</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Set up Git to use your template:
          </p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">git config --global commit.template ~/.gitmessage.txt</code>
          </pre>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Now when you run <code>gw save</code> without a message, your template will be used.
          </p>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Project-Specific Configuration</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            You can create project-specific GW configurations using Git hooks and local environment variables.
          </p>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Using .env Files</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Create a <code>.env.gw</code> file in your project root:
          </p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              # .env.gw MAIN_BRANCH=develop REMOTE_NAME=upstream MAX_ATTEMPTS=5
            </code>
          </pre>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Then source this file in your project's Git hooks or in a project-specific alias:
          </p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              # In .git/hooks/post-checkout or in your shell config if [ -f .env.gw ]; then source .env.gw fi
            </code>
          </pre>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Custom Aliases</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Create custom aliases for common GW command combinations.
          </p>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Shell Aliases</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Add these to your shell configuration file:
          </p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              # Quick feature branch creation alias gwf='gw start feature/' # Update and submit alias gws='gw update &&
              gw submit --pr' # Clean all merged branches alias gwc='gw checkout main && gw update && gw rm all'
            </code>
          </pre>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Git Aliases</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            You can also create Git aliases that use GW:
          </p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              git config --global alias.feature \'!f() { gw start feature/$1; }; f'
              git config --global alias.submit '!gw submit --pr'
            </code>
          </pre>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Then use them like: <code>git feature login-page</code>
          </p>
        </div>
      </div>
    </DocContent>
  )
}

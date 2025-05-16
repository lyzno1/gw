"use client";

import { useTranslation } from "@/hooks/use-translation";
import { DocContent } from "@/components/doc-content";
// CodeBlock is used implicitly by the raw HTML in the original file,
// but for a cleaner refactor, we'd ideally pass structured data to CodeBlock instances.
// For now, we'll keep the pre/code structure and assume raw HTML for code examples.
// If CodeBlock component is intended, this needs to be refactored further.

interface RepoManagementPageContentProps {
  // lang: string;
}

export function RepoManagementPageContent(props: RepoManagementPageContentProps) {
  const { t } = useTranslation();

  return (
    <DocContent title={t("sidebar.repoManagement")} description="Commands for managing repositories and configuration">
      <div className="space-y-10">
        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">gw init</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">Initializes a Git repository with enhanced setup.</p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Syntax</h3>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">{'gw init [...]'}</code>
          </pre>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Options</h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>
              <code>{'[...]'}</code>: Any options passed to git init
            </li>
          </ul>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Examples</h3>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              {'# Initialize a repository in current directory gw init # Initialize with specific branch name gw init\n--initial-branch=main'}
            </code>
          </pre>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">gw config set-url</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Sets the URL for a remote repository, adding it if it doesn't exist.
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Syntax</h3>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">{'gw config set-url <url>\ngw config set-url <name> <url>'}</code>
          </pre>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Examples</h3>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              {'# Set URL for origin gw config set-url https://github.com/username/repo.git # Set URL for a specific\nremote gw config set-url upstream https://github.com/original/repo.git'}
            </code>
          </pre>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">gw config add-remote</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">Adds a new remote repository.</p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Syntax</h3>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">{'gw config add-remote <name> <url>'}</code>
          </pre>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Examples</h3>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              {'# Add a new remote gw config add-remote upstream https://github.com/original/repo.git'}
            </code>
          </pre>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">gw gh-create</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Creates a repository on GitHub and associates it with the local repository.
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Syntax</h3>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">{'gw gh-create [repo] [...]'}</code>
          </pre>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Requirements</h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>GitHub CLI (gh) must be installed and authenticated</li>
          </ul>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Examples</h3>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              {'# Create a public repository with the current directory name gw gh-create # Create a repository with a\nspecific name gw gh-create my-awesome-project # Create a private repository gw gh-create --private'}
            </code>
          </pre>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">gw ide</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Sets or displays the default editor used by 'gw save' when editing commit messages.
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Syntax</h3>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">{'gw ide [name|cmd]'}</code>
          </pre>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Options</h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>
              <code>{'[name]'}</code>: Predefined editor short name (e.g., vscode, vim, nano)
            </li>
            <li>
              <code>{'[cmd]'}</code>: Full editor command (e.g., "code --wait")
            </li>
          </ul>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Examples</h3>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              {'# Show current editor setting gw ide # Set editor to VS Code gw ide vscode # Set editor to Vim gw ide vim\n# Set custom editor command gw ide "subl -w"'}
            </code>
          </pre>
        </div>
      </div>
    </DocContent>
  );
}
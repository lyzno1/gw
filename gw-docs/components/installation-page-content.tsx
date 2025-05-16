"use client";

import { useTranslation } from "@/hooks/use-translation";
import { DocContent } from "@/components/doc-content";

interface InstallationPageContentProps {
  // lang: string;
}

export function InstallationPageContent(props: InstallationPageContentProps) {
  const { t } = useTranslation();

  return (
    <DocContent title={t("sidebar.installation")} description="Complete guide to installing GW on your system">
      <h2 className="mt-10 scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Prerequisites</h2>
      <p className="leading-7 [&:not(:first-child)]:mt-6">Before installing GW, make sure you have the following:</p>
      <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
        <li>Git installed on your system</li>
        <li>Bash or Zsh shell</li>
        <li>(Optional) GitHub CLI for PR-related features</li>
      </ul>

      <h2 className="mt-10 scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">
        Step 1: Clone the Repository
      </h2>
      <p className="leading-7 [&:not(:first-child)]:mt-6">First, clone the GW repository to your local machine:</p>
      <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
        <code className="text-white">{'git clone https://github.com/lyzno1/gw.git'}</code>
      </pre>

      <h2 className="mt-10 scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">
        Step 2: Make Scripts Executable
      </h2>
      <p className="leading-7 [&:not(:first-child)]:mt-6">
        Navigate to the GW directory and make the scripts executable:
      </p>
      <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
        <code className="text-white">
          {`cd gw
chmod +x git_workflow.sh
chmod +x actions/*.sh`}
        </code>
      </pre>

      <h2 className="mt-10 scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">
        Step 3: Add to PATH or Create Alias
      </h2>
      <p className="leading-7 [&:not(:first-child)]:mt-6">
        You have two options to make GW available from anywhere in your terminal:
      </p>

      <h3 className="mt-8 scroll-m-20 text-xl font-semibold tracking-tight">Option A: Add to PATH</h3>
      <p className="leading-7 [&:not(:first-child)]:mt-6">
        Edit your shell configuration file (~/.bashrc, ~/.zshrc, or ~/.profile) and add:
      </p>
      <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
        <code className="text-white">{'export PATH="/path/to/your/gw:$PATH"'}</code>
      </pre>
      <p className="leading-7 [&:not(:first-child)]:mt-6">
        Replace "/path/to/your/gw" with the actual path to your GW directory.
      </p>

      <h3 className="mt-8 scroll-m-20 text-xl font-semibold tracking-tight">Option B: Create Alias (Recommended)</h3>
      <p className="leading-7 [&:not(:first-child)]:mt-6">Edit your shell configuration file and add:</p>
      <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
        <code className="text-white">{'alias gw="/path/to/your/gw/git_workflow.sh"'}</code>
      </pre>
      <p className="leading-7 [&:not(:first-child)]:mt-6">
        Replace "/path/to/your/gw/git_workflow.sh" with the actual path to the git_workflow.sh file.
      </p>

      <h2 className="mt-10 scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Step 4: Apply Changes</h2>
      <p className="leading-7 [&:not(:first-child)]:mt-6">Apply the changes to your current shell session:</p>
      <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
        <code className="text-white">{'source ~/.bashrc # or ~/.zshrc depending on your shell'}</code>
      </pre>

      <h2 className="mt-10 scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">
        Step 5: Verify Installation
      </h2>
      <p className="leading-7 [&:not(:first-child)]:mt-6">Verify that GW is installed correctly:</p>
      <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
        <code className="text-white">{'gw help'}</code>
      </pre>
      <p className="leading-7 [&:not(:first-child)]:mt-6">
        If you see the help information, GW is installed correctly!
      </p>

      <h2 className="mt-10 scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">
        Optional: Install Dependencies
      </h2>
      <p className="leading-7 [&:not(:first-child)]:mt-6">
        For full functionality, consider installing these optional dependencies:
      </p>
      <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
        <li>
          <strong>GitHub CLI (gh)</strong>: Required for <code>{'gw gh-create'}</code> and <code>{'gw submit --pr'}</code>{" "}
          features.
          <pre className="my-2 overflow-x-auto rounded-lg bg-slate-900 p-2">
            <code className="text-white">
              {'# Install GitHub CLI - see https://cli.github.com/ for more options\n# macOS\nbrew install gh\n# Ubuntu/Debian\nsudo apt install gh'}
            </code>
          </pre>
        </li>
        <li>
          <strong>GNU getopt</strong>: Recommended on macOS for full long option support.
          <pre className="my-2 overflow-x-auto rounded-lg bg-slate-900 p-2">
            <code className="text-white">
              {'# macOS\nbrew install gnu-getopt\n# Add to PATH in your shell config file\nexport PATH="/usr/local/opt/gnu-getopt/bin:$PATH"'}
            </code>
          </pre>
        </li>
      </ul>
    </DocContent>
  );
}
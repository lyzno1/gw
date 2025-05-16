"use client";

import Link from "next/link"; // Import Link for internal navigation
import { useTranslation } from "@/hooks/use-translation";
import { DocContent } from "@/components/doc-content";

interface QuickStartPageContentProps {
  lang: string; // Expect lang to be passed for link construction
}

export function QuickStartPageContent({ lang }: QuickStartPageContentProps) {
  const { t } = useTranslation();

  return (
    <DocContent title={t("sidebar.quickStart")} description="Learn the basic workflow with GW in minutes">
      <h2 className="mt-10 scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Basic Workflow</h2>
      <p className="leading-7 [&:not(:first-child)]:mt-6">Here's a typical development workflow using GW:</p>

      <h3 className="mt-8 scroll-m-20 text-xl font-semibold tracking-tight">1. Start a new feature</h3>
      <p className="leading-7 [&:not(:first-child)]:mt-6">
        Begin working on a new feature by creating a new branch from the main branch:
      </p>
      <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
        <code className="text-white">{'gw start feature/my-awesome-feature'}</code>
      </pre>
      <p className="leading-7 [&:not(:first-child)]:mt-6">This command will:</p>
      <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
        <li>Stash any uncommitted changes if needed</li>
        <li>Switch to the main branch</li>
        <li>Pull the latest changes</li>
        <li>Create and switch to your new feature branch</li>
        <li>Apply your stashed changes if any were stashed</li>
      </ul>

      <h3 className="mt-8 scroll-m-20 text-xl font-semibold tracking-tight">2. Make changes and save your work</h3>
      <p className="leading-7 [&:not(:first-child)]:mt-6">After making changes to your code, save your work:</p>
      <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
        <code className="text-white">{'gw save -m "Add new feature X"'}</code>
      </pre>
      <p className="leading-7 [&:not(:first-child)]:mt-6">Or use the interactive commit message editor:</p>
      <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
        <code className="text-white">{'gw save'}</code>
      </pre>

      <h3 className="mt-8 scroll-m-20 text-xl font-semibold tracking-tight">3. Keep your branch up to date</h3>
      <p className="leading-7 [&:not(:first-child)]:mt-6">
        Regularly update your branch with changes from the main branch:
      </p>
      <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
        <code className="text-white">{'gw update'}</code>
      </pre>

      <h3 className="mt-8 scroll-m-20 text-xl font-semibold tracking-tight">4. Save and push in one step</h3>
      <p className="leading-7 [&:not(:first-child)]:mt-6">
        When you want to save your changes and push them to the remote repository:
      </p>
      <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
        <code className="text-white">{'gw sp -m "Complete feature implementation"'}</code>
      </pre>

      <h3 className="mt-8 scroll-m-20 text-xl font-semibold tracking-tight">5. Submit your work</h3>
      <p className="leading-7 [&:not(:first-child)]:mt-6">When your feature is complete and ready for review:</p>
      <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
        <code className="text-white">{'gw submit --pr'}</code>
      </pre>
      <p className="leading-7 [&:not(:first-child)]:mt-6">This will:</p>
      <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
        <li>Save any uncommitted changes</li>
        <li>Push your branch to the remote repository</li>
        <li>Create a pull request (if --pr is specified and gh CLI is installed)</li>
        <li>Switch back to the main branch</li>
      </ul>

      <h3 className="mt-8 scroll-m-20 text-xl font-semibold tracking-tight">6. Clean up</h3>
      <p className="leading-7 [&:not(:first-child)]:mt-6">After your feature branch has been merged, clean it up:</p>
      <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
        <code className="text-white">{'gw clean feature/my-awesome-feature'}</code>
      </pre>
      <p className="leading-7 [&:not(:first-child)]:mt-6">
        This will switch to the main branch, update it, and delete the feature branch both locally and remotely (after
        confirmation).
      </p>

      <h2 className="mt-10 scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Common Scenarios</h2>

      <h3 className="mt-8 scroll-m-20 text-xl font-semibold tracking-tight">Check repository status</h3>
      <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
        <code className="text-white">{'gw status'}</code>
      </pre>

      <h3 className="mt-8 scroll-m-20 text-xl font-semibold tracking-tight">View branch information</h3>
      <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
        <code className="text-white">{'gw branch'}</code>
      </pre>

      <h3 className="mt-8 scroll-m-20 text-xl font-semibold tracking-tight">Switch branches</h3>
      <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
        <code className="text-white">{'gw checkout another-branch'}</code>
      </pre>

      <h3 className="mt-8 scroll-m-20 text-xl font-semibold tracking-tight">Undo last commit</h3>
      <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
        <code className="text-white">{'gw undo'}</code>
      </pre>

      <h2 className="mt-10 scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Next Steps</h2>
      <p className="leading-7 [&:not(:first-child)]:mt-6">
        Now that you're familiar with the basic workflow, explore the{" "}
        <Link href={`/${lang}/docs/commands`} className="text-primary underline">
          complete command reference
        </Link>{" "}
        to learn about all the available commands and options.
      </p>
    </DocContent>
  );
}
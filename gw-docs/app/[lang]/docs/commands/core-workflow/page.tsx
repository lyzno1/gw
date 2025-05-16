import type { Metadata } from "next";
// import { useTranslation } from "@/hooks/use-translation"; // Removed
// import { DocContent } from "@/components/doc-content"; // Handled by CoreWorkflowPageContent
// import { CodeBlock } from "@/components/code-block"; // Handled by CoreWorkflowPageContent
import { CoreWorkflowPageContent } from "@/components/core-workflow-page-content";

// export const metadata: Metadata = { // Temporarily commented out
//   title: "Core Workflow Commands | GW Documentation",
//   description: "Learn about the core workflow commands in GW",
// };

export default function CoreWorkflowPage({ params }: { params: { lang: string } }) { // Added params
  // const { t, locale } = useTranslation(); // Removed

  const startExamples = `# Create a new feature branch based on main
gw start feature/new-login-page

# Create a new branch based on a specific branch
gw start bugfix/login-issue --base release/v1.0

# Create a new branch without pulling latest changes
gw start hotfix/critical-bug --local`;

  const saveExamples = `# Save all changes with a message
gw save -m "Add login form validation"

# Save specific files
gw save -m "Update README" README.md docs/installation.md

# Open editor for commit message
gw save -e`;

  const updateExample = `# Update current branch with latest changes
gw update`;

  const submitExamples = `# Submit changes and stay on current branch
gw submit --no-switch

# Submit changes and create a PR
gw submit --pr

# Submit, create PR, and auto-merge when CI passes
gw submit --pr --auto-merge`;

  const rmExamples = `# Delete a specific branch
gw rm feature/old-feature

# Force delete a branch with unmerged changes
gw rm feature/abandoned-feature -f

# Delete all merged branches
gw rm all`;

  const cleanExample = `# Clean up a feature branch
gw clean feature/completed-feature`;

  return (
    <CoreWorkflowPageContent
      // lang={params.lang} // Pass lang if CoreWorkflowPageContent is adapted
      startExamples={startExamples}
      saveExamples={saveExamples}
      updateExample={updateExample}
      submitExamples={submitExamples}
      rmExamples={rmExamples}
      cleanExample={cleanExample}
    />
  );
}

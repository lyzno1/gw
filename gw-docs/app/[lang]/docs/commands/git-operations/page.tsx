import type { Metadata } from "next";
// import { useTranslation } from "@/hooks/use-translation"; // Removed
// import { DocContent } from "@/components/doc-content"; // Handled by client component
// import { CodeBlock } from "@/components/code-block"; // Handled by client component
import { GitOperationsPageContent } from "@/components/git-operations-page-content";

// export const metadata: Metadata = { // Temporarily commented out
//   title: "Git Operations Commands | GW Documentation",
//   description: "Learn about the Git operations commands in GW",
// };

export default function GitOperationsPage({ params }: { params: { lang: string } }) { // Added params
  // const { t, locale } = useTranslation(); // Removed

  const statusExamples = `# Show basic status
gw status

# Show status with remote comparison
gw status -r

# Show status with recent commits
gw status -l

# Show status with both remote comparison and recent commits
gw status -r -l`;

  const addExamples = `# Interactive file selection
gw add

# Add specific files
gw add src/main.js README.md`;

  const commitExamples = `# Commit with a message
gw commit -m "Fix login bug"

# Open editor for commit message
gw commit -e

# Amend previous commit
gw commit --amend`;

  const pushExamples = `# Push current branch
gw push

# Push to specific remote
gw push origin

# Push specific branch
gw push origin feature/login

# Force push (use with caution)
gw push --force`;

  const pullExamples = `# Pull with rebase from current branch's upstream
gw pull

# Pull from specific remote and branch
gw pull origin main

# Pull without rebase
gw pull --no-rebase`;

  return (
    <GitOperationsPageContent
      // lang={params.lang} // Pass lang if client component is adapted
      statusExamples={statusExamples}
      addExamples={addExamples}
      commitExamples={commitExamples}
      pushExamples={pushExamples}
      pullExamples={pullExamples}
    />
  );
}

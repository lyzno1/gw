import type { Metadata } from "next";
// import { useTranslation } from "@/hooks/use-translation"; // Removed
// import { DocContent } from "@/components/doc-content"; // Handled by client component
import { RepoManagementPageContent } from "@/components/repo-management-page-content";

// export const metadata: Metadata = { // Temporarily commented out
//   title: "Repository Management Commands | GW Documentation",
//   description: "Learn about the repository management commands in GW",
// };

export default function RepoManagementPage({ params }: { params: { lang: string } }) { // Added params
  // const { t } = useTranslation(); // Removed

  // Note: The actual code examples were directly in the JSX in the original file.
  // The new RepoManagementPageContent component has these as static strings for now.
  // If these examples needed to be dynamic or passed as props, this server component would define them.

  return (
    <RepoManagementPageContent /* lang={params.lang} */ />
  );
}

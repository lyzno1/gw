import type { Metadata } from "next";
// import { useTranslation } from "@/hooks/use-translation"; // Removed
// import { DocContent } from "@/components/doc-content"; // Handled by client component
import { TeamWorkflowPageContent } from "@/components/team-workflow-page-content";

// export const metadata: Metadata = { // Temporarily commented out
//   title: "Team Workflow | GW Documentation",
//   description: "Learn how to use GW in a team environment",
// };

export default function TeamWorkflowPage({ params }: { params: { lang: string } }) { // Added params
  // const { t } = useTranslation(); // Removed

  return (
    <TeamWorkflowPageContent /* lang={params.lang} */ />
  );
}

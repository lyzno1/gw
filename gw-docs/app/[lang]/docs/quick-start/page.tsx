import type { Metadata } from "next";
// import { useTranslation } from "@/hooks/use-translation"; // Removed
// import { DocContent } from "@/components/doc-content"; // Handled by client component
import { QuickStartPageContent } from "@/components/quick-start-page-content";

// export const metadata: Metadata = { // Temporarily commented out
//   title: "Quick Start | GW Documentation",
//   description: "Get started quickly with GW - the Git Workflow Assistant",
// };

export default function QuickStartPage({ params }: { params: { lang: string } }) { // Added params
  // const { t } = useTranslation(); // Removed

  return (
    <QuickStartPageContent lang={params.lang} /> // Pass lang for internal link construction
  );
}

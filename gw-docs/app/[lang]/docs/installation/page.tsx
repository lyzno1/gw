import type { Metadata } from "next";
// import { useTranslation } from "@/hooks/use-translation"; // Removed
// import { DocContent } from "@/components/doc-content"; // Handled by client component
import { InstallationPageContent } from "@/components/installation-page-content";

// export const metadata: Metadata = { // Temporarily commented out
//   title: "Installation | GW Documentation",
//   description: "Learn how to install GW - the Git Workflow Assistant",
// };

export default function InstallationPage({ params }: { params: { lang: string } }) { // Added params
  // const { t } = useTranslation(); // Removed

  return (
    <InstallationPageContent /* lang={params.lang} */ />
  );
}

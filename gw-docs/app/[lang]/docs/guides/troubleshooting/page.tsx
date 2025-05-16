import type { Metadata } from "next";
// import { useTranslation } from "@/hooks/use-translation"; // Removed
// import { DocContent } from "@/components/doc-content"; // Handled by client component
import { TroubleshootingPageContent } from "@/components/troubleshooting-page-content";

// export const metadata: Metadata = { // Temporarily commented out
//   title: "Troubleshooting | GW Documentation",
//   description: "Solutions for common issues when using GW",
// };

export default function TroubleshootingPage({ params }: { params: { lang: string } }) { // Added params
  // const { t } = useTranslation(); // Removed

  return (
    <TroubleshootingPageContent /* lang={params.lang} */ />
  );
}

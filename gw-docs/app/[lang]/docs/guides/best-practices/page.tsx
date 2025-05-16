import type { Metadata } from "next";
// import { useTranslation } from "@/hooks/use-translation"; // Removed
// import { DocContent } from "@/components/doc-content"; // Handled by client component
import { BestPracticesPageContent } from "@/components/best-practices-page-content";

// export const metadata: Metadata = { // Temporarily commented out
//   title: "Best Practices | GW Documentation",
//   description: "Learn about best practices when using GW",
// };

export default function BestPracticesPage({ params }: { params: { lang: string } }) { // Added params
  // const { t } = useTranslation(); // Removed

  return (
    <BestPracticesPageContent /* lang={params.lang} */ />
  );
}

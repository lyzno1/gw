import type { Metadata } from "next"
// import { useTranslation } from "@/hooks/use-translation" // Removed
// import { DocContent } from "@/components/doc-content" // Handled by CommandsPageContent
// import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs" // Handled by CommandsPageContent
// import { CommandGroup } from "@/components/command-group" // Handled by CommandsPageContent
import { CommandsPageContent } from "@/components/commands-page-content"

// export const metadata: Metadata = { // Temporarily commented out
//   title: "Commands | GW Documentation",
//   description: "Complete reference of all GW commands",
// }

export default function CommandsPage({ params }: { params: { lang: string } }) { // Added params
  // const { t } = useTranslation() // Removed

  return (
    <CommandsPageContent /* lang={params.lang} */ /> // Pass lang if CommandsPageContent is adapted
  )
}

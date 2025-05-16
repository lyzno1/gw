import type { Metadata } from "next"
// Removed: import { useTranslation } from "@/hooks/use-translation"
// Removed: import { DocContent } from "@/components/doc-content" (Handled by GettingStartedContent)
// Removed: import { CodeBlock } from "@/components/code-block" (Handled by GettingStartedContent)
import { GettingStartedContent } from "@/components/getting-started-content"

// export const metadata: Metadata = { // Temporarily commented out for i18n routing
//   title: "Getting Started | GW Documentation",
//   description: "Learn how to get started with GW - the Git Workflow Assistant",
// }

export default function GettingStartedPage({ params }: { params: { lang: string } }) { // Added params
  // Removed: const { t, locale } = useTranslation()

  const installationCode = `git clone https://github.com/lyzno1/gw.git
cd gw
chmod +x git_workflow.sh
chmod +x actions/*.sh`

  const configurationCode = `# Add to your ~/.bashrc or ~/.zshrc
alias gw="/path/to/your/gw/git_workflow.sh"`

  const verificationCode = `gw help`

  return (
    <GettingStartedContent
      installationCode={installationCode}
      configurationCode={configurationCode}
      verificationCode={verificationCode}
      // lang={params.lang} // We can pass lang down if GettingStartedContent is modified to accept it
    />
  )
}

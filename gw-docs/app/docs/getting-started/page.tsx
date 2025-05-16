"use client"

import type { Metadata } from "next"
import { useTranslation } from "@/hooks/use-translation"
import { DocContent } from "@/components/doc-content"
import { CodeBlock } from "@/components/code-block"

export const metadata: Metadata = {
  title: "Getting Started | GW Documentation",
  description: "Learn how to get started with GW - the Git Workflow Assistant",
}

export default function GettingStartedPage() {
  const { t, locale } = useTranslation()

  const installationCode = `git clone https://github.com/lyzno1/gw.git
cd gw
chmod +x git_workflow.sh
chmod +x actions/*.sh`

  const configurationCode = `# Add to your ~/.bashrc or ~/.zshrc
alias gw="/path/to/your/gw/git_workflow.sh"`

  const verificationCode = `gw help`

  return (
    <DocContent title={t("docs.gettingStarted.title")} description={t("docs.gettingStarted.description")}>
      <h2 className="mt-10 scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">
        {t("docs.gettingStarted.installation.title")}
      </h2>
      <p className="leading-7 [&:not(:first-child)]:mt-6">{t("docs.gettingStarted.installation.description")}</p>
      <CodeBlock code={installationCode} language="bash" />

      <h2 className="mt-10 scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">
        {t("docs.gettingStarted.configuration.title")}
      </h2>
      <p className="leading-7 [&:not(:first-child)]:mt-6">{t("docs.gettingStarted.configuration.description")}</p>
      <CodeBlock code={configurationCode} language="bash" />

      <h2 className="mt-10 scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">
        {t("docs.gettingStarted.verification.title")}
      </h2>
      <p className="leading-7 [&:not(:first-child)]:mt-6">{t("docs.gettingStarted.verification.description")}</p>
      <CodeBlock code={verificationCode} language="bash" showLineNumbers={false} />
    </DocContent>
  )
}

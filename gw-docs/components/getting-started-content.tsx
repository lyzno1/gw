"use client";

import { useTranslation } from "@/hooks/use-translation";
import { DocContent } from "@/components/doc-content";
import { CodeBlock } from "@/components/code-block";

interface GettingStartedContentProps {
  installationCode: string;
  configurationCode: string;
  verificationCode: string;
}

export function GettingStartedContent({
  installationCode,
  configurationCode,
  verificationCode,
}: GettingStartedContentProps) {
  const { t } = useTranslation();

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
      <CodeBlock code={verificationCode} language="bash" /> {/* Removed showLineNumbers prop */}
    </DocContent>
  );
}
"use client"

import type React from "react"

import { usePathname } from "next/navigation"
import { ModernSidebar } from "@/components/modern-sidebar"
import { useTranslation } from "@/hooks/use-translation"

export function DocsLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname()
  const { t } = useTranslation()

  const sidebarItems = [
    {
      title: t("sidebar.gettingStarted"),
      items: [
        {
          title: t("sidebar.introduction"),
          href: "/docs/getting-started",
        },
        {
          title: t("sidebar.installation"),
          href: "/docs/installation",
        },
        {
          title: t("sidebar.quickStart"),
          href: "/docs/quick-start",
        },
      ],
    },
    {
      title: t("sidebar.commands"),
      items: [
        {
          title: t("sidebar.commandsOverview"),
          href: "/docs/commands",
        },
        {
          title: t("sidebar.coreWorkflow"),
          href: "/docs/commands/core-workflow",
        },
        {
          title: t("sidebar.gitOperations"),
          href: "/docs/commands/git-operations",
        },
        {
          title: t("sidebar.repoManagement"),
          href: "/docs/commands/repo-management",
        },
      ],
    },
    {
      title: t("sidebar.guides"),
      items: [
        {
          title: t("sidebar.bestPractices"),
          href: "/docs/guides/best-practices",
        },
        {
          title: t("sidebar.teamWorkflow"),
          href: "/docs/guides/team-workflow",
        },
        {
          title: t("sidebar.troubleshooting"),
          href: "/docs/guides/troubleshooting",
        },
      ],
    },
    {
      title: t("sidebar.advanced"),
      items: [
        {
          title: t("sidebar.customization"),
          href: "/docs/advanced/customization",
        },
        {
          title: t("sidebar.extending"),
          href: "/docs/advanced/extending",
        },
      ],
    },
  ]

  return (
    <div className="container flex-1 items-start md:grid md:grid-cols-[220px_minmax(0,1fr)] md:gap-6 lg:grid-cols-[240px_minmax(0,1fr)] lg:gap-10">
      <aside className="fixed top-14 z-30 -ml-2 hidden h-[calc(100vh-3.5rem)] w-full shrink-0 md:sticky md:block">
        <div className="h-full py-6 pr-2 lg:py-8">
          <ModernSidebar items={sidebarItems} />
        </div>
      </aside>
      <main className="relative py-6 lg:gap-10 lg:py-8 animate-fade-in">{children}</main>
    </div>
  )
}

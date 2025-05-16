import type React from "react"
import { DocsLayout } from "@/components/docs-layout"

export default function Layout({ children, params }: { children: React.ReactNode, params: { lang: string } }) {
  // params.lang is available here if needed by DocsLayout or for other logic
  return <DocsLayout>{children}</DocsLayout> // Removed lang prop for now
}

"use client"

import { useState, useRef, useEffect } from "react"
import { Check, Copy } from "lucide-react"
import { cn } from "@/lib/utils"
import { useTranslation } from "@/hooks/use-translation"

interface CodeBlockProps {
  code: string
  language?: string
  showLineNumbers?: boolean
  className?: string
}

export function CodeBlock({ code, language = "bash", showLineNumbers = true, className }: CodeBlockProps) {
  const [copied, setCopied] = useState(false)
  const codeRef = useRef<HTMLPreElement>(null)
  const { locale } = useTranslation()

  const copyToClipboard = async () => {
    if (!navigator.clipboard || !codeRef.current) return

    try {
      await navigator.clipboard.writeText(code)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch (err) {
      console.error("Failed to copy code: ", err)
    }
  }

  // Apply syntax highlighting
  useEffect(() => {
    if (typeof window !== "undefined" && codeRef.current) {
      import("prismjs").then((Prism) => {
        import("prismjs/components/prism-bash")
        import("prismjs/components/prism-javascript")
        import("prismjs/components/prism-typescript")
        import("prismjs/components/prism-jsx")
        import("prismjs/components/prism-tsx")
        import("prismjs/components/prism-json")
        import("prismjs/components/prism-yaml")
        import("prismjs/components/prism-markdown")
        import("prismjs/components/prism-css")
        import("prismjs/components/prism-scss")
        Prism.highlightElement(codeRef.current)
      })
    }
  }, [code, language])

  const lines = code.split("\n")

  return (
    <div className={cn("relative my-4 overflow-hidden rounded-lg border", className)}>
      <div className="flex items-center justify-between bg-muted px-4 py-2">
        <div className="text-xs font-medium text-muted-foreground">{language.toUpperCase()}</div>
        <button
          onClick={copyToClipboard}
          className="flex h-8 w-8 items-center justify-center rounded-md transition-colors hover:bg-muted-foreground/10"
          aria-label={locale === "zh" ? "复制代码" : "Copy code"}
        >
          {copied ? <Check className="h-4 w-4 text-green-500" /> : <Copy className="h-4 w-4 text-muted-foreground" />}
        </button>
      </div>
      <div className="relative overflow-x-auto bg-black/90 dark:bg-black/70">
        <pre ref={codeRef} className={cn("p-4 text-sm text-white", showLineNumbers && "pl-12")}>
          <code className={`language-${language}`}>{code}</code>
        </pre>
        {showLineNumbers && (
          <div className="absolute left-0 top-0 flex h-full w-8 flex-col items-end border-r border-white/10 bg-black/30 px-2 py-4 text-xs text-gray-500">
            {lines.map((_, i) => (
              <div key={i} className="leading-5">
                {i + 1}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

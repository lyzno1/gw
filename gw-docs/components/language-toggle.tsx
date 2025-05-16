"use client"

import { useTranslation } from "@/hooks/use-translation"
import { Button } from "@/components/ui/button"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Languages } from "lucide-react"
import { motion } from "framer-motion"
import { useState, useEffect } from "react"

export function LanguageToggle() {
  const { locale, setLocale } = useTranslation()
  const [mounted, setMounted] = useState(false)

  // Ensure component is mounted to avoid hydration mismatch
  useEffect(() => {
    setMounted(true)
  }, [])

  if (!mounted) {
    return (
      <Button variant="ghost" size="sm" className="h-8 w-8 px-0">
        <span className="sr-only">Toggle language</span>
      </Button>
    )
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="sm" className="h-8 w-8 px-0">
          <motion.div whileHover={{ rotate: 20 }} transition={{ type: "spring", stiffness: 400, damping: 10 }}>
            <Languages className="h-4 w-4" />
          </motion.div>
          <span className="sr-only">{locale === "zh" ? "切换语言" : "Toggle language"}</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem onClick={() => setLocale("en")} className={locale === "en" ? "bg-muted" : ""}>
          <span className="mr-2">🇺🇸</span> English
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => setLocale("zh")} className={locale === "zh" ? "bg-muted" : ""}>
          <span className="mr-2">🇨🇳</span> 中文
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

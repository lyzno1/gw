"use client"
import { Moon, Sun } from "lucide-react"
import { useTheme } from "next-themes"
import { motion } from "framer-motion"
import { useEffect, useState } from "react"

import { Button } from "@/components/ui/button"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"

// Import at the top to avoid circular dependency issues
import { useTranslation } from "@/hooks/use-translation"

export function ThemeToggle() {
  const { setTheme, theme, resolvedTheme } = useTheme()
  const [mounted, setMounted] = useState(false)
  const translation = useTranslation()

  // Ensure component is mounted to avoid hydration mismatch
  useEffect(() => {
    setMounted(true)
  }, [])

  if (!mounted) {
    return (
      <Button variant="ghost" size="sm" className="h-8 w-8 px-0">
        <span className="sr-only">Toggle theme</span>
      </Button>
    )
  }

  const currentTheme = theme === "system" ? resolvedTheme : theme

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="sm" className="h-8 w-8 px-0">
          <motion.div whileHover={{ rotate: 45 }} transition={{ type: "spring", stiffness: 400, damping: 10 }}>
            <Sun className="h-4 w-4 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
            <Moon className="absolute h-4 w-4 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
          </motion.div>
          <span className="sr-only">{currentTheme === "dark" ? "切换到浅色模式" : "切换到深色模式"}</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem onClick={() => setTheme("light")} className={currentTheme === "light" ? "bg-muted" : ""}>
          <Sun className="mr-2 h-4 w-4" />
          {translation.locale === "zh" ? "浅色" : "Light"}
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme("dark")} className={currentTheme === "dark" ? "bg-muted" : ""}>
          <Moon className="mr-2 h-4 w-4" />
          {translation.locale === "zh" ? "深色" : "Dark"}
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme("system")} className={theme === "system" ? "bg-muted" : ""}>
          <span className="mr-2">💻</span>
          {translation.locale === "zh" ? "系统" : "System"}
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

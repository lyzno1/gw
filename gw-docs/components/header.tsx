"use client"

import Link from "next/link"
import { usePathname } from "next/navigation"
import { Button } from "@/components/ui/button"
import { ThemeToggle } from "@/components/theme-toggle"
import { LanguageToggle } from "@/components/language-toggle"
import { useTranslation } from "@/hooks/use-translation"
import { GitBranch, Menu, Github } from "lucide-react"
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet"
import { useState, useEffect } from "react"
import { cn } from "@/lib/utils"

export function Header() {
  const pathname = usePathname()
  const { t } = useTranslation()
  const [open, setOpen] = useState(false)
  const [scrolled, setScrolled] = useState(false)

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 10)
    }
    window.addEventListener("scroll", handleScroll)
    return () => window.removeEventListener("scroll", handleScroll)
  }, [])

  const isActive = (path: string) => {
    return pathname === path || pathname?.startsWith(`${path}/`)
  }

  return (
    <header
      className={cn(
        "sticky top-0 z-50 w-full backdrop-blur supports-[backdrop-filter]:bg-background/60 transition-all duration-200",
        scrolled ? "border-b shadow-sm" : "border-b border-transparent",
      )}
    >
      <div className="container flex h-16 items-center">
        <div className="mr-4 flex">
          <Link href="/" className="mr-6 flex items-center space-x-2">
            <div className="relative flex h-8 w-8 items-center justify-center rounded-full bg-primary/10 text-primary">
              <GitBranch className="h-4 w-4" />
            </div>
            <span className="hidden font-bold sm:inline-block">GW</span>
          </Link>
          <nav className="hidden md:flex items-center space-x-6 text-sm font-medium">
            <Link
              href="/"
              className={`transition-colors hover:text-foreground/80 ${
                isActive("/") && !isActive("/docs") ? "text-foreground" : "text-foreground/60"
              }`}
            >
              {t("nav.home")}
            </Link>
            <Link
              href="/docs"
              className={`transition-colors hover:text-foreground/80 ${
                isActive("/docs") ? "text-foreground" : "text-foreground/60"
              }`}
            >
              {t("nav.docs")}
            </Link>
            <Link
              href="/docs/guides/best-practices"
              className={`transition-colors hover:text-foreground/80 ${
                isActive("/docs/guides/best-practices") ? "text-foreground" : "text-foreground/60"
              }`}
            >
              {t("nav.bestPractices")}
            </Link>
            <Link
              href="/docs/guides/team-workflow"
              className={`transition-colors hover:text-foreground/80 ${
                isActive("/docs/guides/team-workflow") ? "text-foreground" : "text-foreground/60"
              }`}
            >
              {t("nav.teamWorkflow")}
            </Link>
          </nav>
        </div>
        <div className="flex flex-1 items-center justify-end space-x-2">
          <nav className="flex items-center space-x-2">
            <LanguageToggle />
            <ThemeToggle />
            <div className="hidden md:block">
              <Link href="https://github.com/lyzno1/gw" target="_blank" rel="noopener noreferrer">
                <Button variant="outline" size="sm" className="gap-2">
                  <Github className="h-4 w-4" />
                  GitHub
                </Button>
              </Link>
            </div>
            <Sheet open={open} onOpenChange={setOpen}>
              <SheetTrigger asChild>
                <Button variant="ghost" size="sm" className="md:hidden">
                  <Menu className="h-5 w-5" />
                  <span className="sr-only">Toggle Menu</span>
                </Button>
              </SheetTrigger>
              <SheetContent side="left">
                <Link href="/" className="flex items-center space-x-2" onClick={() => setOpen(false)}>
                  <div className="relative flex h-8 w-8 items-center justify-center rounded-full bg-primary/10 text-primary">
                    <GitBranch className="h-4 w-4" />
                  </div>
                  <span className="font-bold">GW</span>
                </Link>
                <nav className="mt-8 flex flex-col space-y-4">
                  <Link
                    href="/"
                    className="text-foreground/60 transition-colors hover:text-foreground"
                    onClick={() => setOpen(false)}
                  >
                    {t("nav.home")}
                  </Link>
                  <Link
                    href="/docs"
                    className="text-foreground/60 transition-colors hover:text-foreground"
                    onClick={() => setOpen(false)}
                  >
                    {t("nav.docs")}
                  </Link>
                  <Link
                    href="/docs/guides/best-practices"
                    className="text-foreground/60 transition-colors hover:text-foreground"
                    onClick={() => setOpen(false)}
                  >
                    {t("nav.bestPractices")}
                  </Link>
                  <Link
                    href="/docs/guides/team-workflow"
                    className="text-foreground/60 transition-colors hover:text-foreground"
                    onClick={() => setOpen(false)}
                  >
                    {t("nav.teamWorkflow")}
                  </Link>
                  <Link
                    href="https://github.com/lyzno1/gw"
                    className="text-foreground/60 transition-colors hover:text-foreground"
                    target="_blank"
                    rel="noopener noreferrer"
                    onClick={() => setOpen(false)}
                  >
                    GitHub
                  </Link>
                </nav>
              </SheetContent>
            </Sheet>
          </nav>
        </div>
      </div>
    </header>
  )
}

"use client"

import type React from "react"

import { useState, useEffect } from "react"
import { usePathname } from "next/navigation"
import Link from "next/link"
import { ChevronRight, ChevronDown } from "lucide-react"
import { Button } from "@/components/ui/button"
import { useTranslation } from "@/hooks/use-translation"
import { cn } from "@/lib/utils"

interface SidebarItem {
  title: string
  href?: string
  icon?: React.ElementType
  items?: SidebarItem[]
  expanded?: boolean
}

interface SidebarProps {
  items: SidebarItem[]
  className?: string
}

export function ModernSidebar({ items, className }: SidebarProps) {
  const pathname = usePathname()
  const { t } = useTranslation()
  const [expanded, setExpanded] = useState(true)
  const [openGroups, setOpenGroups] = useState<Record<string, boolean>>({})

  // Initialize open groups based on current path
  useEffect(() => {
    const newOpenGroups: Record<string, boolean> = {}

    const checkItemsForCurrentPath = (items: SidebarItem[], parentTitle?: string) => {
      items.forEach((item) => {
        if (item.items?.length) {
          // If this group contains the current path, expand it
          const containsCurrentPath = item.items.some(
            (subItem) => subItem.href === pathname || pathname?.startsWith(`${subItem.href}/`),
          )

          if (containsCurrentPath) {
            const key = parentTitle ? `${parentTitle}-${item.title}` : item.title
            newOpenGroups[key] = true
          }

          // Recursively check nested items
          checkItemsForCurrentPath(item.items, item.title)
        }
      })
    }

    checkItemsForCurrentPath(items)
    setOpenGroups(newOpenGroups)
  }, [pathname, items])

  const toggleGroup = (title: string) => {
    setOpenGroups((prev) => ({
      ...prev,
      [title]: !prev[title],
    }))
  }

  const toggleSidebar = () => {
    setExpanded((prev) => !prev)
  }

  const renderItems = (items: SidebarItem[], level = 0, parentTitle?: string) => {
    return items.map((item, index) => {
      const isActive = item.href === pathname || pathname?.startsWith(`${item.href}/`)
      const hasItems = item.items && item.items.length > 0
      const groupKey = parentTitle ? `${parentTitle}-${item.title}` : item.title
      const isGroupOpen = openGroups[groupKey]

      return (
        <div key={item.title + index} className={cn("animate-fade-in", level > 0 && "ml-3")}>
          {hasItems ? (
            <div>
              <button
                onClick={() => toggleGroup(groupKey)}
                className={cn(
                  "flex w-full items-center justify-between rounded-md px-3 py-2 text-sm font-medium",
                  isActive ? "bg-primary/10 text-primary" : "hover:bg-muted",
                )}
              >
                <span>{item.title}</span>
                {isGroupOpen ? <ChevronDown className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
              </button>
              {isGroupOpen && <div className="mt-1 space-y-1">{renderItems(item.items!, level + 1, item.title)}</div>}
            </div>
          ) : (
            <Link
              href={item.href || "#"}
              className={cn(
                "flex items-center rounded-md px-3 py-2 text-sm font-medium",
                isActive ? "bg-primary/10 text-primary" : "hover:bg-muted text-foreground/70 hover:text-foreground",
              )}
            >
              {item.title}
            </Link>
          )}
        </div>
      )
    })
  }

  return (
    <div className="relative">
      <div
        className={cn(
          "sidebar-container h-full overflow-hidden transition-all duration-300 ease-in-out",
          expanded ? "w-full" : "w-0",
        )}
      >
        <div
          className={cn(
            "sidebar-content h-full overflow-y-auto pr-3 transition-opacity",
            expanded ? "opacity-100" : "opacity-0",
          )}
        >
          <div className="space-y-4 py-4">
            {items.map((section, index) => (
              <div key={section.title + index} className="px-3 py-2">
                <h4 className="mb-2 text-sm font-semibold text-foreground/70">{section.title}</h4>
                <div className="space-y-1">{renderItems(section.items || [])}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
      <Button
        variant="ghost"
        size="icon"
        className="absolute -right-4 top-6 z-20 flex h-8 w-8 items-center justify-center rounded-full border bg-background shadow-md"
        onClick={toggleSidebar}
      >
        {expanded ? <ChevronRight className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
      </Button>
    </div>
  )
}

"use client"

import Link from "next/link"
import { usePathname } from "next/navigation"
import { motion } from "framer-motion"
import { cn } from "@/lib/utils"

interface DocsSidebarProps {
  items: {
    title: string
    items: {
      title: string
      href: string
      items: {
        title: string
        href: string
      }[]
    }[]
  }[]
}

export function DocsSidebar({ items }: DocsSidebarProps) {
  const pathname = usePathname()

  const listVariants = {
    hidden: { opacity: 0 },
    show: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1,
      },
    },
  }

  const itemVariants = {
    hidden: { opacity: 0, x: -20 },
    show: { opacity: 1, x: 0 },
  }

  return (
    <div className="w-full">
      <motion.div initial="hidden" animate="show" variants={listVariants} className="space-y-6">
        {items.map((item, index) => (
          <motion.div key={item.title} variants={itemVariants} className="pb-4">
            <h4 className="mb-1 rounded-md px-2 py-1 text-sm font-semibold">{item.title}</h4>
            {item?.items?.length > 0 && (
              <div className="grid grid-flow-row auto-rows-max text-sm">
                {item.items.map((subItem) => (
                  <Link
                    key={subItem.href}
                    href={subItem.href}
                    className={cn(
                      "group flex w-full items-center rounded-md border border-transparent px-2 py-1 hover:underline transition-colors duration-200",
                      pathname === subItem.href
                        ? "font-medium text-primary bg-primary/5 dark:bg-primary/10"
                        : "text-muted-foreground hover:text-foreground hover:bg-muted/50",
                    )}
                  >
                    {subItem.title}
                  </Link>
                ))}
              </div>
            )}
          </motion.div>
        ))}
      </motion.div>
    </div>
  )
}

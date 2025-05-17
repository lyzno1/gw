"use client"

import { useEffect, useState } from "react"
import { cn } from "@/lib/utils"
import type React from "react"

interface DocContentProps {
  title: string
  description?: string
  children: React.ReactNode
  className?: string
}

export function DocContent({ title, description, children, className }: DocContentProps) {
  // 使用状态来控制内容可见性，实现平滑过渡
  const [isVisible, setIsVisible] = useState(false)
  
  useEffect(() => {
    // 组件挂载时设置为可见
    const timer = setTimeout(() => {
      setIsVisible(true)
    }, 50) // 短暂延迟，以确保DOM完全准备好
    
    return () => clearTimeout(timer)
  }, [])
  
  return (
    <div className="mx-auto w-full min-w-0">
      <div className="space-y-2">
        <h1 className="scroll-m-20 text-4xl font-bold tracking-tight gradient-text">{title}</h1>
        {description && <p className="text-lg text-muted-foreground">{description}</p>}
      </div>
      <div className="pb-12 pt-8 animate-slide-in-up">
        <div 
          className={cn(
            "transition-opacity duration-300 ease-in-out", 
            isVisible ? "opacity-100" : "opacity-0",
            className
          )}
        >
          {children}
        </div>
      </div>
    </div>
  )
}

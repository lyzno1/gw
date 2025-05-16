import type React from "react"
interface DocContentProps {
  title: string
  description?: string
  children: React.ReactNode
}

export function DocContent({ title, description, children }: DocContentProps) {
  return (
    <div className="mx-auto w-full min-w-0">
      <div className="space-y-2">
        <h1 className="scroll-m-20 text-4xl font-bold tracking-tight gradient-text">{title}</h1>
        {description && <p className="text-lg text-muted-foreground">{description}</p>}
      </div>
      <div className="pb-12 pt-8 animate-slide-in-up">{children}</div>
    </div>
  )
}

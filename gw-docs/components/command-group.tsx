interface CommandGroupProps {
  title: string
  description?: string
  commands: {
    name: string
    syntax: string
    description: string
  }[]
}

export function CommandGroup({ title, description, commands }: CommandGroupProps) {
  return (
    <div className="my-6 space-y-4">
      <div className="space-y-2">
        <h3 className="text-xl font-bold">{title}</h3>
        {description && <p className="text-muted-foreground">{description}</p>}
      </div>
      <div className="space-y-4 stagger-animation">
        {commands.map((command) => (
          <div key={command.name} className="rounded-lg border p-4 command-card animate-fade-in">
            <h4 className="font-medium">{command.name}</h4>
            <pre className="mt-2 overflow-x-auto rounded-md bg-muted p-2 text-sm">
              <code>{command.syntax}</code>
            </pre>
            <p className="mt-2 text-sm text-muted-foreground">{command.description}</p>
          </div>
        ))}
      </div>
    </div>
  )
}

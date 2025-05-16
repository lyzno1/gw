"use client"

import type React from "react"

import { useState } from "react"
import { GitBranch, GitCommit, GitMerge, GitPullRequest, Trash2 } from "lucide-react"
import { cn } from "@/lib/utils"

interface WorkflowStep {
  id: string
  title: string
  command: string
  description: string
  icon: React.ElementType
}

export function WorkflowDiagram() {
  const [activeStep, setActiveStep] = useState<string | null>(null)

  const steps: WorkflowStep[] = [
    {
      id: "start",
      title: "Start a feature",
      command: "gw start feature/new-feature",
      description: "Creates a new branch from main, handles stashing, and updates the base branch automatically",
      icon: GitBranch,
    },
    {
      id: "save",
      title: "Save changes",
      command: 'gw save -m "Add new feature"',
      description: "Quickly add and commit changes in one step",
      icon: GitCommit,
    },
    {
      id: "update",
      title: "Keep in sync",
      command: "gw update",
      description: "Update your branch with the latest changes from main",
      icon: GitMerge,
    },
    {
      id: "submit",
      title: "Submit work",
      command: "gw submit --pr",
      description: "Push your changes and create a pull request",
      icon: GitPullRequest,
    },
    {
      id: "clean",
      title: "Clean up",
      command: "gw clean feature/new-feature",
      description: "Switch to main and delete the feature branch",
      icon: Trash2,
    },
  ]

  return (
    <div className="mx-auto max-w-4xl">
      <div className="flex flex-col space-y-6 md:flex-row md:space-y-0 md:space-x-4">
        {steps.map((step, index) => (
          <div
            key={step.id}
            className={cn(
              "relative flex-1 rounded-lg border p-4 transition-all duration-300",
              activeStep === step.id ? "border-primary bg-primary/5 shadow-md" : "hover:border-primary/50",
            )}
            onMouseEnter={() => setActiveStep(step.id)}
            onMouseLeave={() => setActiveStep(null)}
          >
            <div className="mb-3 flex items-center space-x-2">
              <div
                className={cn(
                  "rounded-full p-1.5",
                  activeStep === step.id ? "bg-primary text-primary-foreground" : "bg-muted text-muted-foreground",
                )}
              >
                <step.icon className="h-4 w-4" />
              </div>
              <span className="font-medium">
                {index + 1}. {step.title}
              </span>
            </div>
            <div className="command-syntax text-xs">{step.command}</div>
            <p className="mt-2 text-xs text-muted-foreground">{step.description}</p>

            {index < steps.length - 1 && (
              <div className="absolute -right-2 top-1/2 hidden -translate-y-1/2 md:block">
                <svg width="12" height="24" viewBox="0 0 12 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path
                    d="M1 1L10 12L1 23"
                    stroke="currentColor"
                    strokeOpacity="0.3"
                    strokeWidth="2"
                    strokeLinecap="round"
                  />
                </svg>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  )
}

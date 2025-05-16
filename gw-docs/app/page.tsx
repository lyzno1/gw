"use client"

import Link from "next/link"
import { Button } from "@/components/ui/button"
import { useTranslation } from "@/hooks/use-translation"
import { Terminal, GitBranch, Zap, Shield, Users, ArrowRight, Code, CheckCircle } from "lucide-react"

export default function Home() {
  const { t } = useTranslation()

  return (
    <div className="flex flex-col items-center">
      {/* Hero Section */}
      <section className="w-full py-12 md:py-24 lg:py-32 xl:py-48 hero-gradient relative overflow-hidden">
        <div className="dots-pattern"></div>
        <div className="container px-4 md:px-6 relative z-10">
          <div className="flex flex-col items-center space-y-4 text-center">
            <div className="space-y-2">
              <h1 className="text-3xl font-bold tracking-tighter sm:text-4xl md:text-5xl lg:text-6xl/none gradient-text animate-fade-in">
                {t("home.hero.title")}
              </h1>
              <p className="mx-auto max-w-[700px] text-gray-500 md:text-xl dark:text-gray-400 animate-slide-in-up">
                {t("home.hero.subtitle")}
              </p>
            </div>
            <div className="space-x-4 animate-slide-in-up" style={{ animationDelay: "0.2s" }}>
              <Link href="/docs/getting-started">
                <Button className="h-11 px-8">
                  {t("home.hero.getStarted")}
                  <ArrowRight className="ml-2 h-4 w-4" />
                </Button>
              </Link>
              <Link href="https://github.com/lyzno1/gw" target="_blank" rel="noopener noreferrer">
                <Button variant="outline" className="h-11 px-8">
                  GitHub
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Workflow Visualization */}
      <section className="w-full py-12 md:py-24 bg-background">
        <div className="container px-4 md:px-6">
          <div className="flex flex-col items-center justify-center space-y-4 text-center mb-12">
            <h2 className="text-3xl font-bold tracking-tighter sm:text-4xl gradient-text">Simplified Git Workflow</h2>
            <p className="mx-auto max-w-[700px] text-muted-foreground md:text-lg">
              GW transforms complex Git operations into a streamlined workflow
            </p>
          </div>

          <div className="mx-auto max-w-4xl">
            <div className="space-y-12">
              <div className="workflow-step pl-8 animate-slide-in-right">
                <h3 className="text-xl font-semibold mb-2">1. Start a feature</h3>
                <div className="command-syntax">gw start feature/awesome-feature</div>
                <p className="mt-2 text-muted-foreground">
                  Creates a new branch from main, handles stashing, and updates the base branch automatically
                </p>
              </div>

              <div className="workflow-step pl-8 animate-slide-in-right" style={{ animationDelay: "0.1s" }}>
                <h3 className="text-xl font-semibold mb-2">2. Make changes and save</h3>
                <div className="command-syntax">gw save -m "Add new feature"</div>
                <p className="mt-2 text-muted-foreground">Quickly add and commit changes in one step</p>
              </div>

              <div className="workflow-step pl-8 animate-slide-in-right" style={{ animationDelay: "0.2s" }}>
                <h3 className="text-xl font-semibold mb-2">3. Keep in sync with main</h3>
                <div className="command-syntax">gw update</div>
                <p className="mt-2 text-muted-foreground">Update your branch with the latest changes from main</p>
              </div>

              <div className="workflow-step pl-8 animate-slide-in-right" style={{ animationDelay: "0.3s" }}>
                <h3 className="text-xl font-semibold mb-2">4. Submit your work</h3>
                <div className="command-syntax">gw submit --pr</div>
                <p className="mt-2 text-muted-foreground">Push your changes and create a pull request</p>
              </div>

              <div className="workflow-step pl-8 animate-slide-in-right" style={{ animationDelay: "0.4s" }}>
                <h3 className="text-xl font-semibold mb-2">5. Clean up</h3>
                <div className="command-syntax">gw clean feature/awesome-feature</div>
                <p className="mt-2 text-muted-foreground">Switch to main and delete the feature branch</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="w-full py-12 md:py-24 lg:py-32 bg-muted/50">
        <div className="container px-4 md:px-6">
          <div className="flex flex-col items-center justify-center space-y-4 text-center">
            <div className="space-y-2">
              <h2 className="text-3xl font-bold tracking-tighter sm:text-5xl gradient-text">
                {t("home.features.title")}
              </h2>
              <p className="mx-auto max-w-[700px] text-gray-500 md:text-xl/relaxed lg:text-base/relaxed xl:text-xl/relaxed dark:text-gray-400">
                {t("home.features.subtitle")}
              </p>
            </div>
          </div>
          <div className="mx-auto grid max-w-5xl grid-cols-1 gap-6 py-12 md:grid-cols-2 lg:grid-cols-3 stagger-animation">
            <div className="flex flex-col items-center space-y-2 rounded-lg border p-6 shadow-sm feature-card animate-fade-in">
              <div className="rounded-full bg-primary p-2 text-primary-foreground">
                <Terminal className="h-6 w-6" />
              </div>
              <h3 className="text-xl font-bold">{t("home.features.workflow.title")}</h3>
              <p className="text-sm text-center text-gray-500 dark:text-gray-400">
                {t("home.features.workflow.description")}
              </p>
            </div>
            <div className="flex flex-col items-center space-y-2 rounded-lg border p-6 shadow-sm feature-card animate-fade-in">
              <div className="rounded-full bg-primary p-2 text-primary-foreground">
                <GitBranch className="h-6 w-6" />
              </div>
              <h3 className="text-xl font-bold">{t("home.features.standardization.title")}</h3>
              <p className="text-sm text-center text-gray-500 dark:text-gray-400">
                {t("home.features.standardization.description")}
              </p>
            </div>
            <div className="flex flex-col items-center space-y-2 rounded-lg border p-6 shadow-sm feature-card animate-fade-in">
              <div className="rounded-full bg-primary p-2 text-primary-foreground">
                <Zap className="h-6 w-6" />
              </div>
              <h3 className="text-xl font-bold">{t("home.features.efficiency.title")}</h3>
              <p className="text-sm text-center text-gray-500 dark:text-gray-400">
                {t("home.features.efficiency.description")}
              </p>
            </div>
            <div className="flex flex-col items-center space-y-2 rounded-lg border p-6 shadow-sm feature-card animate-fade-in">
              <div className="rounded-full bg-primary p-2 text-primary-foreground">
                <Shield className="h-6 w-6" />
              </div>
              <h3 className="text-xl font-bold">{t("home.features.robust.title")}</h3>
              <p className="text-sm text-center text-gray-500 dark:text-gray-400">
                {t("home.features.robust.description")}
              </p>
            </div>
            <div className="flex flex-col items-center space-y-2 rounded-lg border p-6 shadow-sm feature-card animate-fade-in">
              <div className="rounded-full bg-primary p-2 text-primary-foreground">
                <Users className="h-6 w-6" />
              </div>
              <h3 className="text-xl font-bold">{t("home.features.team.title")}</h3>
              <p className="text-sm text-center text-gray-500 dark:text-gray-400">
                {t("home.features.team.description")}
              </p>
            </div>
            <div className="flex flex-col items-center space-y-2 rounded-lg border p-6 shadow-sm feature-card animate-fade-in">
              <div className="rounded-full bg-primary p-2 text-primary-foreground">
                <Code className="h-6 w-6" />
              </div>
              <h3 className="text-xl font-bold">{t("home.features.extensible.title")}</h3>
              <p className="text-sm text-center text-gray-500 dark:text-gray-400">
                {t("home.features.extensible.description")}
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Benefits Section */}
      <section className="w-full py-12 md:py-24 lg:py-32">
        <div className="container px-4 md:px-6">
          <div className="flex flex-col items-center justify-center space-y-4 text-center mb-12">
            <h2 className="text-3xl font-bold tracking-tighter sm:text-4xl gradient-text">Why Use GW?</h2>
            <p className="mx-auto max-w-[700px] text-muted-foreground md:text-lg">
              GW solves common Git workflow challenges and improves team productivity
            </p>
          </div>

          <div className="grid gap-8 md:grid-cols-2">
            <div className="flex items-start space-x-4 animate-slide-in-right">
              <div className="mt-1 rounded-full bg-primary/10 p-1">
                <CheckCircle className="h-5 w-5 text-primary" />
              </div>
              <div>
                <h3 className="text-lg font-medium">Reduced Mental Overhead</h3>
                <p className="text-muted-foreground">
                  Stop remembering complex Git command sequences and focus on your code
                </p>
              </div>
            </div>

            <div className="flex items-start space-x-4 animate-slide-in-right" style={{ animationDelay: "0.1s" }}>
              <div className="mt-1 rounded-full bg-primary/10 p-1">
                <CheckCircle className="h-5 w-5 text-primary" />
              </div>
              <div>
                <h3 className="text-lg font-medium">Consistent Team Practices</h3>
                <p className="text-muted-foreground">
                  Standardize Git workflows across your entire team with intuitive commands
                </p>
              </div>
            </div>

            <div className="flex items-start space-x-4 animate-slide-in-right" style={{ animationDelay: "0.2s" }}>
              <div className="mt-1 rounded-full bg-primary/10 p-1">
                <CheckCircle className="h-5 w-5 text-primary" />
              </div>
              <div>
                <h3 className="text-lg font-medium">Fewer Mistakes</h3>
                <p className="text-muted-foreground">
                  Built-in safeguards prevent common Git errors and help maintain a clean history
                </p>
              </div>
            </div>

            <div className="flex items-start space-x-4 animate-slide-in-right" style={{ animationDelay: "0.3s" }}>
              <div className="mt-1 rounded-full bg-primary/10 p-1">
                <CheckCircle className="h-5 w-5 text-primary" />
              </div>
              <div>
                <h3 className="text-lg font-medium">Faster Onboarding</h3>
                <p className="text-muted-foreground">
                  New team members can be productive with Git faster using GW's intuitive commands
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="w-full py-12 md:py-24 lg:py-32 bg-muted">
        <div className="container px-4 md:px-6">
          <div className="flex flex-col items-center justify-center space-y-4 text-center">
            <div className="space-y-2">
              <h2 className="text-3xl font-bold tracking-tighter sm:text-5xl gradient-text">{t("home.cta.title")}</h2>
              <p className="mx-auto max-w-[700px] text-gray-500 md:text-xl/relaxed lg:text-base/relaxed xl:text-xl/relaxed dark:text-gray-400">
                {t("home.cta.subtitle")}
              </p>
            </div>
            <div className="space-x-4">
              <Link href="/docs/installation">
                <Button className="h-11 px-8">{t("home.cta.install")}</Button>
              </Link>
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}

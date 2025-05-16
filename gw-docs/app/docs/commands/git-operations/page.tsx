import type { Metadata } from "next"
import { useTranslation } from "@/hooks/use-translation"
import { DocContent } from "@/components/doc-content"
import { CodeBlock } from "@/components/code-block"

export const metadata: Metadata = {
  title: "Git Operations Commands | GW Documentation",
  description: "Learn about the Git operations commands in GW",
}

export default function GitOperationsPage() {
  const { t, locale } = useTranslation()

  const statusExamples = `# Show basic status
gw status

# Show status with remote comparison
gw status -r

# Show status with recent commits
gw status -l

# Show status with both remote comparison and recent commits
gw status -r -l`

  const addExamples = `# Interactive file selection
gw add

# Add specific files
gw add src/main.js README.md`

  const commitExamples = `# Commit with a message
gw commit -m "Fix login bug"

# Open editor for commit message
gw commit -e

# Amend previous commit
gw commit --amend`

  const pushExamples = `# Push current branch
gw push

# Push to specific remote
gw push origin

# Push specific branch
gw push origin feature/login

# Force push (use with caution)
gw push --force`

  const pullExamples = `# Pull with rebase from current branch's upstream
gw pull

# Pull from specific remote and branch
gw pull origin main

# Pull without rebase
gw pull --no-rebase`

  return (
    <DocContent
      title={locale === "zh" ? t("docs.gitOperations.title") : "Git Operations Commands"}
      description={
        locale === "zh"
          ? t("docs.gitOperations.description")
          : "Enhanced wrappers around common Git operations for improved usability"
      }
    >
      <div className="space-y-10">
        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">gw status</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            {locale === "zh"
              ? "显示工作目录状态，带有增强信息。"
              : "Shows the status of your working directory with enhanced information."}
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "语法" : "Syntax"}
          </h3>
          <CodeBlock code="gw status [-r] [-l]" language="bash" showLineNumbers={false} />
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "选项" : "Options"}
          </h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>
              <code>-r</code>:
              {locale === "zh" ? "包含远程分支比较信息" : "Include remote branch comparison information"}
            </li>
            <li>
              <code>-l</code>:{locale === "zh" ? "包含最近提交日志信息" : "Include recent commit log information"}
            </li>
          </ul>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "示例" : "Examples"}
          </h3>
          <CodeBlock code={statusExamples} language="bash" />
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">gw add</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            {locale === "zh"
              ? "将文件添加到暂存区，无文件指定时进行交互式选择。"
              : "Adds files to the staging area with interactive selection if no files are specified."}
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "语法" : "Syntax"}
          </h3>
          <CodeBlock code="gw add [files...]" language="bash" showLineNumbers={false} />
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "行为" : "Behavior"}
          </h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>
              {locale === "zh"
                ? "无参数时：打开交互式选择菜单选择要暂存的文件"
                : "Without arguments: Opens an interactive selection menu to choose files to stage"}
            </li>
            <li>
              {locale === "zh" ? "带文件参数时：暂存指定的文件" : "With file arguments: Stages the specified files"}
            </li>
          </ul>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "示例" : "Examples"}
          </h3>
          <CodeBlock code={addExamples} language="bash" />
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">gw commit</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            {locale === "zh"
              ? "提交暂存的更改，带增强的消息处理。"
              : "Commits staged changes with enhanced message handling."}
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "语法" : "Syntax"}
          </h3>
          <CodeBlock code='gw commit [-m "message"] [-e] [...]' language="bash" showLineNumbers={false} />
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "选项" : "Options"}
          </h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>
              <code>-m "message"</code>:{locale === "zh" ? "指定提交消息" : "Specify commit message"}
            </li>
            <li>
              <code>-e</code>:
              {locale === "zh" ? "强制打开编辑器编辑提交消息" : "Force opening the editor for commit message"}
            </li>
            <li>
              <code>[...]</code>:
              {locale === "zh" ? "传递给 git commit 的任何其他选项" : "Any other options passed to git commit"}
            </li>
          </ul>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "示例" : "Examples"}
          </h3>
          <CodeBlock code={commitExamples} language="bash" />
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">gw push</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            {locale === "zh"
              ? "推送本地提交到远程，带自动重试和上游处理。"
              : "Pushes local commits to remote with automatic retry and upstream handling."}
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "语法" : "Syntax"}
          </h3>
          <CodeBlock code="gw push [remote] [branch] [...]" language="bash" showLineNumbers={false} />
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "特性" : "Features"}
          </h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>
              {locale === "zh"
                ? "自动处理新分支的 -u（设置上游）"
                : "Automatically handles -u (set-upstream) for new branches"}
            </li>
            <li>
              {locale === "zh"
                ? "内置网络重试机制，适用于不稳定连接"
                : "Built-in network retry mechanism for unstable connections"}
            </li>
            <li>{locale === "zh" ? "推送前检查未提交的更改" : "Checks for uncommitted changes before pushing"}</li>
          </ul>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "示例" : "Examples"}
          </h3>
          <CodeBlock code={pushExamples} language="bash" />
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">gw pull</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            {locale === "zh"
              ? "从远程拉取更新，默认使用 rebase 策略。"
              : "Pulls updates from remote with rebase strategy by default."}
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "语法" : "Syntax"}
          </h3>
          <CodeBlock code="gw pull [remote] [branch] [...]" language="bash" showLineNumbers={false} />
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "特性" : "Features"}
          </h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>
              {locale === "zh"
                ? "默认使用 --rebase 策略，保持更整洁的历史"
                : "Uses --rebase strategy by default for cleaner history"}
            </li>
            <li>{locale === "zh" ? "内置网络重试机制" : "Built-in network retry mechanism"}</li>
            <li>
              {locale === "zh"
                ? "可以使用 --no-rebase 或其他 git pull 选项覆盖"
                : "Can be overridden with --no-rebase or other git pull options"}
            </li>
          </ul>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "示例" : "Examples"}
          </h3>
          <CodeBlock code={pullExamples} language="bash" />
        </div>
      </div>
    </DocContent>
  )
}

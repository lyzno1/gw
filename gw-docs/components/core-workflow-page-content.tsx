"use client";

import { useTranslation } from "@/hooks/use-translation";
import { DocContent } from "@/components/doc-content";
import { CodeBlock } from "@/components/code-block";

interface CoreWorkflowPageContentProps {
  // lang: string; // Can be passed if needed
  startExamples: string;
  saveExamples: string;
  updateExample: string;
  submitExamples: string;
  rmExamples: string;
  cleanExample: string;
}

export function CoreWorkflowPageContent({
  startExamples,
  saveExamples,
  updateExample,
  submitExamples,
  rmExamples,
  cleanExample,
}: CoreWorkflowPageContentProps) {
  const { t, locale } = useTranslation();

  return (
    <DocContent
      title={locale === "zh" ? t("sidebar.coreWorkflow") : "Core Workflow Commands"}
      description={
        locale === "zh"
          ? "构成 GW 工作流骨干的基本命令"
          : "The essential commands that form the backbone of the GW workflow"
      }
    >
      <div className="space-y-10">
        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">gw start</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            {locale === "zh"
              ? "从基础分支创建新分支并开始工作。"
              : "Creates a new branch from the base branch and starts working on it."}
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "语法" : "Syntax"}
          </h3>
          <CodeBlock code="gw start <branch> [--base <base>] [--local]" language="bash" />
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "选项" : "Options"}
          </h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>
              <code>--base &lt;base&gt;</code>:
              {locale === "zh"
                ? "指定不同的基础分支（默认为 main/master）"
                : "Specify a different base branch (default is main/master)"}
            </li>
            <li>
              <code>--local</code>:
              {locale === "zh" ? "跳过从远程拉取最新更改" : "Skip pulling the latest changes from remote"}
            </li>
          </ul>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "示例" : "Examples"}
          </h3>
          <CodeBlock code={startExamples} language="bash" />
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">gw save</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            {locale === "zh"
              ? "快速保存更改（add + commit）一步完成。"
              : "Quickly saves changes (add + commit) in one step."}
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "语法" : "Syntax"}
          </h3>
          <CodeBlock code="gw save [-m <message>] [-e] [files...]" language="bash" />
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "选项" : "Options"}
          </h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>
              <code>-m &lt;message&gt;</code>:{locale === "zh" ? "指定提交消息" : "Specify commit message"}
            </li>
            <li>
              <code>-e</code>:
              {locale === "zh" ? "强制打开编辑器编辑提交消息" : "Force opening the editor for commit message"}
            </li>
            <li>
              <code>[files...]</code>:
              {locale === "zh" ? "要添加的特定文件（默认：所有更改）" : "Specific files to add (default: all changes)"}
            </li>
          </ul>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "示例" : "Examples"}
          </h3>
          <CodeBlock code={saveExamples} language="bash" />
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">gw update</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            {locale === "zh"
              ? "用主分支的最新更改更新当前分支。"
              : "Updates the current branch with the latest changes from the main branch."}
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "语法" : "Syntax"}
          </h3>
          <CodeBlock code="gw update" language="bash" />
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "行为" : "Behavior"}
          </h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>
              {locale === "zh"
                ? "如果在功能分支上：使用 rebase 与主分支同步"
                : "If on a feature branch: Syncs with the main branch using rebase"}
            </li>
            <li>
              {locale === "zh"
                ? "如果在主分支上：从远程拉取最新更改"
                : "If on the main branch: Pulls the latest changes from remote"}
            </li>
            <li>
              {locale === "zh"
                ? "如果需要，自动处理未提交更改的暂存"
                : "Automatically handles stashing uncommitted changes if needed"}
            </li>
          </ul>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "示例" : "Example"}
          </h3>
          <CodeBlock code={updateExample} language="bash" />
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">gw submit</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            {locale === "zh"
              ? "提交分支工作：保存更改，推送到远程，并可选择创建 PR。"
              : "Submits branch work: saves changes, pushes to remote, and optionally creates a PR."}
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "语法" : "Syntax"}
          </h3>
          <CodeBlock
            code="gw submit [--no-switch] [--pr] [-a|--auto-merge] [-s|--squash] [--merge-strategy <strategy>] [--delete-branch-after-merge]"
            language="bash"
          />
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "选项" : "Options"}
          </h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>
              <code>--no-switch</code>:
              {locale === "zh" ? "提交后不切换回主分支" : "Don't switch back to the main branch after submitting"}
            </li>
            <li>
              <code>--pr</code>:
              {locale === "zh" ? "创建拉取请求（需要 GitHub CLI）" : "Create a pull request (requires GitHub CLI)"}
            </li>
            <li>
              <code>-a|--auto-merge</code>:
              {locale === "zh" ? "如果可能，自动合并 PR" : "Automatically merge the PR if possible"}
            </li>
            <li>
              <code>-s|--squash</code>:
              {locale === "zh" ? "将所有更改压缩到一个提交中" : "Squash all changes into one commit"}
            </li>
            <li>
              <code>--merge-strategy &lt;strategy&gt;</code>:
              {locale === "zh" ? "指定合并策略" : "Specify merge strategy"}
            </li>
            <li>
              <code>--delete-branch-after-merge</code>:
              {locale === "zh" ? "成功合并后删除分支" : "Delete the branch after successful merge"}
            </li>
          </ul>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "示例" : "Examples"}
          </h3>
          <CodeBlock code={submitExamples} language="bash" />
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">gw rm</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            {locale === "zh"
              ? "删除本地分支，并可选择删除远程分支。"
              : "Deletes a branch locally and optionally remotely."}
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "语法" : "Syntax"}
          </h3>
          <CodeBlock code="gw rm <branch|all> [-f] [--delete-remotes]" language="bash" />
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "选项" : "Options"}
          </h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>
              <code>-f</code>:
              {locale === "zh"
                ? "即使分支有未合并的更改也强制删除"
                : "Force delete the branch even if it has unmerged changes"}
            </li>
            <li>
              <code>--delete-remotes</code>:
              {locale === "zh"
                ? "自动删除远程分支，无需确认"
                : "Automatically delete remote branches without confirmation"}
            </li>
          </ul>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "示例" : "Examples"}
          </h3>
          <CodeBlock code={rmExamples} language="bash" />
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">gw clean</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            {locale === "zh"
              ? "清理分支：切换到主分支，更新，然后删除指定分支。"
              : "Cleans up a branch by switching to main, updating, and deleting the specified branch."}
          </p>
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "语法" : "Syntax"}
          </h3>
          <CodeBlock code="gw clean <branch>" language="bash" />
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">
            {locale === "zh" ? "示例" : "Example"}
          </h3>
          <CodeBlock code={cleanExample} language="bash" />
        </div>
      </div>
    </DocContent>
  );
}
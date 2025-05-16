"use client";

import { useTranslation } from "@/hooks/use-translation";
import { DocContent } from "@/components/doc-content";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { CommandGroup } from "@/components/command-group";

interface CommandsPageContentProps {
  // lang: string; // lang can be passed if I18nProvider needs explicit lang
}

export function CommandsPageContent(props: CommandsPageContentProps) {
  const { t } = useTranslation();

  return (
    <DocContent title={t("docs.commands.title")} description={t("docs.commands.description")}>
      <Tabs defaultValue="core" className="w-full">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="core">{t("docs.commands.tabs.core")}</TabsTrigger>
          <TabsTrigger value="git">{t("docs.commands.tabs.git")}</TabsTrigger>
          <TabsTrigger value="repo">{t("docs.commands.tabs.repo")}</TabsTrigger>
          <TabsTrigger value="other">{t("docs.commands.tabs.other")}</TabsTrigger>
        </TabsList>
        <TabsContent value="core">
          <CommandGroup
            title={t("docs.commands.coreWorkflow.title")}
            description={t("docs.commands.coreWorkflow.description")}
            commands={[
              {
                name: "start",
                syntax: "gw start <branch> [--base <base>] [--local]",
                description: t("docs.commands.coreWorkflow.start"),
              },
              {
                name: "save",
                syntax: "gw save [-m msg] [-e] [files...]",
                description: t("docs.commands.coreWorkflow.save"),
              },
              {
                name: "sp",
                syntax: "gw sp [-m msg] [-e] [files...]",
                description: t("docs.commands.coreWorkflow.sp"),
              },
              {
                name: "update",
                syntax: "gw update",
                description: t("docs.commands.coreWorkflow.update"),
              },
              {
                name: "submit",
                syntax: "gw submit [--no-switch] [--pr] [-a|--auto-merge] [--delete-branch-after-merge]",
                description: t("docs.commands.coreWorkflow.submit"),
              },
              {
                name: "rm",
                syntax: "gw rm <branch|all> [-f]",
                description: t("docs.commands.coreWorkflow.rm"),
              },
              {
                name: "clean",
                syntax: "gw clean <branch>",
                description: t("docs.commands.coreWorkflow.clean"),
              },
            ]}
          />
        </TabsContent>
        <TabsContent value="git">
          <CommandGroup
            title={t("docs.commands.gitOperations.title")}
            description={t("docs.commands.gitOperations.description")}
            commands={[
              {
                name: "status",
                syntax: "gw status [-r] [-l]",
                description: t("docs.commands.gitOperations.status"),
              },
              {
                name: "add",
                syntax: "gw add [files...]",
                description: t("docs.commands.gitOperations.add"),
              },
              {
                name: "add-all",
                syntax: "gw add-all",
                description: t("docs.commands.gitOperations.addAll"),
              },
              {
                name: "commit",
                syntax: "gw commit [...]",
                description: t("docs.commands.gitOperations.commit"),
              },
              {
                name: "push",
                syntax: "gw push [...]",
                description: t("docs.commands.gitOperations.push"),
              },
              {
                name: "pull",
                syntax: "gw pull [...]",
                description: t("docs.commands.gitOperations.pull"),
              },
              {
                name: "fetch",
                syntax: "gw fetch [...]",
                description: t("docs.commands.gitOperations.fetch"),
              },
              {
                name: "branch",
                syntax: "gw branch [...]",
                description: t("docs.commands.gitOperations.branch"),
              },
              {
                name: "checkout",
                syntax: "gw checkout <branch>",
                description: t("docs.commands.gitOperations.checkout"),
              },
              {
                name: "merge",
                syntax: "gw merge <source> [...]",
                description: t("docs.commands.gitOperations.merge"),
              },
              {
                name: "log",
                syntax: "gw log [...]",
                description: t("docs.commands.gitOperations.log"),
              },
              {
                name: "diff",
                syntax: "gw diff [...]",
                description: t("docs.commands.gitOperations.diff"),
              },
              {
                name: "reset",
                syntax: "gw reset <target> [...]",
                description: t("docs.commands.gitOperations.reset"),
              },
              {
                name: "stash",
                syntax: "gw stash [subcommand] [...]",
                description: t("docs.commands.gitOperations.stash"),
              },
              {
                name: "rebase",
                syntax: "gw rebase <target> [...]",
                description: t("docs.commands.gitOperations.rebase"),
              },
              {
                name: "undo",
                syntax: "gw undo [--soft|--hard]",
                description: t("docs.commands.gitOperations.undo"),
              },
              {
                name: "unstage",
                syntax: "gw unstage [-i] [files...]",
                description: t("docs.commands.gitOperations.unstage"),
              },
            ]}
          />
        </TabsContent>
        <TabsContent value="repo">
          <CommandGroup
            title={t("docs.commands.repoConfig.title")}
            description={t("docs.commands.repoConfig.description")}
            commands={[
              {
                name: "init",
                syntax: "gw init [...]",
                description: t("docs.commands.repoConfig.init"),
              },
              {
                name: "config set-url",
                syntax: "gw config set-url <url>",
                description: t("docs.commands.repoConfig.setUrl"),
              },
              {
                name: "config set-url",
                syntax: "gw config set-url <name> <url>",
                description: t("docs.commands.repoConfig.setUrlNamed"),
              },
              {
                name: "config add-remote",
                syntax: "gw config add-remote <name> <url>",
                description: t("docs.commands.repoConfig.addRemote"),
              },
              {
                name: "config list",
                syntax: "gw config list | show",
                description: t("docs.commands.repoConfig.list"),
              },
              {
                name: "config",
                syntax: "gw config <usr> <eml> [--global|-g]",
                description: t("docs.commands.repoConfig.userConfig"),
              },
              {
                name: "config",
                syntax: "gw config [...]",
                description: t("docs.commands.repoConfig.config"),
              },
              {
                name: "remote",
                syntax: "gw remote [...]",
                description: t("docs.commands.repoConfig.remote"),
              },
              {
                name: "gh-create",
                syntax: "gw gh-create [repo] [...]",
                description: t("docs.commands.repoConfig.ghCreate"),
              },
              {
                name: "ide",
                syntax: "gw ide [name|cmd]",
                description: t("docs.commands.repoConfig.ide"),
              },
            ]}
          />
        </TabsContent>
        <TabsContent value="other">
          <CommandGroup
            title={t("docs.commands.oldPush.title")}
            description={t("docs.commands.oldPush.description")}
            commands={[
              {
                name: "1 | first",
                syntax: "gw 1 <branch> | gw first <branch>",
                description: t("docs.commands.oldPush.first"),
              },
              {
                name: "2",
                syntax: "gw 2",
                description: t("docs.commands.oldPush.main"),
              },
              {
                name: "3 | other",
                syntax: "gw 3 <branch> | gw other <branch>",
                description: t("docs.commands.oldPush.other"),
              },
              {
                name: "4 | current",
                syntax: "gw 4 | gw current",
                description: t("docs.commands.oldPush.current"),
              },
            ]}
          />
          <CommandGroup
            title={t("docs.commands.help.title")}
            description={t("docs.commands.help.description")}
            commands={[
              {
                name: "help",
                syntax: "gw help, --help, -h",
                description: t("docs.commands.help.help"),
              },
            ]}
          />
        </TabsContent>
      </Tabs>
    </DocContent>
  );
}
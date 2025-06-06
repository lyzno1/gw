export const en = {
  nav: {
    home: "Home",
    docs: "Documentation",
    bestPractices: "Best Practices",
    teamWorkflow: "Team Workflow",
  },
  home: {
    hero: {
      title: "GW - Git Workflow Assistant",
      subtitle: "Simplify your Git experience with a modern workflow assistant",
      getStarted: "Get Started",
    },
    features: {
      title: "Features",
      subtitle: "GW is designed to make your Git workflow more efficient and less error-prone",
      workflow: {
        title: "Workflow-Centric",
        description: "Commands are designed around common development workflows, not just Git operations",
      },
      standardization: {
        title: "Clean History",
        description: "Encourages best practices for maintaining a clean, linear Git history",
      },
      efficiency: {
        title: "Efficiency",
        description: "Reduce keystrokes and mental overhead with intuitive, high-level commands",
      },
      robust: {
        title: "Robust & Reliable",
        description: "Built-in retry mechanisms and safety checks to prevent common mistakes",
      },
      team: {
        title: "Team Friendly",
        description: "Standardize Git workflows across your team with consistent commands",
      },
      extensible: {
        title: "Extensible",
        description: "Easily extend with custom commands to fit your team's specific needs",
      },
    },
    cta: {
      title: "Ready to simplify your Git workflow?",
      subtitle: "Get started with GW today and focus on what matters - your code.",
      install: "Installation Guide",
    },
  },
  sidebar: {
    gettingStarted: "Getting Started",
    introduction: "Introduction",
    installation: "Installation",
    quickStart: "Quick Start",
    commands: "Commands",
    commandsOverview: "Overview",
    coreWorkflow: "Core Workflow",
    gitOperations: "Git Operations",
    repoManagement: "Repository Management",
    guides: "Guides",
    bestPractices: "Best Practices",
    teamWorkflow: "Team Workflow",
    troubleshooting: "Troubleshooting",
    advanced: "Advanced",
    customization: "Customization",
    extending: "Extending GW",
  },
  docs: {
    gettingStarted: {
      title: "Getting Started with GW",
      description: "Learn how to install and configure GW for your development workflow",
      installation: {
        title: "Installation",
        description: "To install GW, clone the repository and make the scripts executable:",
      },
      configuration: {
        title: "Configuration",
        description: "Add GW to your PATH or create an alias in your shell configuration file:",
      },
      verification: {
        title: "Verification",
        description: "Verify that GW is installed correctly by running the help command:",
      },
    },
    commands: {
      title: "Command Reference",
      description: "Complete reference of all GW commands",
      tabs: {
        core: "Core Workflow",
        git: "Git Operations",
        repo: "Repository & Config",
        other: "Other",
      },
      coreWorkflow: {
        title: "Core Workflow Commands",
        description: "These commands represent the main development workflow",
        start:
          "Create a new branch from the base branch (default: main) and start working. Automatically handles stash, updates the base branch.",
        save: "Quickly save changes (add+commit). Adds all changes by default.",
        sp: "Quickly save all changes and push to remote (save && push).",
        update: "Update current branch: sync with main if on feature branch, pull if on main branch.",
        submit: "Submit branch work: save/push, optionally create PR (-p), optionally don't switch (-n).",
        rm: "Delete local branch, and ask whether to delete remote branch of the same name.",
        clean: "Clean up branch: switch to main branch, update, then call 'gw rm' to delete specified branch.",
      },
      gitOperations: {
        title: "Git Operations",
        description: "Enhanced wrappers around common Git operations",
        status: "Show working directory status (enhanced: includes remote comparison, optional log).",
        add: "Add files to staging area (interactive selection if no parameters).",
        addAll: "Add all changes to staging area (git add -A).",
        commit: "Commit staged changes (wraps native commit, behavior depends on native if no -m/-F).",
        push: "Push local commits (with retry, automatic -u handling, remote checks).",
        pull: "Pull updates (with retry, default uses --rebase).",
        fetch: "Fetch remote updates without merging (native fetch wrapper).",
        branch: "Display local branches (no parameters); native 'git branch' operation (with parameters).",
        checkout: "Switch branches (checks for uncommitted changes, interactive selection if no parameters).",
        merge: "Merge specified branch into current (checks for uncommitted changes).",
        log: "Show commit history (auto-pagination, supports native log parameters).",
        diff: "Show changes (native diff wrapper).",
        reset: "Reset HEAD (with strong confirmation for --hard).",
        stash: "Stash working directory changes (wraps common stash subcommands, confirms for clear).",
        rebase: "Rebase current branch (enhanced: auto-updates target, handles stash).",
        undo: "Undo last commit. Default returns to working directory, --soft keeps staged, --hard discards.",
        unstage: "Move staged changes back to working directory. Default all, -i interactive, can specify files.",
      },
      repoConfig: {
        title: "Repository Management & Configuration",
        description: "Commands for managing repositories and configuration",
        init: "Initialize Git repository (native init wrapper).",
        setUrl: "Set URL for 'origin' (add if it doesn't exist).",
        setUrlNamed: "Set URL for specified remote (add if it doesn't exist).",
        addRemote: "Add a new remote repository.",
        list: "Show 'gw' script configuration and some Git user configuration.",
        userConfig: "Quickly set local (default) or global (--global or -g) username/email.",
        config: "Other parameters will be passed to native 'git config'.",
        remote: "Manage remote repositories (native remote wrapper).",
        ghCreate: "Create repository on GitHub and associate it (requires 'gh' CLI).",
        ide: "Set or display the default editor used by 'gw save' when editing commit messages.",
      },
      oldPush: {
        title: "Old Push Aliases",
        description: "Compatible commands from previous versions",
        first: "First push of specified branch (with -u).",
        main: "Push main branch.",
        other: "Push existing specified branch.",
        current: "Push current branch (automatically handles -u).",
      },
      help: {
        title: "Help",
        description: "Display help information",
        help: "Display this help information.",
      },
    },
  },
  ui: {
    copyCode: "Copy code",
    copied: "Copied",
    toggleTheme: "Toggle theme",
    toggleLanguage: "Toggle language",
    lightMode: "Light mode",
    darkMode: "Dark mode",
    systemMode: "System mode",
    english: "English",
    chinese: "Chinese",
    menu: "Menu",
    close: "Close",
    search: "Search",
    moreInfo: "More information",
    learnMore: "Learn more",
    example: "Example",
    note: "Note",
    warning: "Warning",
    tip: "Tip",
    seeAlso: "See also",
    relatedCommands: "Related commands",
    syntax: "Syntax",
    options: "Options",
    arguments: "Arguments",
    returns: "Returns",
    examples: "Examples",
    description: "Description",
  },
}

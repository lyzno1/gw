export const zh = {
  nav: {
    home: "首页",
    docs: "文档",
    bestPractices: "最佳实践",
    teamWorkflow: "团队工作流",
  },
  home: {
    hero: {
      title: "GW - Git 工作流助手",
      subtitle: "通过现代工作流助手简化您的 Git 体验",
      getStarted: "开始使用",
    },
    features: {
      title: "特性",
      subtitle: "GW 旨在使您的 Git 工作流更高效，更少出错",
      workflow: {
        title: "以工作流为中心",
        description: "命令围绕常见开发工作流设计，而不仅仅是 Git 操作",
      },
      standardization: {
        title: "整洁历史",
        description: "鼓励维护干净、线性的 Git 历史的最佳实践",
      },
      efficiency: {
        title: "高效",
        description: "通过直观的高级命令减少按键次数和心智负担",
      },
      robust: {
        title: "健壮可靠",
        description: "内置重试机制和安全检查，防止常见错误",
      },
      team: {
        title: "团队友好",
        description: "通过一致的命令标准化团队的 Git 工作流",
      },
      extensible: {
        title: "可扩展",
        description: "轻松扩展自定义命令以满足团队的特定需求",
      },
    },
    cta: {
      title: "准备简化您的 Git 工作流？",
      subtitle: "立即开始使用 GW，专注于真正重要的事情 - 您的代码。",
      install: "安装指南",
    },
  },
  sidebar: {
    gettingStarted: "入门",
    introduction: "介绍",
    installation: "安装",
    quickStart: "快速开始",
    commands: "命令",
    commandsOverview: "概览",
    coreWorkflow: "核心工作流",
    gitOperations: "Git 操作",
    repoManagement: "仓库管理",
    guides: "指南",
    bestPractices: "最佳实践",
    teamWorkflow: "团队工作流",
    troubleshooting: "故障排除",
    advanced: "高级",
    customization: "自定义",
    extending: "扩展 GW",
  },
  docs: {
    gettingStarted: {
      title: "GW 入门",
      description: "了解如何为您的开发工作流安装和配置 GW",
      installation: {
        title: "安装",
        description: "要安装 GW，克隆仓库并使脚本可执行：",
      },
      configuration: {
        title: "配置",
        description: "将 GW 添加到您的 PATH 或在 shell 配置文件中创建别名：",
      },
      verification: {
        title: "验证",
        description: "通过运行帮助命令验证 GW 是否正确安装：",
      },
    },
    commands: {
      title: "命令参考",
      description: "所有 GW 命令的完整参考",
      tabs: {
        core: "核心工作流",
        git: "Git 操作",
        repo: "仓库与配置",
        other: "其他",
      },
      coreWorkflow: {
        title: "核心工作流命令",
        description: "这些命令代表主要开发工作流",
        start: "从基础分支（默认：main）创建新分支并开始工作。自动处理 stash，更新基础分支。",
        save: "快速保存更改（add+commit）。默认添加所有更改。",
        sp: "快速保存所有更改并推送到远程（save && push）。",
        update: "更新当前分支：如果在特性分支上则与主干同步，如果在主干上则拉取。",
        submit: "提交分支工作：保存/推送，可选创建 PR (-p)，可选不切换 (-n)。",
        rm: "删除本地分支，并询问是否删除同名远程分支。",
        clean: "清理分支：切换到主分支，更新，然后调用 'gw rm' 删除指定分支。",
      },
      gitOperations: {
        title: "Git 操作",
        description: "常见 Git 操作的增强封装",
        status: "显示工作目录状态（增强版：包含远程比较，可选日志）。",
        add: "将文件添加到暂存区（无参数则交互式选择）。",
        addAll: "将所有更改添加到暂存区（git add -A）。",
        commit: "提交暂存的更改（封装原生 commit，无 -m/-F 时行为依赖原生）。",
        push: "推送本地提交（带重试，自动处理 -u，远程检查）。",
        pull: "拉取更新（带重试，默认使用 --rebase）。",
        fetch: "获取远程更新，不合并（原生 fetch 包装器）。",
        branch: "（无参数）显示本地分支；（带参数）原生 'git branch' 操作。",
        checkout: "切换分支（检查未提交更改，无参数可交互选择）。",
        merge: "合并指定分支到当前（检查未提交更改）。",
        log: "显示提交历史（自动分页，支持原生 log 参数）。",
        diff: "显示变更差异（原生 diff 包装器）。",
        reset: "重置 HEAD（对 --hard 有强确认）。",
        stash: "暂存工作区变更（封装常用 stash 子命令，对 clear 有确认）。",
        rebase: "Rebase 当前分支（增强版：自动更新目标，处理 stash）。",
        undo: "撤销上一次提交。默认放回工作区，--soft 保留暂存，--hard 丢弃。",
        unstage: "将暂存区更改移回工作区。默认全部，-i 交互，可指定文件。",
      },
      repoConfig: {
        title: "仓库管理与配置",
        description: "用于管理仓库和配置的命令",
        init: "初始化 Git 仓库（原生 init 包装器）。",
        setUrl: "设置 'origin' 的 URL（若不存在则添加）。",
        setUrlNamed: "设置指定远程的 URL（若不存在则添加）。",
        addRemote: "添加新的远程仓库。",
        list: "显示 'gw' 脚本配置和部分 Git 用户配置。",
        userConfig: "快速设置本地（默认）或全局（--global 或 -g）用户名/邮箱。",
        config: "其他参数将透传给原生 'git config'。",
        remote: "管理远程仓库（原生 remote 包装器）。",
        ghCreate: "在 GitHub 创建仓库并关联（需要 'gh' CLI）。",
        ide: "设置或显示 'gw save' 编辑提交信息时默认使用的编辑器。",
      },
      oldPush: {
        title: "旧版推送命令",
        description: "兼容以前版本的命令",
        first: "首次推送指定分支（带 -u）。",
        main: "推送主分支。",
        other: "推送已存在的指定分支。",
        current: "推送当前分支（自动处理 -u）。",
      },
      help: {
        title: "帮助",
        description: "显示帮助信息",
        help: "显示此帮助信息。",
      },
    },
    gitOperations: {
      title: "Git 操作命令",
      description: "增强的 Git 操作命令，提供更好的可用性",
      status: {
        title: "gw status",
        description: "显示工作目录状态，带有增强信息",
        syntax: "gw status [-r] [-l]",
        options: {
          r: "包含远程分支比较信息",
          l: "包含最近提交日志信息"
        },
        examples: {
          basic: "显示基本状态",
          remote: "显示带远程比较的状态",
          log: "显示带最近提交的状态",
          both: "显示带远程比较和最近提交的状态"
        }
      },
      add: {
        title: "gw add",
        description: "将文件添加到暂存区，无文件指定时进行交互式选择",
        syntax: "gw add [文件...]",
        behavior: {
          noArgs: "无参数时：打开交互式选择菜单选择要暂存的文件",
          withArgs: "带文件参数时：暂存指定的文件"
        },
        examples: {
          interactive: "交互式文件选择",
          specific: "添加特定文件"
        }
      },
      commit: {
        title: "gw commit",
        description: "提交暂存的更改，带增强的消息处理",
        syntax: "gw commit [-m \"消息\"] [-e] [...]",
        options: {
          m: "指定提交消息",
          e: "强制打开编辑器编辑提交消息"
        },
        examples: {
          withMessage: "带消息提交",
          withEditor: "打开编辑器提交",
          amend: "修改上一次提交"
        }
      },
      push: {
        title: "gw push",
        description: "推送本地提交到远程，带自动重试和上游处理",
        syntax: "gw push [远程] [分支] [...]",
        features: {
          upstream: "自动处理新分支的 -u（设置上游）",
          retry: "内置网络重试机制，适用于不稳定连接",
          checks: "推送前检查未提交的更改"
        },
        examples: {
          current: "推送当前分支",
          specific: "推送到特定远程",
          branch: "推送特定分支",
          force: "强制推送（谨慎使用）"
        }
      },
      pull: {
        title: "gw pull",
        description: "从远程拉取更新，默认使用 rebase 策略",
        syntax: "gw pull [远程] [分支] [...]",
        features: {
          rebase: "默认使用 --rebase 策略，保持更整洁的历史",
          retry: "内置网络重试机制",
          override: "可以使用 --no-rebase 或其他 git pull 选项覆盖"
        },
        examples: {
          default: "使用 rebase 从当前分支的上游拉取",
          specific: "从特定远程和分支拉取",
          noRebase: "不使用 rebase 拉取"
        }
      }
    },
    repoManagement: {
      title: "仓库管理命令",
      description: "用于管理仓库和配置的命令",
      init: {
        title: "gw init",
        description: "初始化 Git 仓库，带增强设置",
        syntax: "gw init [...]",
        options: {
          passthrough: "任何传递给 git init 的选项"
        },
        examples: {
          basic: "在当前目录初始化仓库",
          branch: "使用特定分支名初始化"
        }
      },
      configSetUrl: {
        title: "gw config set-url",
        description: "设置远程仓库的 URL，如果不存在则添加",
        syntax: "gw config set-url <url>\ngw config set-url <name> <url>",
        examples: {
          origin: "设置 origin 的 URL",
          specific: "设置特定远程的 URL"
        }
      },
      configAddRemote: {
        title: "gw config add-remote",
        description: "添加新的远程仓库",
        syntax: "gw config add-remote <name> <url>",
        examples: {
          upstream: "添加新的远程仓库"
        }
      },
      ghCreate: {
        title: "gw gh-create",
        description: "在 GitHub 上创建仓库并与本地仓库关联",
        syntax: "gw gh-create [repo] [...]",
        requirements: {
          gh: "必须安装并认证 GitHub CLI (gh)"
        },
        examples: {
          default: "使用当前目录名创建公共仓库",
          named: "使用特定名称创建仓库",
          private: "创建私有仓库"
        }
      },
      ide: {
        title: "gw ide",
        description: "设置或显示 'gw save' 编辑提交消息时使用的默认编辑器",
        syntax: "gw ide [name|cmd]",
        options: {
          name: "预定义编辑器短名称（如 vscode、vim、nano）",
          cmd: "完整编辑器命令（如 \"code --wait\"）"
        },
        examples: {
          show: "显示当前编辑器设置",
          vscode: "设置编辑器为 VS Code",
          vim: "设置编辑器为 Vim",
          custom: "设置自定义编辑器命令"
        }
      }
    },
    bestPractices: {
      title: "最佳实践",
      description: "使用 GW 的推荐实践",
      branchNaming: {
        title: "分支命名约定",
        description: "一致的分支命名有助于团队成员一目了然地理解每个分支的用途。",
        pattern: "推荐模式",
        types: "常见类型包括：",
        typeFeature: "feature：新功能",
        typeBugfix: "bugfix：Bug 修复",
        typeHotfix: "hotfix：紧急生产修复",
        typeRefactor: "refactor：不改变功能的代码改进",
        typeDocs: "docs：文档更改",
        typeTest: "test：添加或改进测试",
        examples: "示例"
      },
      commitMessage: {
        title: "提交消息指南",
        description: "结构良好的提交消息使您的仓库历史更有用且可读。",
        conventional: "约定式提交",
        conventionalDescription: "考虑使用约定式提交格式：",
        example: "例如：",
        structure: "提交消息结构",
        structureItems: {
          imperative: "使用祈使语气（Add feature 而非 Added feature）",
          length: "保持第一行不超过50个字符",
          detail: "需要时在提交正文中添加详细说明",
          reference: "适用时引用问题编号"
        }
      },
      regularUpdates: {
        title: "定期更新",
        description: "保持功能分支与主分支同步可减少合并冲突和集成问题。",
        frequency: "更新频率",
        frequencyItems: {
          daily: "每天至少更新一次功能分支",
          beforePR: "提交拉取请求前始终更新",
          afterChanges: "主分支有重大变更后更新"
        }
      },
      cleanHistory: {
        title: "整洁历史",
        description: "维护整洁、线性的历史使项目演变更易于理解，也更容易找到bug。",
        tips: "整洁历史的技巧",
        tipsItems: {
          rebase: "更新分支时使用 GW 的默认 rebase 策略",
          squash: "考虑在合并到主分支前压缩提交（例如，gw submit --squash）",
          focused: "保持提交专注于单一逻辑变更",
          interactive: "提交前使用交互式 rebase 清理分支"
        },
        workflow: "示例工作流"
      },
      branchCleanup: {
        title: "分支清理",
        description: "定期清理已合并的分支保持仓库整洁和专注。",
        strategies: "清理策略",
        strategiesItems: {
          immediate: "分支合并后立即清理",
          periodic: "定期审查并清理所有已合并分支",
          automatic: "考虑使用合并后自动删除分支"
        }
      }
    },
    teamWorkflow: {
      title: "团队工作流",
      description: "在团队环境中使用 GW 的最佳实践",
      standardizing: {
        title: "标准化工作流",
        description: "GW 的一个关键优势是在团队中标准化 Git 工作流。这减少了混淆，最小化了错误，并使新团队成员的入职更容易。",
        steps: "团队采用步骤",
        stepsItems: {
          install: "为所有团队成员安装 GW",
          document: "基于 GW 命令创建团队工作流文档",
          training: "进行简短的培训会话",
          ci: "设置 CI 检查以强制执行工作流标准"
        }
      },
      featureBranch: {
        title: "功能分支工作流",
        description: "使用 GW 的常见团队工作流遵循功能分支模型，每个功能、错误修复或任务都在自己的分支中开发。",
        steps: "工作流步骤",
        stepsItems: {
          start: "开始一个功能：",
          changes: "进行更改并定期提交：",
          sync: "与主分支保持同步：",
          push: "推送更改以备份或共享：",
          submit: "提交审核：",
          feedback: "处理审核反馈：",
          cleanup: "合并后清理："
        }
      },
      codeReview: {
        title: "代码审核流程",
        description: "GW 可以通过确保分支在审核前正确准备来简化代码审核流程。",
        checklist: "审核前检查清单",
        checklistItems: {
          update: "用最新的主分支更新分支：",
          tests: "确保所有测试通过",
          history: "如果需要，清理提交历史",
          pr: "提交带有描述性 PR 标题："
        },
        reviewer: "审核者工作流",
        reviewerItems: {
          checkout: "检出 PR 分支：",
          review: "审核代码，运行测试等",
          feedback: "在 PR 上提供反馈",
          approve: "准备好时批准并合并"
        }
      },
      releaseManagement: {
        title: "发布管理",
        description: "GW 可以通过为发布分支提供一致的工作流来帮助管理发布。",
        workflow: "发布分支工作流",
        workflowItems: {
          create: "创建发布分支：",
          adjust: "进行最终调整：",
          tag: "标记发布：",
          push: "推送标签：",
          merge: "合并回主分支：",
          cleanup: "清理："
        }
      },
      hotfixes: {
        title: "处理热修复",
        description: "当需要修复生产中的关键问题时，GW 提供了一致的热修复工作流。",
        workflow: "热修复工作流",
        workflowItems: {
          create: "从生产标签创建热修复分支：",
          fix: "修复问题：",
          tag: "创建新的补丁版本标签：",
          push: "推送修复和标签：",
          merge: "合并回主分支：",
          cleanup: "清理："
        }
      }
    },
    troubleshooting: {
      title: "故障排除",
      description: "使用 GW 时常见问题的解决方案",
      commonIssues: {
        title: "常见问题",
        description: "以下是使用 GW 时可能遇到的一些常见问题的解决方案。",
        commandNotFound: {
          title: "命令未找到",
          description: "如果尝试使用 GW 时看到\"命令未找到\"，请检查您的安装：",
          items: {
            permissions: "验证脚本具有执行权限：",
            alias: "检查您的别名是否在 shell 配置文件中正确设置",
            source: "确保您已经加载了更新的 shell 配置："
          }
        },
        mergeConflicts: {
          title: "合并冲突",
          description: "当 gw update 导致合并冲突时：",
          items: {
            resolve: "在编辑器中解决冲突",
            mark: "将文件标记为已解决：",
            continue: "继续 rebase：",
            abort: "如果需要中止："
          }
        },
        networkIssues: {
          title: "网络问题",
          description: "如果您遇到网络相关的失败，尽管 GW 有重试机制：",
          items: {
            connection: "检查您的互联网连接",
            credentials: "验证您的 SSH 密钥或凭据设置正确",
            retry: "尝试增加重试次数：",
            direct: "检查是否可以直接使用 Git 访问远程仓库"
          }
        }
      },
      recovering: {
        title: "从错误中恢复",
        undoCommit: {
          title: "撤销最后一次提交",
          description: "如果需要撤销最后一次提交：",
          examples: {
            keep: "保留工作目录中的更改",
            staged: "保留已暂存的更改",
            discard: "完全丢弃更改"
          }
        },
        deletedBranches: {
          title: "恢复已删除的分支",
          description: "如果意外删除了分支：",
          steps: {
            find: "找到分支尖端的提交哈希：",
            recreate: "重新创建分支："
          }
        },
        badRebase: {
          title: "修复错误的 rebase",
          description: "如果 rebase 出错，需要重新开始："
        }
      },
      envVars: {
        title: "环境变量",
        description: "GW 的行为可以通过环境变量自定义：",
        available: {
          title: "可用变量",
          items: {
            mainBranch: "默认主分支名称（默认：main 或 master）",
            remoteName: "默认远程名称（默认：origin）",
            maxAttempts: "网络操作的重试次数（默认：3）",
            delaySeconds: "重试尝试之间的延迟秒数（默认：2）"
          }
        },
        setting: {
          title: "设置变量",
          description: "您可以在 shell 配置文件中或在运行命令前设置这些变量："
        }
      },
      debugging: {
        title: "调试 GW",
        description: "如果需要对 GW 本身进行故障排除：",
        debug: {
          title: "启用调试模式",
          description: "使用 bash 的调试模式运行 GW 以查看发生了什么："
        },
        config: {
          title: "检查 GW 配置",
          description: "查看当前的 GW 配置："
        },
        permissions: {
          title: "检查脚本权限",
          description: "确保所有脚本具有正确的权限："
        }
      }
    },
    customization: {
      title: "自定义",
      description: "自定义 GW 以适应团队的特定工作流需求",
      configOptions: {
        title: "配置选项",
        description: "GW 可以通过环境变量和配置文件进行自定义，以匹配您团队的工作流。",
        envVars: {
          title: "环境变量",
          description: "在 shell 配置文件（.bashrc、.zshrc）中设置这些变量以进行持久自定义："
        },
        editor: {
          title: "编辑器配置",
          description: "配置您偏好的提交消息编辑器："
        }
      },
      coreFiles: {
        title: "自定义核心文件",
        description: "对于更高级的自定义，您可以直接修改 GW 的核心文件。",
        configVars: {
          title: "配置变量",
          description: "编辑 core_utils/config_vars.sh 以更改默认设置："
        },
        commandBehavior: {
          title: "命令行为",
          description: "在 actions/ 目录中修改命令实现：",
          items: {
            start: "actions/start_branch.sh：自定义分支创建行为",
            save: "actions/save_changes.sh：修改如何保存更改",
            update: "actions/update_branch.sh：更改分支更新方式",
            submit: "actions/submit_work.sh：自定义提交流程"
          },
          warning: "修改这些文件前务必备份！"
        }
      },
      commitTemplates: {
        title: "自定义提交模板",
        description: "创建自定义提交消息模板以标准化团队的提交消息。",
        creating: {
          title: "创建模板",
          description: "创建包含您模板的文件："
        },
        configuring: {
          title: "配置 Git 使用模板",
          description: "设置 Git 使用您的模板：",
          note: "现在当您运行 gw save 而不带消息时，将使用您的模板。"
        }
      },
      projectSpecific: {
        title: "项目特定配置",
        description: "您可以使用 Git 钩子和本地环境变量创建项目特定的 GW 配置。",
        envFiles: {
          title: "使用 .env 文件",
          description: "在项目根目录创建 .env.gw 文件：",
          sourcing: "然后在项目的 Git 钩子或项目特定别名中加载此文件："
        }
      },
      customAliases: {
        title: "自定义别名",
        description: "为常用的 GW 命令组合创建自定义别名。",
        shell: {
          title: "Shell 别名",
          description: "将这些添加到您的 shell 配置文件："
        },
        git: {
          title: "Git 别名",
          description: "您还可以创建使用 GW 的 Git 别名：",
          usage: "然后像这样使用它们："
        }
      }
    },
    extending: {
      title: "扩展 GW",
      description: "使用自定义命令和功能扩展 GW",
      addingCommands: {
        title: "添加自定义命令",
        description: "GW 的模块化设计使添加自己的自定义命令变得容易。",
        creating: {
          title: "创建命令文件",
          description: "在 actions/ 目录中创建新文件："
        },
        registering: {
          title: "注册命令",
          description: "将您的命令添加到 git_workflow.sh：",
          steps: {
            source: "在顶部附近与其他操作一起加载您的命令文件",
            case: "在主函数的 case 语句中添加您的命令"
          }
        },
        executable: {
          title: "使其可执行",
          description: "使您的命令文件可执行："
        },
        using: {
          title: "使用您的命令",
          description: "现在您可以使用您的自定义命令："
        }
      },
      bestPractices: {
        title: "命令最佳实践",
        description: "创建自定义命令时遵循这些最佳实践：",
        structure: {
          title: "结构和文档",
          items: {
            header: "以清晰的注释头开始，解释命令的目的",
            dependencies: "列出依赖项和所需环境",
            prefix: "为主函数使用 cmd_ 前缀",
            help: "将您的命令添加到 actions/show_help.sh 中的帮助文本"
          }
        },
        errorHandling: {
          title: "错误处理",
          items: {
            required: "检查所需参数",
            validate: "在继续前验证输入",
            utils: "使用实用函数进行常见检查",
            messages: "提供清晰的错误消息",
            exit: "返回适当的退出代码"
          }
        },
        feedback: {
          title: "用户反馈",
          items: {
            color: "一致地使用颜色编码（参见 core_utils/colors.sh）",
            progress: "为长时间运行的操作提供进度信息",
            completion: "确认成功完成",
            verbose: "考虑添加 --verbose 标志以获取详细输出"
          }
        },
        utilityFunctions: {
          title: "实用函数",
          description: "GW 提供了几个您可以在自定义命令中使用的实用函数。",
          common: {
            title: "常用实用工具",
            items: {
              checkGitRepo: "check_git_repo：确保当前目录是 Git 仓库",
              checkRemoteExists: "check_remote_exists：检查远程是否存在",
              checkBranchExists: "check_branch_exists：验证分支是否存在",
              getCurrentBranch: "get_current_branch：获取当前分支的名称",
              hasUncommittedChanges: "has_uncommitted_changes：检查未提交的更改",
              confirmAction: "confirm_action：提示用户确认"
            }
          },
          example: {
            title: "示例用法"
          }
        },
        advancedExtensions: {
          title: "高级扩展",
          description: "除了简单的命令外，您还可以以更高级的方式扩展 GW。",
          gitHooks: {
            title: "Git 钩子集成",
            description: "创建安装或管理 Git 钩子的命令："
          },
          projectTemplates: {
            title: "项目模板",
            description: "创建用于使用标准文件初始化项目的命令："
          },
          integration: {
            title: "与其他工具集成",
            description: "创建与其他开发工具集成的命令"
          }
        }
      }
    }
  },
  ui: {
    copyCode: "复制代码",
    copied: "已复制",
    toggleTheme: "切换主题",
    toggleLanguage: "切换语言",
    lightMode: "浅色模式",
    darkMode: "深色模式",
    systemMode: "系统模式",
    english: "英文",
    chinese: "中文",
    menu: "菜单",
    close: "关闭",
    search: "搜索",
    moreInfo: "更多信息",
    learnMore: "了解更多",
    example: "示例",
    note: "注意",
    warning: "警告",
    tip: "提示",
    seeAlso: "另见",
    relatedCommands: "相关命令",
    syntax: "语法",
    options: "选项",
    arguments: "参数",
    returns: "返回",
    examples: "示例",
    description: "描述"
  }
}

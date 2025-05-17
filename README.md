# `gw` (Git Workflow)：告别繁琐，拥抱流畅——您的智能 Git 工作流引擎

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 为什么选择 `gw`？

`gw` 的诞生源于一个简单的理念：**Git 应当是开发的助力，而非阻力**。通过将行业最佳实践与高效工作流相结合，`gw` 让开发者能将更多时间投入到真正创造价值的编码工作中。

**您将获得：**

- **效率提升**：减少重复的 Git 命令序列，专注于实际开发
- **规范协作**：统一的工作流程，帮助团队维护清晰、线性的主干历史
- **更安全可靠**：智能检查机制和自动重试，降低误操作风险
- **简单易学**：直观的命令名称，符合开发流程的自然思维

## 🚀 核心特性

### 流程驱动的工作方式

```
# 开始新功能开发
gw start feature/amazing-feature

# 保存工作进度
gw save -m "实现了新功能的核心逻辑"

# 与主分支保持同步
gw update

# 提交工作成果
gw submit --pr
```

### 设计理念

1. **流程优先，而非命令优先**
   - 每个命令代表开发周期中的实际意图和位置
   - 简化多步操作为单一、符合直觉的命令

2. **默认安全、交互友好**
   - 彩色输出，清晰的状态提示
   - 智能检查防止误操作
   - 破坏性操作需确认

3. **规范与灵活平衡**
   - 鼓励使用 rebase 保持历史整洁
   - 智能处理分支同步和提交

## 📚 详细文档

访问我们的[在线文档](https://your-docs-url-here)了解更多功能和用法。

## 🔧 安装

1. **克隆仓库**:
   ```bash
   git clone https://github.com/lyzno1/gw.git
   cd gw 
   ```

2. **赋予执行权限**:
   ```bash
   chmod +x git_workflow.sh
   chmod +x actions/*.sh
   ```

3. **选择安装方式**:

   - **添加到 PATH** (推荐):
     ```bash
     # 在 ~/.bashrc 或 ~/.zshrc 中添加
     export PATH="/path/to/your/gw:$PATH"
     ```

   - **创建别名**:
     ```bash
     # 在 ~/.bashrc 或 ~/.zshrc 中添加
     alias gw="/path/to/your/gw/git_workflow.sh"
     ```

4. **验证安装**:
   ```bash
   gw help
   ```

## 适用人群

- 追求高效开发流程的个人开发者
- 希望规范团队 Git 实践的技术负责人
- 渴望简化版本控制体验的团队
- Git 新手和有经验的开发者都能从中受益

## 许可证

本项目采用 MIT 许可证 - 详情请参见 [LICENSE](LICENSE) 文件。

# GW - Git Workflow Assistant

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A modern Git workflow assistant to simplify your Git experience.

## Features

- **Workflow-Centric**: Commands designed around common development workflows
- **Clean History**: Encourages best practices for maintaining a clean, linear Git history
- **Efficiency**: Reduce keystrokes and mental overhead with intuitive, high-level commands
- **Robust & Reliable**: Built-in retry mechanisms and safety checks to prevent common mistakes
- **Team Friendly**: Standardize Git workflows across your team with consistent commands

## Quick Start

\`\`\`bash
# Clone the repository
git clone https://github.com/lyzno1/gw.git

# Make scripts executable
cd gw
chmod +x git_workflow.sh
chmod +x actions/*.sh

# Add to your shell configuration
alias gw="/path/to/your/gw/git_workflow.sh"

# Start using GW
gw help
\`\`\`

## Basic Workflow

\`\`\`bash
# Start a new feature
gw start feature/my-awesome-feature

# Make changes and save your work
gw save -m "Add new feature"

# Keep your branch up to date
gw update

# Submit your work
gw submit --pr

# Clean up when done
gw clean feature/my-awesome-feature
\`\`\`

## Documentation

For complete documentation, visit [our documentation site](https://gw-docs.example.com).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

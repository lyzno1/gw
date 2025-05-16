import type { Metadata } from "next"
import { useTranslation } from "@/hooks/use-translation"
import { DocContent } from "@/components/doc-content"

export const metadata: Metadata = {
  title: "Extending GW | GW Documentation",
  description: "Learn how to extend GW with custom commands and functionality",
}

export default function ExtendingPage() {
  const { t } = useTranslation()

  return (
    <DocContent
      title={t("sidebar.extending")}
      description="Extend GW with custom commands and functionality"
    >
      <div className="space-y-10">
        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Adding Custom Commands</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            GW's modular design makes it easy to add your own custom commands.
          </p>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Creating a Command File</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Create a new file in the <code>actions/</code> directory:
          </p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              #!/bin/bash
              # File: actions/my_custom_command.sh
              #
              # Implements a custom command for GW
              #
              # Dependencies:
              # - colors.sh (color definitions)
              # - utils.sh (utility functions)
              # Define the command function
              cmd_custom() {
                # Source the colors file to get color definitions
                source "$SCRIPT_DIR/core_utils/colors.sh"

                echo -e "${GREEN}Running custom command...${NC}"
                # Your command logic here
                # Example: accessing parameters
                echo "Parameters: $@"
                # Example: using utility functions from utils.sh
                check_git_repo
                # Example: running git commands
                git status
                # Return success
                exit 0
              }
            </code>
          </pre>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Registering the Command</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Add your command to <code>git_workflow.sh</code>:
          </p>
          <ol className="my-6 ml-6 list-decimal [&>li]:mt-2">
            <li>Source your command file near the top with the other actions</li>
            <li>Add your command to the case statement in the main function</li>
          </ol>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              # In git_workflow.sh
              # 1. Source your command file
              source "$SCRIPT_DIR/actions/my_custom_command.sh"

              # 2. Add to case statement
              case "$cmd" in
                # ... existing commands ...
                custom)
                  shift
                  cmd_custom "$@"
                  ;;
                # ... more existing commands ...
              esac
            </code>
          </pre>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Making It Executable</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Make your command file executable:
          </p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">chmod +x actions/my_custom_command.sh</code>
          </pre>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Using Your Command</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Now you can use your custom command:
          </p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">gw custom [parameters]</code>
          </pre>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Command Best Practices</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Follow these best practices when creating custom commands:
          </p>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Structure and Documentation</h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>Start with a clear comment header explaining the command's purpose</li>
            <li>List dependencies and required environment</li>
            <li>Use the <code>cmd_</code> prefix for your main function</li>
            <li>Add your command to the help text in <code>actions/show_help.sh</code></li>
          </ul>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Error Handling</h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>Check for required parameters</li>
            <li>Validate input before proceeding</li>
            <li>Use the utility functions for common checks</li>
            <li>Provide clear error messages</li>
            <li>Return appropriate exit codes</li>
          </ul>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              # Example error handling
              # Source the colors file to get color definitions
              source "$SCRIPT_DIR/core_utils/colors.sh"

              if [ -z "$1" ]; then
                echo -e "${RED}Error: Missing required parameter${NC}"
                return 1
              fi
            </code>
          </pre>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">User Feedback</h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li>Use color coding consistently (see <code>core_utils/colors.sh</code>)</li>
            <li>Provide progress information for long-running operations</li>
            <li>Confirm successful completion</li>
            <li>Consider adding a --verbose flag for detailed output</li>
          </ul>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Utility Functions</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            GW provides several utility functions you can use in your custom commands.
          </p>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Common Utilities</h3>
          <ul className="my-6 ml-6 list-disc [&>li]:mt-2">
            <li><code>check_git_repo</code>: Ensures the current directory is a Git repository</li>
            <li><code>check_remote_exists</code>: Checks if a remote exists</li>
            <li><code>check_branch_exists</code>: Verifies if a branch exists</li>
            <li><code>get_current_branch</code>: Gets the name of the current branch</li>
            <li><code>has_uncommitted_changes</code>: Checks for uncommitted changes</li>
            <li><code>confirm_action</code>: Prompts the user for confirmation</li>
          </ul>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Example Usage</h3>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              # Check if we're in a Git repo
              check_git_repo

              # Get current branch
              current_branch=$(get_current_branch)

              # Check for uncommitted changes
              if has_uncommitted_changes; then
                # Source the colors file to get color definitions
                source "$SCRIPT_DIR/core_utils/colors.sh"

                echo -e "${YELLOW}You have uncommitted changes${NC}"

                # Ask for confirmation
                if confirm_action "Continue anyway?"; then
                  echo "Proceeding..."
                else
                  echo "Aborting..."
                  return 1
                fi
              fi
            </code>
          </pre>
        </div>

        <div>
          <h2 className="scroll-m-20 border-b pb-2 text-2xl font-semibold tracking-tight">Advanced Extensions</h2>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Beyond simple commands, you can extend GW in more advanced ways.
          </p>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Git Hooks Integration</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Create commands that install or manage Git hooks:
          </p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              cmd_install_hooks() {
                # Source the colors file to get color definitions
                source "$SCRIPT_DIR/core_utils/colors.sh"

                echo -e "${GREEN}Installing Git hooks...${NC}"
                # Create pre-commit hook
                cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Run tests before committing
npm test
exit $?
EOF
                # Make it executable
                chmod +x .git/hooks/pre-commit
                echo -e "${GREEN}Hooks installed successfully${NC}"
              }
            </code>
          </pre>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Project Templates</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Create commands for initializing projects with standard files:
          </p>
          <pre className="my-4 overflow-x-auto rounded-lg bg-slate-900 p-4">
            <code className="text-white">
              cmd_init_project() {
                local project_type="$1"

                # Source the colors file to get color definitions
                source "$SCRIPT_DIR/core_utils/colors.sh"

                echo -e "${GREEN}Initializing $project_type project...${NC}"
                # Initialize Git repo if needed
                if [ ! -d .git ]; then
                  git init
                fi

                # Create standard files based on project type
                case "$project_type" in
                  node)
                    echo '{"name":"project","version":"1.0.0"}' > package.json
                    echo 'node_modules' > .gitignore
                    ;;
                  python)
                    echo -e "venv\n__pycache__\n*.pyc" > .gitignore
                    echo "# Project Title\n\nDescription" > README.md
                    ;;
                  *)
                    echo -e "${RED}Unknown project type: $project_type${NC}"
                    return 1
                    ;;
                esac

                echo -e "${GREEN}Project initialized successfully${NC}"
              }
            </code>
          </pre>
          
          <h3 className="mt-6 scroll-m-20 text-lg font-semibold tracking-tight">Integration with Other Tools</h3>
          <p className="leading-7 [&:not(:first-child)]:mt-6">
            Create


Some time ago, while working at the company I belonged to, my teammate and I constantly faced challenges when cloning repositories and synchronizing remote branches with their corresponding local branches.

We would clone a repository only to realize that we were missing crucial branches. The typical workflow looked like this:

```bash
git clone <repo-url>
cd <repo>
git branch -a 
git checkout <name-branch>
git pull origin <name-branch>
```
text
This process was not only time-consuming but also prone to errors. Branches were often missed, leading to confusion and wasted time. The worst part? Everyone on the team was experiencing the same problem, but we all just accepted it as "that's how Git works."

As someone who has always loved command-line tools and automation, I couldn't stand this inefficiency any longer. I thought: "There has to be a better way!"

So I created Git Clone Master.

📦 Git Clone Master - Advanced Git Repository Cloner
Git Clone Master is an interactive and advanced CLI (Command Line Interface) tool for cloning Git repositories with all their branches automatically. Designed to simplify the workflow of developers who need to work with multiple branches of a repository.


✨ Main Features
🔄 Complete Cloning
Clone ALL branches automatically

Detects remote branches and creates their local equivalents

Synchronizes each branch with git pull automatically

Support for multiple URL formats (HTTPS, SSH, with/without .git)

🎯 Interactive Interface
Step-by-step CLI - No need to remember parameters

Real-time validation of URLs and directories

Confirmation before execution - Prevents accidental errors

Animated spinner for long operations

📊 Detailed Information
Shows statistics of cloned branches

Lists files from the cloned directory

Information per branch (files, latest commits)

Full path where the repository was saved

⚙️ Advanced Options
Verbose mode to see execution details

Mirror mode for backups (with clear warnings)

Specific branch cloning

Automatic deletion of existing directories

Branch listing upon completion
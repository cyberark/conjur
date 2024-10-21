## Ghea Chaw meeting summaries and progress

### Meeting 1
Discussed possible contribution, installed Docker through Chrome because it didn't work through Edge. We were told to go through the CONTRIBUTING.md document to check if it made sense if an outside person were to want to follow the steps. Also told to follow the instructions in CONTRIBUTING.md document to build Conjur

### Meeting 2
Continued trying to build Conjur<br>
When run in WSL the following error appeared (line endings CRLF):
- /usr/bin/env: ‘bash\r’: no such file or directory
- this error was resolved with using git bash

Running ./start (in git bash) resulted in the following error:
- /usr/bin/env: ‘ruby’: no such file or directory
- decided to solve line endings error before continuing

Before meeting, I tried to resolve the line endings error. Attempts 1 and 2 were found on the internet by Shlomo
Attempt 1:
>git config --global --edit <br>
git config --global core.eol lf <br>
git config --global core.autocrlf input<br>
git rm -rf --cached .<br>
git reset --hard HEAD<br>

Attempt 2: 
>add a file named .gitattributes <br>
*.txt text eol=lf <br>
Then run git add --renormalize .

Attempt 3: I got ChatGPT to write me a bash script that changed the line endings in each file from CRLF to LF
>#!/bin/bash
<br>
DIRECTORY=$1<br>
if [ -z "$DIRECTORY" ]; then<br>
  echo "Usage: $0 <directory>"<br>
  exit 1<br>
fi<br>
find "$DIRECTORY" -type f -exec sed -i 's/\r$//' {} \;<br>
echo "All files in $DIRECTORY converted to LF line endings."<br>

Running this file with ./convert_to_lf.sh "$(pwd)" did change all the line endings to LF, however also made it so github couldn't find the repository for some reason. Whenever I would delete the repository and try recloning and rerunning this script, it would just make the repository seemingly dissapear from my github desktop.

Attempt 4: git clone https://github.com/GheaCRPI/Conjur-RCOS-F24.git
Recloning the repository using the command line instead of github desktop seemed to resolve the issue

After I fixed this, I ran into another issue regarding ruby I think, this was fixed in meeting 4.

### Meeting 4
I do not remember the issue I initially fixed however, I got conjur built during this meeting and was able to set up the conjur environment. We began attempting to debug and downloaded Ruby LSP.

Attempted to learn to debug with VSCode, created a launch.json file in the .vscode folder 
> {<br>
    "version": "0.2.0",<br>
    "configurations": [<br>
        {<br>
            "name": "Listen for rdebug-ide",<br>
            "type": "ruby_lsp",<br>
            "request": "attach",<br>
            "remoteHost": "127.0.0.1",<br>
            "remotePort": "1234",<br>
            "remoteWorkspaceRoot": "/src/conjur-server"<br>
        }<br>
    ]<br>
}

It didn't work.

### Meeting 5
Helped Brian reclone the directory using the command line, got it built on his laptop. Attempted to start it however it kept timing out because it took too long. Tried running it on a VM but it didn't work either. (problem was later resolved by increasing the time allowed to run the program)

Continued trying to debug
- VSCode now cannot find RubyLSP
- I can't start RubyLSP for some reason now
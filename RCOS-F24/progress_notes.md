### Discovered using WSl led to error /usr/bin/env: ‘bash\r’: no such file or directory
- fixed by using git bash (which caused problems afterwards)
- problem stemmed from line endings being CRLF instead of LF

### Using git bash led to error /usr/bin/env: ‘ruby’: no such file or directory
- error fixed by recloning folder using the command line instead of github
- git clone https://github.com/repo_owner/repo_name.git results in line endings being kept as LF
    - discovered WSL must be used after this, git adds something to the file path which causes git bash not to work

### Fixing line endings attempts:
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

### Fix warnings 
- FromAsCasing: 'as' and 'FROM' keywords' casing do not match (line 1)
    - First Warning: Go to dockerfile and in the first line change the lower “as” to “AS”
- LegacyKeyValueFormat: "ENV key=value" should be used instead of legacy "ENV key value" format (line 45)
- LegacyKeyValueFormat: "ENV key=value" should be used instead of legacy "ENV key value" format (line 46)
    - In dockerfile.dev, there should be equal signs as shown in line 45 and 46
- changed outdated syntax

### Figure out what caused \r to appear
- cloning using github caused line endings to change from LF to CRLF resulting in this error
- fixed by using command line


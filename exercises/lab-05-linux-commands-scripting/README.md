# Lab 5 — Linux Commands and Shell Scripting

## Objectives

- Navigate the filesystem and manage files using common Linux commands
- Use shell variables and environment variables
- Redirect input/output and chain commands with pipes
- Write and execute Bash scripts

## Background

The **shell** is a command-line interpreter. In Linux the default shell is usually **Bash**.
Every command you run is either a built-in shell command or an external program on `PATH`.

Understanding the shell is foundational for cloud and DevOps work — automation, CI/CD pipelines,
and server configuration all rely on shell scripting.

## Part 1 — Essential Linux Commands

### Navigation and files

```bash
pwd               # print working directory
ls -lah           # list files (long, all, human-readable sizes)
cd /tmp           # change directory
mkdir mydir       # create directory
touch myfile.txt  # create empty file
cp src dst        # copy file
mv src dst        # move/rename file
rm myfile.txt     # delete file
cat file.txt      # print file contents
less file.txt     # page through file (q to quit)
```

### Finding things

```bash
find /etc -name "*.conf"          # find files by name
grep "error" /var/log/syslog      # search inside files
grep -r "TODO" ~/scripts/         # recursive search
which bash                        # find a command's location
```

### System info

```bash
uname -a          # kernel info
df -h             # disk usage
free -h           # memory usage
top               # live process viewer (q to quit)
ps aux            # snapshot of all processes
```

### Permissions

```bash
ls -l             # see permission bits (rwxrwxrwx)
chmod +x script.sh        # make file executable
chmod 644 file.txt        # owner rw, group/other r
chown user:group file     # change owner
```

## Part 2 — Variables

```bash
# Assign (no spaces around =)
NAME="Alice"
AGE=30

# Use (prefix with $)
echo "Hello, $NAME. You are $AGE years old."

# Command substitution
TODAY=$(date +%Y-%m-%d)
echo "Today is $TODAY"

# Environment variables (inherited by child processes)
export MY_VAR="shared"
```

## Part 3 — Redirection

```bash
# Redirect stdout to a file (overwrite)
echo "hello" > output.txt

# Append stdout to a file
echo "world" >> output.txt

# Redirect stderr
ls /nonexistent 2> errors.txt

# Both stdout and stderr
command > all.txt 2>&1

# Use a file as stdin
sort < unsorted.txt

# Pipe: stdout of one command → stdin of next
cat /etc/passwd | grep "bash" | cut -d: -f1
```

## Part 4 — Shell Scripts

Scripts live in `scripts/`. Run any of them with `bash scripts/<name>.sh`.

| Script | What it covers |
|--------|---------------|
| [01-hello-world.sh](scripts/01-hello-world.sh) | Basic script structure, echo |
| [02-variables.sh](scripts/02-variables.sh) | Variables, command substitution, user input |
| [03-redirection.sh](scripts/03-redirection.sh) | stdout/stderr redirection, pipes |
| [04-factorial.sh](scripts/04-factorial.sh) | Loops, arithmetic |
| [05-palindrome.sh](scripts/05-palindrome.sh) | Conditionals, string manipulation |

```bash
cd lab-05-linux-commands-scripting/

bash scripts/01-hello-world.sh
bash scripts/02-variables.sh
bash scripts/03-redirection.sh
bash scripts/04-factorial.sh
bash scripts/05-palindrome.sh
```

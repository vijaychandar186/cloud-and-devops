# Lab 08 — Installing Ansible and Basic Automation

## Objectives

By the end of this lab you will be able to:

- Install Ansible on Ubuntu (or macOS) and verify the installation
- Understand core Ansible concepts: inventory, modules, playbooks, and ad-hoc commands
- Write a playbook that installs Apache and deploys a Jinja2-templated HTML page
- Run a playbook in dry-run (check) mode to safely preview changes

---

## Background

Ansible is an agentless IT automation tool. It connects to target hosts over SSH (or locally via `connection: local`) and executes **modules** — small Python programs that perform a single unit of work such as installing a package, copying a file, or restarting a service. A **playbook** is a YAML file that orchestrates multiple modules into a repeatable workflow.

### Why Ansible?

| Concern | Without Ansible | With Ansible |
|---|---|---|
| Consistency | Manual steps, drift over time | Idempotent playbooks — run as many times as needed |
| Repeatability | Shell scripts that break across distros | Declarative tasks that describe desired state |
| Scale | SSH loop in bash | Parallel execution across hundreds of hosts |
| Auditability | Who ran what, when? | YAML in version control = full change history |

---

## Key Concepts

| Concept | Description |
|---|---|
| **Inventory** | A list of hosts Ansible manages. Can be a static INI/YAML file or a dynamic script that queries a cloud provider. Default location: `/etc/ansible/hosts`. |
| **Module** | A discrete unit of work (e.g., `apt`, `template`, `file`, `service`). Ansible ships with thousands of built-in modules. |
| **Task** | A single call to a module inside a playbook, given a human-readable `name`. |
| **Play** | A mapping of tasks to a set of hosts. A playbook can contain multiple plays. |
| **Playbook** | A YAML file containing one or more plays. The top-level automation artefact. |
| **Handler** | A task triggered only when notified by another task. Commonly used to restart a service after a config file changes. |
| **Template** | A Jinja2 file (`.j2`) rendered by Ansible and deployed to the target host. Variables are substituted at render time. |
| **Ad-hoc command** | A one-liner Ansible invocation for quick tasks without writing a playbook. |
| **become** | Privilege escalation — equivalent to `sudo`. Required for tasks that modify system state. |
| **Idempotency** | Running a playbook multiple times produces the same result without unintended side effects. |

---

## Installation

### Ubuntu / Debian (including EC2 Ubuntu instances)

```bash
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
ansible --version
```

### macOS (Homebrew)

```bash
brew install ansible
ansible --version
```

### Any OS via pip

```bash
pip3 install --user ansible
ansible --version
```

---

## Lab Structure

```
lab-08-ansible-setup/
├── README.md
├── playbook/
│   ├── playbook.yml          # Ansible playbook
│   └── templates/
│       └── index.html.j2     # Jinja2 HTML template
└── scripts/
    ├── 01-verify-ansible.sh  # Verify installation, ping localhost
    ├── 02-run-playbook.sh    # Run playbook in dry-run mode
    └── cleanup.sh            # Remove apache2 and deployed files
```

---

## The Playbook Explained

```yaml
- name: Install and configure web server
  hosts: localhost        # target: the local machine
  connection: local       # no SSH — run tasks directly
  become: true            # use sudo for privileged tasks
  tasks:
    - name: Install Apache web server
      apt:                # module: manage apt packages
        name: apache2
        state: present    # ensure it is installed

    - name: Create index.html file
      template:           # module: render a Jinja2 template
        src: index.html.j2
        dest: /var/www/html/index.html

    - name: Set ownership and permissions on index.html
      file:               # module: manage file attributes
        path: /var/www/html/index.html
        owner: www-data
        group: www-data
        mode: "0644"

  handlers:
    - name: restart apache2
      service:            # module: manage system services
        name: apache2
        state: restarted
```

### What each module does

| Module | Purpose in this playbook |
|---|---|
| `apt` | Installs the `apache2` package via the system package manager |
| `template` | Renders `index.html.j2` with Jinja2 and writes the result to `/var/www/html/index.html` |
| `file` | Sets the owner, group, and permission mode on the deployed file |
| `service` | Restarts apache2 (only triggered if a task sends a `notify`) |

---

## Ad-hoc Commands

Ad-hoc commands let you run a single module without a playbook. Useful for quick checks:

```bash
# Ping localhost to test connectivity
ansible localhost -m ping --connection=local

# Gather facts (system info) from localhost
ansible localhost -m setup --connection=local

# Check free disk space
ansible localhost -m command -a "df -h" --connection=local

# Install a package ad-hoc (requires become)
ansible localhost -m apt -a "name=curl state=present" --become --connection=local
```

---

## Scripts

### 01-verify-ansible.sh

Checks that Ansible is installed, prints the active configuration, explains inventory concepts, and runs `ansible localhost -m ping` to confirm everything works.

```bash
bash scripts/01-verify-ansible.sh
```

### 02-run-playbook.sh

Runs the playbook in `--check --diff` (dry-run) mode. No changes are made to the system. The `--diff` flag shows exactly what would change inside any templated files.

```bash
bash scripts/02-run-playbook.sh
```

To apply the playbook for real on an Ubuntu host or EC2 instance:

```bash
cd playbook/
sudo ansible-playbook playbook.yml
```

### cleanup.sh

Removes `apache2` (if installed) and deletes `/var/www/html/index.html`.

```bash
bash scripts/cleanup.sh
```

---

## Real-World Notes

- **EC2 usage**: On a real Ubuntu EC2 instance, remove `connection: local` and `become: true` from the play level, add `ansible_user: ubuntu` to your inventory, and ensure port 22 is open in the security group. Run from a control node (your laptop or a bastion host).
- **Idempotency**: Run the playbook twice — the second run should report all tasks as `ok` (no changes), not `changed`. This is the expected behaviour.
- **Handlers fire once**: Even if ten tasks notify the same handler, it restarts apache2 only once at the end of the play.
- **`--check` mode**: Always a safe first step when applying a playbook to production. Some modules report inaccurate results in check mode (e.g., if a later task depends on a file created by an earlier task that was skipped).

---

## Next Steps

Proceed to **Lab 09** to refactor this flat playbook into a reusable Ansible **role**.

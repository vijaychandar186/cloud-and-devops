# Lab 09 — Create Roles in Ansible

## Objectives

By the end of this lab you will be able to:

- Understand the purpose and structure of an Ansible role
- Convert a flat playbook into a properly structured role
- Use role defaults and Jinja2 variables to make automation reusable
- Run a role-based playbook and override variables without editing files

---

## Background

In Lab 08 you wrote a single `playbook.yml` that installed Apache, deployed a template, and set file permissions. That works fine for one server type, but as your infrastructure grows you will need to manage web servers, database servers, monitoring agents, and more — often mixing them on different hosts. Putting everything in one file becomes unmanageable.

**Ansible roles** solve this by providing a standardised directory layout that separates tasks, handlers, templates, variables, and metadata into dedicated files. A role is self-contained and reusable: you can drop it into any playbook by name, share it on Ansible Galaxy, or import it as a dependency of another role.

### Flat Playbook vs Role — Side by Side

| Aspect | Flat playbook (Lab 08) | Role (Lab 09) |
|---|---|---|
| Structure | Single `playbook.yml` file | Multiple files in a standardised directory tree |
| Reusability | Copy-paste into every project | Import by role name in any playbook |
| Variable management | Hard-coded values or play-level `vars:` | `defaults/` and `vars/` with clear precedence |
| Sharing | Manual copy | Publishable to Ansible Galaxy |
| Testing | Test the whole playbook | Test each role in isolation |
| Readability at scale | One long file | Each concern in its own file |

---

## Role Directory Structure

The `ansible-galaxy init` command generates the standard skeleton. Every subdirectory serves a specific purpose:

| Directory / File | Purpose |
|---|---|
| `tasks/main.yml` | Entry point for the role's task list. Ansible runs this automatically when the role is applied. Additional task files can be imported from here. |
| `handlers/main.yml` | Handlers for this role. A handler is a task that only runs when notified by another task (e.g., restart a service after a config change). |
| `templates/` | Jinja2 template files (`.j2`). The `template` module renders them with variable substitution before copying to the target host. |
| `defaults/main.yml` | Default variable values. Lowest precedence — easily overridden by inventory variables, group/host vars, or `-e` on the command line. |
| `vars/main.yml` | Higher-precedence role variables. Use for internal constants that operators should not normally override. |
| `files/` | Static files deployed verbatim with the `copy` module. No Jinja2 processing. |
| `meta/main.yml` | Role metadata: author, description, supported platforms, Galaxy tags, and role dependencies. |

---

## Lab Structure

```
lab-09-ansible-roles/
├── README.md
├── site.yml                              # Top-level playbook — applies the role
├── roles/
│   └── webserver/
│       ├── tasks/
│       │   └── main.yml                 # Install Apache, deploy template, set perms
│       ├── handlers/
│       │   └── main.yml                 # Restart apache2
│       ├── templates/
│       │   └── index.html.j2            # Jinja2 template using {{ page_title }}
│       ├── defaults/
│       │   └── main.yml                 # page_title, web_owner, web_group defaults
│       └── meta/
│           └── main.yml                 # Author, platforms, dependencies
└── scripts/
    ├── 01-explore-role-structure.sh     # Print tree, cat all files, explain dirs
    ├── 02-run-role-playbook.sh          # Run site.yml --check --diff (dry-run)
    └── cleanup.sh                       # Remove apache2 and index.html
```

---

## How the Role Works

### site.yml

```yaml
- name: Configure web servers using the webserver role
  hosts: localhost
  connection: local
  become: true
  roles:
    - webserver
```

Listing a role under `roles:` tells Ansible to look for `roles/webserver/` relative to the playbook. Ansible automatically imports `tasks/main.yml`, `handlers/main.yml`, and makes `defaults/main.yml` variables available.

### Variable Flow

```
defaults/main.yml          (lowest precedence — role defaults)
  page_title: "Hello from Ansible Role!"
  web_owner:  www-data
  web_group:  www-data

      |
      v   overridden by any of these (in increasing precedence):
      |
  inventory group_vars / host_vars
  play-level vars:
  extra-vars (-e flag)     (highest precedence)
```

### Jinja2 Template

`templates/index.html.j2` uses `{{ page_title }}` which Ansible replaces with the resolved variable value at render time:

```html
<h1>{{ page_title }}</h1>
```

With the default value this renders as:

```html
<h1>Hello from Ansible Role!</h1>
```

Override without touching any file:

```bash
ansible-playbook site.yml -e "page_title='My EC2 Web Server'"
```

---

## Scripts

### 01-explore-role-structure.sh

Prints the full role directory tree using `find`, then `cat`s every file with a header, and explains what each directory is for.

```bash
bash scripts/01-explore-role-structure.sh
```

### 02-run-role-playbook.sh

Runs `ansible-playbook site.yml --check --diff` (dry-run mode). No changes are applied to the system. Safe to run inside a devcontainer.

```bash
bash scripts/02-run-role-playbook.sh
```

To apply the role for real on an Ubuntu host or EC2 instance:

```bash
cd /path/to/lab-09-ansible-roles/
sudo ansible-playbook site.yml
```

### cleanup.sh

Removes `apache2` (if installed) and deletes `/var/www/html/index.html`.

```bash
bash scripts/cleanup.sh
```

---

## When to Use Roles

Use a role when any of the following apply:

- The same configuration logic is needed on more than one host group
- You want to version and test a piece of automation independently
- You plan to share automation via Ansible Galaxy or a private hub
- A single playbook is growing beyond ~50 tasks and becoming hard to navigate
- You need clear separation between what a role does (tasks) and how it can be customised (defaults)

Use a flat playbook when you have a quick, one-off task or a simple workflow that will only ever apply to a single context.

---

## Real-World Notes

- **Galaxy roles**: `ansible-galaxy install geerlingguy.apache` downloads a community role for Apache with dozens of configuration options. Study its directory structure to see how experienced contributors organise roles.
- **Role dependencies**: List other roles in `meta/main.yml` under `dependencies:`. Ansible installs and runs them automatically before your role's tasks.
- **Molecule**: The standard tool for testing Ansible roles in Docker or Vagrant before deploying to production. Run `molecule test` to lint, converge, and verify a role in isolation.
- **`vars/` vs `defaults/`**: Put values operators might legitimately customise in `defaults/`. Put internal implementation constants in `vars/` to signal they should not be changed by consumers of the role.
- **`ansible-galaxy init webserver`**: Generates the full role skeleton including the `vars/`, `files/`, and `tests/` directories not included in this lab. Run it to see the complete structure.

---

## Next Steps

- Explore **Lab 10** (Terraform) to see how infrastructure is provisioned before Ansible configures it.
- Publish your `webserver` role to Ansible Galaxy: `ansible-galaxy role import <github-user> <repo>`.
- Add a `molecule/` directory and write a convergence test for the webserver role.

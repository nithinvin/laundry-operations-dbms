# Runbook — Install, Load, Run, Reset, Troubleshoot

Target environments:

| Env | Role | OS |
|-----|------|----|
| **A** | Build and verify | openSUSE Leap 16.0 (native Linux, Docker + Compose v2 already installed) |
| **B** | Final demo | Windows 11 → WSL 2 → Ubuntu 24.04 |

Neo4j runs in Docker in both environments, so after the one-time setup in
section 1 or 2, **every command from section 3 onward is identical.**

> Every command in sections 3–9 was tested on Env A (openSUSE Leap 16.0,
> Docker Compose 2.33, Neo4j 2026.09.0, Python 3.13, neo4j driver 6.3).
> Write down any differences found on Env B in section 10.

---

## 1. One-time setup — openSUSE Leap 16.0 (Env A)

```bash
# Docker engine + compose plugin (skip if already present)
sudo zypper install docker docker-compose   # provides `docker compose`
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"             # log out/in afterwards

docker compose version                      # expect v2.x
python3 --version                           # 3.11+ is fine
```

## 2. One-time setup — Windows 11 + WSL 2 + Ubuntu 24.04 (Env B)

### 2.1 WSL and Ubuntu

Run in **Windows PowerShell as Administrator**:

```powershell
wsl --install -d Ubuntu-24.04
wsl --set-default-version 2
wsl -l -v            # Ubuntu-24.04 should show VERSION 2
```

Open the Ubuntu terminal, create a Linux user, then:

```bash
sudo apt update && sudo apt upgrade -y
cat /etc/wsl.conf    # should contain [boot] systemd=true (default on new installs)
```

If `systemd=true` is missing, add it, then run `wsl --shutdown` from
PowerShell and reopen Ubuntu.

### 2.2 Docker — choose one option

**Option 1 (recommended): Docker Engine inside Ubuntu.** Nothing to install
on the Windows side, and it behaves exactly like Env A.

```bash
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker "$USER"     # close and reopen the Ubuntu terminal
docker run --rm hello-world
```

**Option 2: Docker Desktop for Windows** with *Settings → Resources → WSL
Integration → Ubuntu-24.04* turned on. Choose this if Docker Desktop is
already installed. Do not use both options at the same time.

### 2.3 Python and git

```bash
sudo apt install -y python3 python3-venv python3-pip git
```

### 2.4 Clone the repo inside the Linux filesystem

```bash
cd ~ && git clone <repo-url> laundry-operations-dbms
cd laundry-operations-dbms
```

> Clone into `~/…`, **not** `/mnt/c/…`. The Windows filesystem is slow from
> WSL, and it can add CRLF line endings that break the `.sh` scripts.

### 2.5 Reaching Neo4j from Windows

WSL 2 forwards `localhost` to Windows by default. Once the container is
running, open **<http://localhost:7474>** in Edge or Chrome on Windows and
connect with `neo4j://localhost:7687`.

---

## 3. Configure (once per clone)

All commands are run from the repo root.

```bash
cp .env.example .env
nano .env               # set NEO4J_PASSWORD (at least 8 characters)

python3 -m venv .venv
.venv/bin/pip install -r python/requirements.txt
```

`.env` holds:

```
NEO4J_URI=bolt://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=<your password>
```

It is git-ignored. Never commit it. Docker Compose also reads it, to set the
initial Neo4j password.

## 4. Start Neo4j

```bash
docker compose up -d
docker compose ps         # wait until STATUS shows (healthy), about 15–30 s
```

`docker-compose.yml` runs the `neo4j:2026.09.0-community` image as the
container `laundry-neo4j`:

| Setting | Value |
|---------|-------|
| Ports | 7474 (Browser / HTTP), 7687 (Bolt) |
| Memory | heap 512 MB, page cache 256 MB (laptop-friendly) |
| Data | named volume `neo4j-data` (survives restarts) |
| `./cypher` | mounted read-only at `/cypher` inside the container, so `cypher-shell -f /cypher/<file>` works |

Quick connection test from Python:

```bash
.venv/bin/python python/db.py     # Connected to Neo4j, RETURN 1 -> 1
```

## 5. Load schema and data

```bash
./scripts/load.sh
```

This runs `cypher/01_constraints.cypher` and then `cypher/02_load_data.cypher`
inside the container, and prints the counts. Expected at the end:

```
nodes, relationships
53, 51
constraints
14
```

It is safe to run again: the counts stay the same.

## 6. Validate

```bash
./scripts/validate.sh
```

This runs the 42 checks in `cypher/04_validation.cypher`. Expected last line:
`42/42 checks passed.` The script exits with status 1 if any check fails, and
prints the rows that break the rule.

## 7. Run the queries

**Terminal: Cypher files**, printed as tables:

```bash
./scripts/run_cypher.sh 03_queries.cypher     # 5 ported SQL queries
./scripts/run_cypher.sh 06_showcase.cypher    # graph showcase queries
```

**Terminal: the PL/SQL equivalents:**

```bash
.venv/bin/python python/run_plsql_equivalents.py     # all 5
.venv/bin/python python/plsql_q5_ready_check.py O002 # one script, with an argument
```

Compare with [queries.md](queries.md) and `docs/outputs/`. (You can also run
`source .venv/bin/activate` once, then use plain `python`.)

**Neo4j Browser:**

1. Open <http://localhost:7474> (from Windows when using WSL).
2. Connect URL: `neo4j://localhost:7687`, user `neo4j`, and the password from `.env`.
3. *Optional style:* type `:style` and drag `cypher/browser-style.grass`
   onto the style panel. This gives colours and captions per label.
4. Paste queries from the `cypher/*.cypher` files. See [demo-script.md](demo-script.md).

**Workflow operations** (these change data):

```bash
.venv/bin/python python/workflow.py show O002
.venv/bin/python python/workflow.py advance O002
.venv/bin/python python/workflow.py remind
```

## 8. Reset

```bash
./scripts/reset.sh      # delete all nodes/relationships, then run load.sh
```

Reset after any workflow operation or manual edit, and before a demo.

Full wipe, which also removes the stored password and the data volume:

```bash
docker compose down -v
docker compose up -d && ./scripts/load.sh
```

## 9. Stop

```bash
docker compose stop      # keeps data
docker compose down      # removes the container, keeps the volume
```

---

## 10. Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `The client is unauthorized due to authentication failure` after changing `.env` | `NEO4J_AUTH` only takes effect the first time, on an empty data volume | `docker compose down -v`, then `up -d` again |
| Container exits immediately, log says password is too short | Neo4j requires at least 8 characters | Use a longer password in `.env` |
| `bind: address already in use` on 7474/7687 | Another Neo4j (Desktop, an old container) is running | `docker ps -a`, stop it, or change the host ports |
| Browser on Windows cannot reach `localhost:7474` | WSL localhost forwarding is off, or the container is not running | `docker ps` inside WSL; in `%UserProfile%\.wslconfig` make sure `localhostForwarding=true` (or that networking mode is not set to block it); `wsl --shutdown` and retry |
| `ServiceUnavailable` from Python | Neo4j is still starting | Wait for `Started.` in the logs |
| `./scripts/*.sh: /bin/bash^M: bad interpreter` | CRLF line endings (repo cloned on the Windows side) | Clone inside WSL (`~/`), or `git config core.autocrlf input` and re-checkout |
| `error: externally-managed-environment` from pip | PEP 668 on Ubuntu 24.04 | Use the `.venv` virtual environment (section 3) |
| `ERROR: .venv not found` from validate.sh | Virtual environment not created | Section 3 |
| `ERROR: .env not found` from a script | `.env` not created | `cp .env.example .env` and set the password |
| `docker: permission denied` | User is not in the `docker` group yet | `sudo usermod -aG docker $USER`, then reopen the terminal |
| Query outputs do not match queries.md | Data changed by workflow operations or manual edits | `./scripts/reset.sh` |
| Neo4j uses too much RAM on a laptop | Default memory settings | Lower the heap/pagecache settings in `docker-compose.yml` |

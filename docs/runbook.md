# Runbook — Install, Load, Run, Reset, Troubleshoot

Target environments:

| Env | Role | OS |
|-----|------|----|
| **A** | Build and verify | openSUSE Leap 16.0 (native Linux, Docker + Compose v2 already installed) |
| **B** | Final demo | Windows 11 → WSL 2 → Ubuntu 24.04 |

Neo4j runs in Docker in both environments, so after the one-time setup in
section 1 or 2, **every command from section 3 onward is identical.**

> Commands marked *(planned)* refer to files created during implementation
> (see [plan.md](plan.md)). This runbook is updated in Phase 7 with the
> exact, tested commands.

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

## 3. Configure

*(planned)* Copy the example environment file and set a password:

```bash
cp .env.example .env
# edit .env:
#   NEO4J_URI=bolt://localhost:7687
#   NEO4J_USER=neo4j
#   NEO4J_PASSWORD=<at least 8 characters>
```

`.env` is git-ignored. Never commit it.

## 4. Start Neo4j

*(planned)* `docker-compose.yml`, in outline:

```yaml
services:
  neo4j:
    image: neo4j:2026.09.0-community     # fallback: neo4j:5.26-community (LTS)
    container_name: laundry-neo4j
    ports: ["7474:7474", "7687:7687"]
    environment:
      NEO4J_AUTH: neo4j/${NEO4J_PASSWORD}
      NEO4J_server_memory_heap_max__size: 512m
      NEO4J_server_memory_pagecache_size: 256m
    volumes:
      - neo4j-data:/data
      - ./cypher:/cypher:ro
volumes:
  neo4j-data:
```

```bash
docker compose up -d
docker compose logs -f neo4j      # wait for "Started." then Ctrl+C
```

## 5. Load schema and data

*(planned)* `./scripts/load.sh` runs these, in this order:

```bash
docker exec -i laundry-neo4j cypher-shell -u neo4j -p "$NEO4J_PASSWORD" -f /cypher/01_constraints.cypher
docker exec -i laundry-neo4j cypher-shell -u neo4j -p "$NEO4J_PASSWORD" -f /cypher/02_load_data.cypher
```

Check the counts (expected values are in [spec.md §5](spec.md#5-data-requirements)):

```cypher
MATCH (n) RETURN labels(n)[0] AS label, count(*) ORDER BY label;      // 53 total
MATCH ()-[r]->() RETURN type(r) AS rel, count(*) ORDER BY rel;          // 51 total
SHOW CONSTRAINTS;                                                       // 14
```

## 6. Validate

```bash
./scripts/validate.sh            # (planned) wraps: python python/validate.py
```

Every check must report `PASS` (0 violating rows).

## 7. Run the queries

**In Neo4j Browser:** paste the queries from `cypher/03_queries.cypher` one
at a time, following [demo-script.md](demo-script.md).

**From the terminal:**

```bash
docker exec -i laundry-neo4j cypher-shell -u neo4j -p "$NEO4J_PASSWORD" -f /cypher/03_queries.cypher
```

**Python (the PL/SQL equivalents):**

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r python/requirements.txt
python python/run_plsql_equivalents.py
```

Compare the output with the expected output in [queries.md](queries.md).

## 8. Reset

```bash
./scripts/reset.sh      # (planned) DETACH DELETE everything, then re-run load.sh
```

Full wipe, including the stored password and the data volume:

```bash
docker compose down -v
docker compose up -d && ./scripts/load.sh
```

Reset after running any workflow operation (queries.md Part D) and before
a demo.

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
| `error: externally-managed-environment` from pip | PEP 668 on Ubuntu 24.04 | Use the `.venv` virtual environment (section 7) |
| `docker: permission denied` | User is not in the `docker` group yet | `sudo usermod -aG docker $USER`, then reopen the terminal |
| Query outputs do not match queries.md | Data changed by workflow operations or manual edits | `./scripts/reset.sh` |
| Neo4j uses too much RAM on a laptop | Default memory settings | Lower the heap/pagecache settings in `docker-compose.yml` |

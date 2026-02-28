# mdvault

Markdown documentation server with MkDocs Material. Instantly browse your markdown files with a beautiful interface.

## Installation

### One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/stealth-dev-lab/mdvault/main/install.sh | sh
```

This will:
1. Detect your container engine (Docker or Podman)
2. Guide you through configuration
3. Start mdvault automatically

### Management Commands

```bash
# Update to latest version
curl -fsSL https://raw.githubusercontent.com/stealth-dev-lab/mdvault/main/install.sh | sh -s -- --update

# Check status
curl -fsSL https://raw.githubusercontent.com/stealth-dev-lab/mdvault/main/install.sh | sh -s -- --status

# Uninstall
curl -fsSL https://raw.githubusercontent.com/stealth-dev-lab/mdvault/main/install.sh | sh -s -- --uninstall
```

## Features

- Filename as navigation title (instead of H1 heading)
- Mermaid diagram rendering
- Hot reload (file create/update/delete)
- Auto-update support (Podman Quadlet with `AutoUpdate=registry`)

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `MDVAULT_SOURCE` | `~/work` | Directory to serve |
| `MDVAULT_PORT` | `3000` | Host port |
| `MDVAULT_DEPTH` | `3` | Directory depth limit |

## Manual Installation

### Docker Compose

```bash
# Clone and configure
git clone https://github.com/stealth-dev-lab/mdvault.git
cd mdvault
cp .env.example .env
# Edit .env with your settings

# Start
docker compose up -d
```

### Podman (Manual)

```bash
podman run -d --name mdvault \
  -p 3000:8000 \
  -v ~/work:/source:ro,Z \
  -e MKDOCS_DEPTH=3 \
  ghcr.io/stealth-dev-lab/mdvault:latest \
  serve --dev-addr=0.0.0.0:8000 --livereload
```

### Build from Source

```bash
# Build
podman build -t mdvault .

# Run
podman run -d --name mdvault \
  -p 3000:8000 \
  -v ~/work:/source:ro,Z \
  -e MKDOCS_DEPTH=3 \
  mdvault serve --dev-addr=0.0.0.0:8000 --livereload
```

## How It Works

mdvault mounts your source directory read-only and serves it through MkDocs Material. The `MKDOCS_DEPTH` option limits directory scanning depth for better performance with large codebases.

### Mount Points

| Path | Description |
|------|-------------|
| `/source` | Your markdown files (with depth filtering) |
| `/docs/docs` | Direct mount (no depth filtering) |

## Files

| File | Description |
|------|-------------|
| `install.sh` | One-line installer script |
| `docker-compose.yml` | Docker Compose configuration |
| `quadlet/mdvault.container` | Podman Quadlet template |
| `Containerfile` | Container image definition |
| `mkdocs.yml` | MkDocs configuration |
| `hooks/` | MkDocs hooks (filename_title, depth_filter) |

## License

MIT

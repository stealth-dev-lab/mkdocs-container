# MkDocs Container

MkDocs Material container with custom hooks for documentation hosting.

## Features

- Filename as navigation title (instead of H1 heading)
- Mermaid diagram rendering
- Hot reload (file create/update/delete)
- No Nix dependency

## Quick Start

```bash
# Build
podman build -t mkdocs-custom .

# Run (mount the directory you want to browse)
podman run -d --name mkdocs \
  --network "pasta:--ipv4-only" \
  -p 3000:8000 \
  -v ~/work:/docs/docs:Z \
  mkdocs-custom serve --dev-addr=0.0.0.0:8000 --livereload
```

Access at `http://localhost:3000/`

## Usage

### Mount Structure

MkDocs reads markdown files from `/docs/docs` inside the container. Mount your target directory there:

```bash
-v /path/to/your/markdown:/docs/docs:Z
```

### Examples

```bash
# Browse ~/work directory
-v ~/work:/docs/docs:Z

# Browse a specific project
-v ~/projects/my-app:/docs/docs:Z
```

### Depth Filtering

For large directories, use `MKDOCS_DEPTH` to limit scanning depth. Mount to `/source` instead of `/docs/docs`:

```bash
# Only show files up to 3 levels deep
podman run --rm --name mkdocs \
  --network "pasta:--ipv4-only" \
  -p 3000:8000 \
  -e MKDOCS_DEPTH=3 \
  -v ~/work:/source:Z \
  mkdocs-custom serve --dev-addr=0.0.0.0:8000 --livereload
```

This creates symlinks only for files within the depth limit, making startup fast even for large directories.

### Options

| Option | Description |
|--------|-------------|
| `-e MKDOCS_DEPTH=N` | Limit to N levels deep (optional) |
| `--network "pasta:--ipv4-only"` | Required for rootless podman with Nix-installed pasta (avoids IPv6 connection issues) |
| `-p 3000:8000` | Map container port 8000 to host port 3000 |
| `--livereload` | Required for hot reload to work |

## Files

| File | Description |
|------|-------------|
| `Containerfile` | Container image definition |
| `mkdocs.yml` | MkDocs configuration |
| `hooks/filename_title.py` | Hook to use filename as nav title |

## Documentation

See [docs/mkdocs_container_setup.md](../docs/mkdocs_container_setup.md) for detailed setup instructions.

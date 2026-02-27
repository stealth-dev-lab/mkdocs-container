#!/bin/sh
set -e

SOURCE_DIR="/source"
DOCS_DIR="/docs/docs"

# If MKDOCS_DEPTH is set and source is mounted, create filtered symlinks
if [ -n "$MKDOCS_DEPTH" ] && [ -d "$SOURCE_DIR" ]; then
    echo "Filtering files with depth <= $MKDOCS_DEPTH..."

    # Clean docs directory
    rm -rf "$DOCS_DIR"/*

    # Find markdown files within depth limit and create symlinks
    find "$SOURCE_DIR" -maxdepth "$MKDOCS_DEPTH" -name "*.md" -type f | while read file; do
        # Get relative path from source
        rel_path="${file#$SOURCE_DIR/}"
        dir_path=$(dirname "$rel_path")
        target_dir="$DOCS_DIR/$dir_path"

        # Create directory structure and symlink
        mkdir -p "$target_dir"
        ln -sf "$file" "$DOCS_DIR/$rel_path"
    done

    file_count=$(find "$DOCS_DIR" -name "*.md" -type l | wc -l)
    echo "Created $file_count symlinks"
fi

# Execute mkdocs
exec mkdocs "$@"

import os
from mkdocs.structure.files import Files


def on_files(files: Files, config) -> Files:
    """Filter files by directory depth.

    Set MKDOCS_DEPTH environment variable to limit depth.
    Example: MKDOCS_DEPTH=3 limits to 3 levels deep.
    """
    depth_str = os.environ.get("MKDOCS_DEPTH", "")
    if not depth_str:
        return files

    try:
        max_depth = int(depth_str)
    except ValueError:
        return files

    filtered = []
    for file in files:
        # Count directory separators to determine depth
        depth = file.src_path.count("/")
        if depth < max_depth:
            filtered.append(file)

    return Files(filtered)

from pathlib import Path


def on_page_content(html, page, config, files):
    """Set page title to filename without extension."""
    page.title = Path(page.file.src_path).stem
    return html

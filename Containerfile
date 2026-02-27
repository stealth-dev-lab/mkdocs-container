FROM docker.io/squidfunk/mkdocs-material:latest

# Copy MkDocs configuration, hooks, and entrypoint
COPY mkdocs.yml /docs/
COPY hooks /docs/hooks
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

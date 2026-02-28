FROM docker.io/squidfunk/mkdocs-material:latest

# Copy MkDocs configuration, hooks, stylesheets, and entrypoint
COPY mkdocs.yml /docs/
COPY hooks /docs/hooks
COPY docs/stylesheets /docs/docs/stylesheets
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

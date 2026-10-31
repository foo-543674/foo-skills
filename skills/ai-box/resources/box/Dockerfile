FROM node:22-bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends git curl jq openssl ripgrep less ca-certificates gnupg \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update && apt-get install -y --no-install-recommends gh podman \
 && rm -rf /var/lib/apt/lists/*

# Language toolchains never enter the box: project commands run in the project's dev image via
# rootless Podman. Single-UID mode (no subuid range): newuidmap needs CAP_SYS_ADMIN inside Docker,
# which the box must not have. See SKILL.md "プロジェクトのコマンドを動かす仕組み".
RUN sed -i '/^node:/d' /etc/subuid /etc/subgid
COPY containers/ /etc/ai-box/containers/

# Updated by rebuilding the image (ai-box build), not by self-update.
RUN npm install -g @anthropic-ai/claude-code @openai/codex && npm cache clean --force

COPY bin/ /usr/local/bin/
RUN chmod 755 /usr/local/bin/* \
 && git config --system credential.helper /usr/local/bin/git-credential-app \
 && git config --system url."https://github.com/".insteadOf "git@github.com:" \
 && git config --system init.defaultBranch main

USER node
ENV DISABLE_AUTOUPDATER=1 \
    PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin
WORKDIR /home/node
ENTRYPOINT ["/usr/local/bin/ai-box-entrypoint"]
CMD ["bash"]

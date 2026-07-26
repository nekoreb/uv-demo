FROM python:3.14-slim AS builder


COPY --from=ghcr.io/astral-sh/uv:latest \
  /uv \
  /usr/local/bin/uv


WORKDIR /opt/app


ENV UV_COMPILE_BYTECODE=1 \
  UV_LINK_MODE=copy \
  UV_PROJECT_ENVIRONMENT=/opt/venv


COPY pyproject.toml uv.lock ./


RUN --mount=type=cache,target=/root/.cache/uv \
  uv sync \
  --frozen \
  --no-dev \
  --no-install-project


COPY src ./src
COPY README.md* ./


RUN --mount=type=cache,target=/root/.cache/uv \
  uv sync \
  --frozen \
  --no-dev \
  --no-editable


FROM python:3.14-slim AS runner


WORKDIR /opt/app


# 1. PATH 提升 /opt/venv/bin
# 2. HOME 强制指向 /tmp，完美兼容 readOnlyRootFilesystem: true
ENV PATH="/opt/venv/bin:$PATH" \
  PYTHONUNBUFFERED=1 \
  HOME=/tmp


COPY --from=builder /opt/venv /opt/venv



# 严格的非 root 权限控制 (UID: 10001)
RUN useradd -u 10001 --create-home --shell /bin/false app \
  && chown -R app:app /opt/app

USER 10001

EXPOSE 8080


CMD ["uv-demo"]

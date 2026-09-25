# ---- build stage: install dependencies ----
FROM python:3.12-slim AS builder
WORKDIR /build
COPY app/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---- runtime stage: small, non-root ----
FROM python:3.12-slim
ARG APP_VERSION=dev
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_VERSION=${APP_VERSION}
RUN useradd --system --uid 10001 --no-create-home appuser
WORKDIR /app
COPY --from=builder /install /usr/local
COPY app/main.py .
USER 10001
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"
# 1 worker + threads: state is in-memory, so keep it consistent per container
CMD ["gunicorn", "-b", "0.0.0.0:8000", "-w", "1", "--threads", "4", "main:app"]

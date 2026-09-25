"""Task API - a deliberately tiny Flask service used as a DevOps practice target."""
import os
import time
import uuid

from flask import Flask, jsonify, request


def create_app():
    app = Flask(__name__)
    tasks = {}  # in-memory on purpose: see README exercise "add a database"
    started = time.time()

    @app.get("/")
    def index():
        return jsonify(
            service="task-api",
            version=os.getenv("APP_VERSION", "dev"),
            environment=os.getenv("APP_ENV", "local"),
            message=os.getenv("APP_MESSAGE", "Hello from the DevOps lab!"),
        )

    @app.get("/health")  # liveness probe
    def health():
        return jsonify(status="ok", uptime_seconds=round(time.time() - started, 1))

    @app.get("/ready")  # readiness probe
    def ready():
        return jsonify(status="ready")

    @app.get("/tasks")
    def list_tasks():
        return jsonify(list(tasks.values()))

    @app.post("/tasks")
    def create_task():
        body = request.get_json(silent=True) or {}
        title = str(body.get("title", "")).strip()
        if not title:
            return jsonify(error="title is required"), 400
        task = {"id": uuid.uuid4().hex[:8], "title": title, "done": False}
        tasks[task["id"]] = task
        return jsonify(task), 201

    @app.delete("/tasks/<task_id>")
    def delete_task(task_id):
        if tasks.pop(task_id, None) is None:
            return jsonify(error="not found"), 404
        return "", 204

    return app


app = create_app()

from main import create_app


def client():
    return create_app().test_client()


def test_health():
    r = client().get("/health")
    assert r.status_code == 200
    assert r.get_json()["status"] == "ok"


def test_ready():
    assert client().get("/ready").status_code == 200


def test_create_list_delete_task():
    c = client()
    created = c.post("/tasks", json={"title": "learn terraform"})
    assert created.status_code == 201
    task_id = created.get_json()["id"]
    assert len(c.get("/tasks").get_json()) == 1
    assert c.delete(f"/tasks/{task_id}").status_code == 204
    assert c.get("/tasks").get_json() == []


def test_create_task_requires_title():
    assert client().post("/tasks", json={}).status_code == 400


def test_delete_missing_task():
    assert client().delete("/tasks/nope").status_code == 404

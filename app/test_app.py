from app import app

def test_hello():
    with app.test_client() as c:
        rv = c.get("/")
        assert rv.status_code == 200
        assert rv.get_json()["message"] == "hello, world"

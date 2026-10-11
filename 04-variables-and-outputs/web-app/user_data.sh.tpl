#!/bin/bash
set -e

apt-get update -y
apt-get install -y python3-pip
pip3 install flask psycopg2-binary

cat <<'PYEOF' > /home/ubuntu/app.py
import os
import time
from flask import Flask, request, redirect

app = Flask(__name__)


def get_conn():
    import psycopg2
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASS"],
        connect_timeout=5,
    )


def init_db():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute(
        "CREATE TABLE IF NOT EXISTS todos ("
        "id SERIAL PRIMARY KEY, task TEXT NOT NULL, done BOOLEAN DEFAULT FALSE)"
    )
    conn.commit()
    cur.close()
    conn.close()


@app.route("/")
def index():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT id, task, done FROM todos ORDER BY id")
    todos = cur.fetchall()
    cur.close()
    conn.close()

    rows = ""
    for todo_id, task, done in todos:
        mark = "done" if done else "open"
        checkbox = "checked" if done else ""
        rows += (
            "<li>"
            f"<a href='/toggle/{todo_id}' class='toggle {mark}'>{'DONE' if done else 'OPEN'}</a> "
            f"<span class='{mark}'>{task}</span> "
            f"<a href='/delete/{todo_id}' class='delete'>delete</a>"
            "</li>"
        )

    instance_label = os.environ.get("INSTANCE_LABEL", "unknown")
    return f"""
    <html>
    <head>
      <title>Terraform Todo App</title>
      <style>
        body {{ font-family: sans-serif; max-width: 480px; margin: 40px auto; color: #333; }}
        h1 {{ color: #7B68C8; }}
        ul {{ list-style: none; padding: 0; }}
        li {{ padding: 8px 0; border-bottom: 1px solid #eee; }}
        .done {{ text-decoration: line-through; color: #999; }}
        .toggle {{ text-decoration: none; font-size: 0.75em; padding: 2px 6px; border-radius: 4px; background: #eee; }}
        .delete {{ float: right; color: #c0392b; text-decoration: none; }}
        input {{ padding: 6px; width: 70%; }}
        button {{ padding: 6px 12px; background: #7B68C8; color: white; border: none; border-radius: 4px; }}
        footer {{ margin-top: 30px; font-size: 0.8em; color: #aaa; }}
      </style>
    </head>
    <body>
      <h1>Terraform Todo App</h1>
      <form action="/add" method="post">
        <input name="task" placeholder="new task" required>
        <button type="submit">Add</button>
      </form>
      <ul>{rows}</ul>
      <footer>Served by: {instance_label}</footer>
    </body>
    </html>
    """


@app.route("/add", methods=["POST"])
def add():
    task = request.form["task"]
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("INSERT INTO todos (task) VALUES (%s)", (task,))
    conn.commit()
    cur.close()
    conn.close()
    return redirect("/")


@app.route("/toggle/<int:todo_id>")
def toggle(todo_id):
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("UPDATE todos SET done = NOT done WHERE id = %s", (todo_id,))
    conn.commit()
    cur.close()
    conn.close()
    return redirect("/")


@app.route("/delete/<int:todo_id>")
def delete(todo_id):
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("DELETE FROM todos WHERE id = %s", (todo_id,))
    conn.commit()
    cur.close()
    conn.close()
    return redirect("/")


if __name__ == "__main__":
    for attempt in range(30):
        try:
            init_db()
            break
        except Exception as exc:
            print(f"DB not ready yet (attempt {attempt}): {exc}")
            time.sleep(10)
    app.run(host="0.0.0.0", port=8080)
PYEOF

cat <<EOF > /etc/systemd/system/todo-app.service
[Unit]
Description=Terraform Todo App
After=network.target

[Service]
Environment=DB_HOST=${db_host}
Environment=DB_NAME=${db_name}
Environment=DB_USER=${db_user}
Environment=DB_PASS=${db_pass}
Environment=INSTANCE_LABEL=${instance_label}
ExecStart=/usr/bin/python3 /home/ubuntu/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable todo-app
systemctl start todo-app

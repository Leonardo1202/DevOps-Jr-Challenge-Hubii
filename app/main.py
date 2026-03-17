import os

from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/health")
def health():
    return jsonify({
        "status": "ok",
        "version": "1.0.0",
        "environment": os.getenv("APP_ENV", "development")
    }), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
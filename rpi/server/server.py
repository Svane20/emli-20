from flask import Flask, send_from_directory, jsonify, render_template_string
import os

app = Flask(__name__)
BASE_DIR = '/home/emli/camera'
IGNORE_DIR = 'temp'

LOG_DIR = '/home/emli/logs'
LOG_FILE = 'wildlife_camera.log'


@app.route('/')
def index():
    # Collect all image and JSON files
    files = []
    for root, dirs, filenames in os.walk(BASE_DIR):
        if IGNORE_DIR in root:
            continue

        for filename in filenames:
            if filename.endswith('.jpg'):
                json_file = filename.replace('.jpg', '.json')
                files.append({
                    'image': filename,
                    'json': json_file,
                    'path': root.replace(BASE_DIR, '')
                })

    return render_template_string("""
        <html>
        <body>
            <h1>Wildlife Camera Images</h1>
            <ul>
            {% for file in files %}
                <li>
                    <a href="{{ url_for('get_image', path=file.path, filename=file.image) }}">
                        {{ file.image }}
                    </a>
                    (<a href="{{ url_for('get_metadata', path=file.path, filename=file.json) }}">
                        metadata
                    </a>)
                </li>
            {% endfor %}
            </ul>
            <h2>Log File</h2>
            <a href="{{ url_for('get_log') }}">View Log File</a>
        </body>
        </html>
    """, files=files)


@app.route('/images/<path:path>/<filename>')
def get_image(path, filename):
    directory = os.path.join(BASE_DIR, path)
    return send_from_directory(directory, filename)


@app.route('/metadata/<path:path>/<filename>')
def get_metadata(path, filename):
    directory = os.path.join(BASE_DIR, path)
    return send_from_directory(directory, filename, mimetype='application/json')


@app.route('/log')
def get_log():
    return send_from_directory(LOG_DIR, LOG_FILE, mimetype='text/plain')


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

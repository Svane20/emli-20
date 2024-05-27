from flask import Flask, send_from_directory, render_template_string
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
        <head>
            <style>
                .image-preview {
                    width: 200px;
                    height: 200px;
                    object-fit: cover;
                }
                .image-list {
                    list-style-type: none;
                    padding: 0;
                    display: flex;
                    flex-wrap: wrap;
                }
                .image-list li {
                    margin: 10px;
                    flex: 1 1 calc(33.333% - 20px);
                    box-sizing: border-box;
                }
                .image-container {
                    text-align: center;
                }
                .log-button {
                    display: inline-block;
                    padding: 10px 20px;
                    font-size: 16px;
                    cursor: pointer;
                    text-align: center;
                    text-decoration: none;
                    outline: none;
                    color: #fff;
                    background-color: #4CAF50;
                    border: none;
                    border-radius: 15px;
                    box-shadow: 0 9px #999;
                    margin-bottom: 20px;
                }
                .log-button:hover {background-color: #3e8e41}
                .log-button:active {
                    background-color: #3e8e41;
                    box-shadow: 0 5px #666;
                    transform: translateY(4px);
                }
                .log-heading {
                    color: #4CAF50;
                    font-size: 24px;
                    margin: 20px 0 10px 0;
                }
            </style>
        </head>
        <body>
            <h1>Wildlife Camera Images</h1>
            <a href="{{ url_for('get_log') }}" class="log-button">View Log File</a>
            <ul class="image-list">
            {% for file in files %}
                <li>
                    <div class="image-container">
                        <a href="{{ url_for('get_metadata', path=file.path, filename=file.json) }}">
                            <img src="{{ url_for('get_image', path=file.path, filename=file.image) }}" alt="{{ file.image }}" class="image-preview">
                        </a>
                        <br>{{ file.image }}
                    </div>
                </li>
            {% endfor %}
            </ul>
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
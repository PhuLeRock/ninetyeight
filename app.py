from flask import Flask, request, jsonify

app = Flask(__name__)
files = {}
# Limit file upload size to 50MB
#app.config['MAX_CONTENT_LENGTH'] = 50 * 1024 * 1024

@app.route('/files', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    files[file.filename] = file.read()
    return jsonify({'message': 'File uploaded successfully'}), 201

@app.route('/files', methods=['GET'])
def list_files():
    return jsonify(list(files.keys()))

@app.route('/files/<filename>', methods=['GET'])
def get_file(filename):
    if filename not in files:
        return jsonify({'error': 'File not found'}), 404
    return files[filename]

@app.route('/files/<filename>', methods=['DELETE'])
def delete_file(filename):
    if filename not in files:
        return jsonify({'error': 'File not found'}), 404
    del files[filename]
    return jsonify({'message': 'File deleted successfully'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
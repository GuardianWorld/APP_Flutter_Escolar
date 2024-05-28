import eventlet
import eventlet.wsgi
eventlet.monkey_patch()


import jwt
import datetime
from flask import Flask, request, jsonify
from flask_socketio import SocketIO, emit
from flask_cors import CORS
import sqlite3
import json

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")
CORS(app)

## Gen secret key

SECRET_KEY = 'secret_key'

def generate_token(user_id):
    payload = {
        'user_id': user_id,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=1)  # Token expires in 1 hour
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm='HS256')
    return token

## Database

def init_db():
    conn = sqlite3.connect('database.db')
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, cpf TEXT, name TEXT, password TEXT, user_type TEXT, license TEXT, plate TEXT)''')
    c.execute('''CREATE TABLE IF NOT EXISTS children (id INTEGER PRIMARY KEY, name TEXT, user_id INTEGER, driver_id INTEGER)''')
    c.execute('''CREATE TABLE IF NOT EXISTS notifications (id INTEGER PRIMARY KEY, message TEXT, sender_id INTEGER, receiver_id INTEGER)''')
    conn.commit()
    conn.close()

@app.route('/register', methods=['POST'])
def register():
    try:
        print("Registration Data:", request.json)
        
        data = request.json
        cpf = data.get('cpf')
        name = data.get('name')
        password = data.get('password')
        user_type = data.get('user_type')  # 'user' or 'driver'
        license = data.get('license', '')
        plate = data.get('plate', '')

        conn = sqlite3.connect('database.db')
        c = conn.cursor()
        c.execute('INSERT INTO users (cpf, name, password, user_type, license, plate) VALUES (?, ?, ?, ?, ?, ?)',
                  (cpf, name, password, user_type, license, plate))
        conn.commit()
        conn.close()
        return jsonify({'status': 'success'})
    except Exception as e:
        return jsonify({'status': 'failure', 'error': str(e)}), 500

@app.route('/login', methods=['POST'])
def login():
    data = request.json
    cpf = data.get('cpf')
    password = data.get('password')
    
    conn = sqlite3.connect('database.db')
    c = conn.cursor()
    c.execute('SELECT * FROM users WHERE cpf = ? AND password = ?', (cpf, password))
    user = c.fetchone()
    conn.close()
    
    if user:
        user_id = user[0]
        token = generate_token(user_id)
        return jsonify({'status': 'success', 'token': token, 'user': user})
    else:
        return jsonify({'status': 'failure'}), 401

@app.route('/protected', methods=['GET'])
def protected():
    token = request.headers.get('Authorization')
    if not token:
        return jsonify({'status': 'failure', 'message': 'Token is missing'}), 401
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
        user_id = payload['user_id']
        # Access the protected resource with the user ID
        return jsonify({'status': 'success', 'user_id': user_id})
    except jwt.ExpiredSignatureError:
        return jsonify({'status': 'failure', 'message': 'Token has expired'}), 401
    except jwt.InvalidTokenError:
        return jsonify({'status': 'failure', 'message': 'Invalid token'}), 401

@app.route('/children', methods=['POST'])
def add_child():
    data = request.json
    name = data.get('name')
    user_id = data.get('user_id')
    driver_id = data.get('driver_id')
    
    conn = sqlite3.connect('database.db')
    c = conn.cursor()
    c.execute('INSERT INTO children (name, user_id, driver_id) VALUES (?, ?, ?)',
              (name, user_id, driver_id))
    conn.commit()
    conn.close()
    return jsonify({'status': 'success'})

@app.route('/notifications', methods=['POST'])
def send_notification():
    data = request.json
    message = data.get('message')
    sender_id = data.get('sender_id')
    receiver_id = data.get('receiver_id')
    
    conn = sqlite3.connect('database.db')
    c = conn.cursor()
    c.execute('INSERT INTO notifications (message, sender_id, receiver_id) VALUES (?, ?, ?)',
              (message, sender_id, receiver_id))
    conn.commit()
    conn.close()
    socketio.emit('notification', {'message': message, 'receiver_id': receiver_id}, broadcast=True)
    return jsonify({'status': 'success'})

@socketio.on('connect')
def handle_connect():
    print('Client connected')
    emit('response', {'message': 'Connected to the server'})

@socketio.on('disconnect')
def handle_disconnect():
    print('Client disconnected')

@socketio.on('location')
def handle_location(data):
    print(f"Received location: {data}")
    # You can process the GPS data here (e.g., store it in the database)

if __name__ == '__main__':
    init_db()
    
    socketio.run(app, host='127.0.0.1', port=5000, debug=True)
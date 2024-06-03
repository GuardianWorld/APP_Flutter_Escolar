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
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=1) 
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm='HS256')
    return token

## Database

def init_db():
    conn = sqlite3.connect('database.db')
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, cpf TEXT, name TEXT, password TEXT, user_type TEXT, license TEXT, plate TEXT)''')
    c.execute('''CREATE TABLE IF NOT EXISTS children (id INTEGER PRIMARY KEY, name TEXT, school TEXT, address TEXT, user_id INTEGER, driver_id INTEGER)''')
    c.execute('''CREATE TABLE IF NOT EXISTS notifications (id INTEGER PRIMARY KEY, message TEXT, sender_id INTEGER, receiver_id INTEGER, read INTEGER DEFAULT 0)''')
    c.execute('''CREATE TABLE IF NOT EXISTS contracts (id INTEGER PRIMARY KEY, notificationID INTEGER, child_id INTEGER, driver_id INTEGER, school_id INTEGER, status TEXT, date TEXT)''')
    c.execute('''CREATE TABLE IF NOT EXISTS school (id INTEGER PRIMARY KEY, name TEXT, address TEXT)''')
    c.execute('''CREATE TABLE IF NOT EXISTS school_driver (id INTEGER PRIMARY KEY, school_id INTEGER, driver_id INTEGER)''')
    
    conn.commit()
    conn.close()

## Auxiliar functions

def validate_token():
    token = request.headers.get('Authorization')
    if not token:
        return None, jsonify({'status': 'failure', 'message': 'Token is missing'}), 401
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
        user_id = payload['user_id']
        return user_id, None, None
    except jwt.ExpiredSignatureError:
        return None, jsonify({'status': 'failure', 'message': 'Token has expired'}), 401
    except jwt.InvalidTokenError:
        return None, jsonify({'status': 'failure', 'message': 'Invalid token'}), 401

def get_db_connection():
    conn = sqlite3.connect('database.db')
    c = conn.cursor()
    return conn, c

@app.route('/register', methods=['POST'])
def register():
    try:        
        data = request.json
        cpf = data.get('cpf')
        name = data.get('name')
        password = data.get('password')
        user_type = data.get('user_type')  # 'user' or 'driver'
        license = data.get('license', '')
        plate = data.get('plate', '')

        conn, c = get_db_connection()
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
    
    conn, c = get_db_connection()
    c.execute('SELECT * FROM users WHERE cpf = ? AND password = ?', (cpf, password))
    user = c.fetchone()
    conn.close()
    
    if user:
        user_id = user[0]
        user_type = user[4]
        token = generate_token(user_id)
        return jsonify({'status': 'success', 'token': token, 'user': user, 'user_type': user_type})
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

@app.route('/profile', methods=['GET'])
def get_profile():
    # Validate token and retrieve user ID
    user_id, error_response, status_code = validate_token()
    if error_response:
        return error_response, status_code

    # Connect to the database
    conn, c = get_db_connection()
    c.execute('SELECT name, cpf FROM users WHERE id = ?', (user_id,))
    user = c.fetchone()
    conn.close()

    # Return user profile data
    if user:
        return jsonify({'status': 'success', 'name': user[0], 'cpf': user[1]})
    else:
        return jsonify({'status': 'failure', 'message': 'User not found'}), 404
    
@app.route('/children', methods=['GET', 'POST', 'DELETE'])
def manage_children():
    # Validate token and retrieve user ID
    user_id, error_response, status_code = validate_token()
    if error_response:
        return error_response, status_code

    # Connect to the database
    conn, c = get_db_connection()

    if request.method == 'GET':
        # Fetch children data for the user
        c.execute('SELECT id, name, school, address, driver_id FROM children WHERE user_id = ?', (user_id,))
        children = c.fetchall()

        children_list = []
        for child in children:
            child_id, name, school, address, driver_id = child
            if driver_id == -1 or driver_id is None:
                driver_name = 'Nenhum'
            else:
                c.execute('SELECT name FROM users WHERE id = ?', (driver_id,))
                driver = c.fetchone()
                driver_name = driver[0] if driver else 'Nenhum'
            
            children_list.append({
                'id': child_id,
                'name': name,
                'school': school,
                'address': address,
                'driver_name': driver_name,
                'driver_id': driver_id
            })

        conn.close()
        return jsonify({'status': 'success', 'children': children_list})

    elif request.method == 'POST':
        # Add a new child for the user
        data = request.json
        name = data.get('name')
        school = data.get('school')
        address = data.get('address')
        c.execute('INSERT INTO children (name, school, address, user_id, driver_id) VALUES (?, ?, ?, ?, ?)', (name, school, address, user_id, None))
        conn.commit()
        conn.close()
        return jsonify({'status': 'success'})

    elif request.method == 'DELETE':
        # Remove a child for the user
        child_id = request.json.get('child_id')
        c.execute('DELETE FROM children WHERE id = ? AND user_id = ?', (child_id, user_id))
        conn.commit()
        conn.close()
        return jsonify({'status': 'success'})

@app.route('/children/without_driver', methods=['GET'])
def get_children_without_driver():
    user_id, error_response, status_code = validate_token()
    if error_response:
        return error_response, status_code

    conn, c = get_db_connection()
    
    c.execute('SELECT id, name, school, address FROM children WHERE driver_id IS NULL AND user_id = ?', (user_id,))
    children = c.fetchall()
    children_list = [{'id': child[0], 'name': child[1], 'school': child[2], 'address': child[3]} for child in children]
    conn.close()
    return jsonify({'status': 'success', 'children': children_list})

@app.route('/schools', methods=['GET'])
def get_schools():
    user_id, error_response, status_code = validate_token()
    if error_response:
        return error_response, status_code

    # Connect to the database
    conn, c = get_db_connection()
    
    c.execute('SELECT name FROM school')
    schools = [row[0] for row in c.fetchall()]
    conn.close()
    return jsonify({'status': 'success', 'schools': schools})

@app.route('/link_school', methods=['POST'])
def link_school():
    
    driver_id, error_response, status_code = validate_token()
    if error_response:
        return error_response, status_code

    # Connect to the database
    conn, c = get_db_connection()
        
    data = request.json
    school_name = data.get('school_name')
    
    # Check if the school exists
    c.execute('SELECT id FROM school WHERE name = ?', (school_name,))
    school = c.fetchone()
    
    if not school:
        return jsonify({'status': 'failure', 'message': 'School not found'}), 404
    
    school_id = school[0]
    
    # Check if the school is already linked to the driver
    c.execute('SELECT id FROM school_driver WHERE school_id = ? AND driver_id = ?', (school_id, driver_id))
    link = c.fetchone()
    
    if link:
        conn.close()
        return jsonify({'status': 'failure', 'message': 'School is already assigned to the driver'}), 409
    
    # Link the school to the driver
    c.execute('INSERT INTO school_driver (school_id, driver_id) VALUES (?, ?)', (school_id, driver_id))
    conn.commit()
    conn.close()
    
    return jsonify({'status': 'success'})

@app.route('/add_school', methods=['POST'])
def add_school():
    user_id, error_response, status_code = validate_token()
    if error_response:
        return error_response, status_code

    # Connect to the database
    conn, c = get_db_connection()
        
    data = request.json
    school_name = data.get('school_name')
    school_address = data.get('school_address')
    
    # Check if the school already exists
    if not school_name:
        return jsonify({'status': 'failure', 'message': 'School name required'}), 400
    
    c.execute('SELECT id FROM school WHERE name = ?', (school_name,))
    school = c.fetchone()
    
    if school:
        conn.close()
        return jsonify({'status': 'failure', 'message': 'School already exists'}), 409
    
    # Add the new school
    c.execute('INSERT INTO school (name, address) VALUES (?, ?)', (school_name, school_address))
    conn.commit()
    conn.close()
    
    return jsonify({'status': 'success'})

@app.route('/school/drivers', methods=['POST'])
def get_school_drivers():
    user_id, error_response, status_code = validate_token()
    if error_response:
        return error_response, status_code

    # Connect to the database
    conn, c = get_db_connection()
        
    data = request.json
    school_name = data.get('school_name')
    
    # Check if the school exists
    c.execute('SELECT id FROM school WHERE name = ?', (school_name,))
    school = c.fetchone()
    
    if not school:
        return jsonify({'status': 'failure', 'message': 'School not found'}), 404
    
    school_id = school[0]
    
    # Fetch drivers assigned to the school with their names
    c.execute('''
        SELECT d.id, d.name
        FROM school_driver sd
        JOIN users d ON sd.driver_id = d.id
        WHERE sd.school_id = ?
    ''', (school_id,))
    
    drivers = [{'id': row[0], 'name': row[1]} for row in c.fetchall()]
    conn.close()
    
    return jsonify({'status': 'success', 'drivers': drivers})


# Driver API

@app.route('/driver/profile', methods=['GET'])
def get_driver_profile():
    # Validate token and retrieve user ID
    user_id, error_response, status_code = validate_token()
    if error_response:
        return error_response, status_code

    # Connect to the database
    conn, c = get_db_connection()
    c.execute('SELECT name, cpf, license, plate FROM users WHERE id = ?', (user_id,))
    user = c.fetchone()
    conn.close()

    # Return user profile data
    if user:
        return jsonify({'status': 'success', 'name': user[0], 'cpf': user[1], 'license': user[2], 'plate': user[3]})
    else:
        return jsonify({'status': 'failure', 'message': 'User not found'}), 404

@app.route('/driver/children', methods=['GET'])
def get_driver_children():
    # Validate token and retrieve user ID
    user_id, error_response, status_code = validate_token()
    if error_response:
        return error_response, status_code

    conn, c = get_db_connection()

    c.execute('SELECT id, name, school, address FROM children WHERE driver_id = ?', (user_id,))
    children = c.fetchall()
    if not children:
        return jsonify({'status': 'failure', 'message': 'No children assigned to this driver'}), 204
    
    children_list = [{'id': child[0], 'name': child[1], 'school': child[2], 'address': child[3]} for child in children]
    conn.close()
    return jsonify({'status': 'success', 'children': children_list})

@app.route('/driver/schools', methods=['GET'])
def get_driver_schools():
    # Validate token and retrieve user ID
    user_id, error_response, status_code = validate_token()
    if error_response:
        return error_response, status_code

    conn, c = get_db_connection()

    # Join school_driver and school tables to get the school names
    c.execute('''
        SELECT sd.id, s.name, s.address
        FROM school_driver sd
        JOIN school s ON sd.school_id = s.id
        WHERE sd.driver_id = ?
    ''', (user_id,))
    
    schools = c.fetchall()
    conn.close()

    if not schools:
        return jsonify({'status': 'failure', 'message': 'No schools assigned to this driver'}), 204

    school_list = [{'id': school[0], 'name': school[1], 'address': school[2]} for school in schools]
    
    return jsonify({'status': 'success', 'schools': school_list})

@app.route('/remove_child_contract', methods=['POST'])
def remove_child():
    user_id, error_response, status_code = validate_token()
    if error_response:
        return error_response, status_code

    data = request.get_json()
    child_id = data.get('child_id')

    conn, c = get_db_connection()
    
    # Ensure the child belongs to the driver
    c.execute('SELECT driver_id FROM children WHERE id = ?', (child_id,))
    child = c.fetchone()
    
    if child and child[0] == user_id:
        c.execute('UPDATE children SET driver_id = NULL WHERE id = ?', (child_id,))
        conn.commit()
        conn.close()
        return jsonify({'status': 'success'})
    else:
        conn.close()
        return jsonify({'status': 'error', 'message': 'Child not found or does not belong to the driver'}), 404


# Notifications

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

@app.route('/notifications', methods=['GET'])
def get_notifications():
    user_id, error_response, status_code = validate_token()
    if error_response:
        return error_response, status_code

    conn, c = get_db_connection()
    
    # Modified query to join with the users table to get the sender's name
    c.execute('''
        SELECT n.id, n.message, n.sender_id, u.name as sender_name 
        FROM notifications n
        JOIN users u ON n.sender_id = u.id
        WHERE n.receiver_id = ? AND n.read = 0
    ''', (user_id,))
    
    notifications = c.fetchall()
    
    notifications_list = []
    for notification in notifications:
        notification_id = notification[0]
        message = notification[1]
        sender_id = notification[2]
        sender_name = notification[3]
        
        # Check if this notification is related to a contract
        c.execute('''
            SELECT c.id, c.child_id, c.driver_id, c.school_id, c.status, c.date, ch.name as child_name, s.name as school_name, ch.address as child_address
            FROM contracts c
            JOIN children ch ON c.child_id = ch.id
            JOIN school s ON c.school_id = s.id
            WHERE c.notificationID = ? AND c.status = 'pending'
        ''', (notification_id,))
        
        contract = c.fetchone()
        
        if contract:
            # Craft the message for contract notifications
            message = f'{sender_name} quer contratar você para a criança {contract[6]}, endereço: {contract[8]}, Escola: {contract[7]}'
            notification_type = 'contract'
        else:
            notification_type = 'normal'
        
        notifications_list.append({
            'id': notification_id,
            'message': message,
            'sender_id': sender_id,
            'sender_name': sender_name,
            'type': notification_type
        })
    
    conn.close()
    return jsonify({'status': 'success', 'notifications': notifications_list})




@app.route('/contracts', methods=['GET'])
def get_contracts():
    user_id, error_response, status_code = validate_token()
    if error_response:
        return error_response, status_code

    conn, c = get_db_connection()
    c.execute('SELECT c.id, n.message, c.status, c.date FROM contracts c JOIN notifications n ON c.notificationID = n.id WHERE c.child_id IN (SELECT id FROM children WHERE driver_id = ?)', (user_id,))
    contracts = c.fetchall()
    contracts_list = [{'id': contract[0], 'message': contract[1], 'status': contract[2], 'date': contract[3]} for contract in contracts]
    conn.close()
    return jsonify({'status': 'success', 'contracts': contracts_list})

@app.route('/contract_notification', methods=['POST'])
def send_contract_notification():
    user_id, error_response, status_code = validate_token()
    if error_response:
        return error_response, status_code

    conn, c = get_db_connection()

    #First step, make the notification itself.
    data = request.json
    
    school_name = data.get('school_name')
    school_id = c.execute('SELECT id FROM school WHERE name = ?', (school_name,)).fetchone()[0]
    driver_id = data.get('driver_id')  # Is also ReceiverID
    child_id = data.get('child_id')
    
    # Fetch the names of user_id and driver_id
    user_name = c.execute('SELECT name FROM users WHERE id = ?', (user_id,)).fetchone()[0]
    driver_name = c.execute('SELECT name FROM users WHERE id = ?', (driver_id,)).fetchone()[0]

    # Create a detailed message
    message = f'Contrato entre {user_name} e {driver_name}'

    c.execute('INSERT INTO notifications (message, sender_id, receiver_id) VALUES (?, ?, ?)',
              (message, user_id, driver_id))
    
    # Make contract now.
    c.execute('INSERT INTO contracts (notificationID, child_id, driver_id, school_id, status, date) VALUES (?, ?, ?, ?, ?, ?)',
              (c.lastrowid, child_id, driver_id, school_id, "pending", datetime.datetime.now()))
    conn.commit()
    conn.close()
    
    return jsonify({'status': 'success'})

@app.route('/accept_contract', methods=['POST'])
def accept_contract():
    user_id, error_response, status_code = validate_token()
    if error_response:
        return error_response, status_code

    notification_id = request.form['notification_id']

    conn, c = get_db_connection()
    
    # Fetch the ChildID and DriverID from the contracts table
    c.execute('SELECT child_id, driver_id FROM contracts WHERE notificationID = ?', (notification_id,))
    contract = c.fetchone()

    if contract:
        child_id = contract[0]
        driver_id = contract[1]

        # Update the contract status to 'accepted'
        c.execute('UPDATE contracts SET status = "accepted" WHERE notificationID = ?', (notification_id,))

        # Update the DriverID field in the children table
        c.execute('UPDATE children SET driver_id = ? WHERE id = ?', (driver_id, child_id))

        conn.commit()
        conn.close()
        return jsonify({'status': 'success'})
    else:
        conn.close()
        return jsonify({'status': 'error', 'message': 'Contract not found'}), 404

@app.route('/reject_contract', methods=['POST'])
def reject_contract():
    user_id, error_response, status_code = validate_token()
    if error_response:
        return error_response, status_code

    notification_id = request.form['notification_id']

    conn, c = get_db_connection()
    c.execute('UPDATE contracts SET status = "rejected" WHERE notificationID = ?', (notification_id,))
    conn.commit()
    conn.close()

    return jsonify({'status': 'success'})

@app.route('/acknowledge_notification', methods=['POST'])
def acknowledge_notification():
    user_id, error_response, status_code = validate_token()
    if error_response:
        return error_response, status_code

    notification_id = request.form['notification_id']

    conn, c = get_db_connection()
    c.execute('UPDATE notifications SET read = 1 WHERE id = ?', (notification_id,))
    conn.commit()
    conn.close()

    return jsonify({'status': 'success'})

@app.route('/notify_absence', methods=['POST'])
def notify_absence():
    user_id, error_response, status_code = validate_token()
    if error_response:
        return error_response, status_code

    conn, c = get_db_connection()

    data = request.json
    child_id = data.get('child_id')
    absence_date = datetime.date.today()

    # Fetch the child details and their associated driver
    child = c.execute('SELECT name, driver_id FROM children WHERE id = ?', (child_id,)).fetchone()
    if not child:
        return jsonify({'status': 'error', 'message': 'Child not found'}), 404

    child_name = child[0]
    driver_id = child[1]

    if driver_id is None or driver_id == -1:
        return jsonify({'status': 'error', 'message': 'Child does not have an assigned driver'}), 400

    # Fetch the names of user_id and driver_id
    user_name = c.execute('SELECT name FROM users WHERE id = ?', (user_id,)).fetchone()[0]
    driver_name = c.execute('SELECT name FROM users WHERE id = ?', (driver_id,)).fetchone()[0]

    # Create a detailed message
    message = f'Notificação de ausência: {child_name} estará ausente no dia {absence_date}'

    c.execute('INSERT INTO notifications (message, sender_id, receiver_id, read) VALUES (?, ?, ?, ?)',
              (message, user_id, driver_id, 0))

    conn.commit()
    conn.close()

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
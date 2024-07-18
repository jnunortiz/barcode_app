from flask import Flask, jsonify, request
from flask_cors import CORS
import random
import datetime

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Hardcoded list of 10 barcode numbers
barcodes = [
    "1234567890",
    "2345678901",
    "3456789012",
    "4567890123",
    "5678901234",
    "6789012345",
    "7890123456",
    "8901234567",
    "9012345678",
    "0123456789"
]

# Sample events and terminals
events = ["Scanned", "Delivered", "Returned", "Processed"]
terminals = ["A", "B", "C", "D", "E"]

@app.route('/search', methods=['POST'])
def search_barcodes():
    data = request.json
    barcodes_to_search = data.get('barcodes', [])

    # Simulate searching and returning results
    results = []
    for barcode in barcodes_to_search:
        if barcode in barcodes:
            # Generate a random event, terminal, and timestamp for the barcode
            event = random.choice(events)
            terminal = random.choice(terminals)
            timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            results.append({
                'barcode_number': barcode,
                'event': event,
                'terminal': terminal,
                'timestamp': timestamp
            })

    return jsonify(results)

@app.route('/generate_data', methods=['GET'])
def generate_data():
    data = []
    for _ in range(100):  # Generate 100 lines of data
        barcode = random.choice(barcodes)
        event = random.choice(events)
        terminal = random.choice(terminals)
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        data.append({
            'barcode_number': barcode,
            'event': event,
            'terminal': terminal,
            'timestamp': timestamp
        })
    return jsonify(data)

if __name__ == '__main__':
    app.run(debug=True)

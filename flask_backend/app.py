from flask import Flask, jsonify, request
from flask_cors import CORS
import random
import datetime

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Set a fixed seed for reproducibility
SEED = 42
random.seed(SEED)

def generate_piece_code():
    return ''.join(random.choices("0123456789", k=14))

def generate_random_data():
    now = datetime.datetime.now()
    data = {
        'Piece Pin': generate_piece_code(),
        'Shipment Pin': generate_piece_code(),
        'Scan Date': now.strftime("%Y-%m-%d"),
        'Scan Time': now.strftime("%H:%M:%S"),
        'System Update Date': now.strftime("%Y-%m-%d %H:%M:%S"),
        'Terminal Name': f"Terminal{random.randint(1, 10)}",
        'Terminal Id': generate_piece_code(),
        'Route': f"Route{random.randint(1, 10)}",
        'Scan Code': f"Code{random.randint(100, 999)}",
        'Event Reason Code': f"Reason{random.randint(1, 5)}",
        'Event Code Desc[Eng]': f"EventDesc{random.randint(1, 10)}",
        'Event Code Desc[Fr]': f"EventDesc{random.randint(1, 10)}",
        'Comment': f"Comment {random.randint(1, 100)}",
        'Delivery Signature': f"Signature{random.randint(1, 100)}",
        'Expected Delivery Date': (now + datetime.timedelta(days=random.randint(1, 10))).strftime("%Y-%m-%d"),
        'Service Date': now.strftime("%Y-%m-%d"),
        'Origin Terminal Name': f"OriginTerminal{random.randint(1, 10)}",
        'Origin Terminal Id': generate_piece_code(),
        'Origin City': f"City{random.randint(1, 10)}",
        'Origin Province': f"Province{random.randint(1, 10)}",
        'Origin FSA': f"FSA{random.randint(100, 999)}",
        'Origin PC': f"PostalCode{random.randint(1000, 9999)}",
        'Origin Country Code': f"Country{random.randint(1, 10)}",
        'Destination Terminal Id': generate_piece_code(),
        'Destination Terminal Name': f"DestinationTerminal{random.randint(1, 10)}",
        'Destination City': f"City{random.randint(1, 10)}",
        'Destination Province': f"Province{random.randint(1, 10)}",
        'Destination FSA': f"FSA{random.randint(100, 999)}",
        'Destination PC': f"PostalCode{random.randint(1000, 9999)}",
        'Destination Country Code': f"Country{random.randint(1, 10)}",
        'Account Number': f"Account{random.randint(1000, 9999)}",
        'Exp Mode of Trans': f"Mode{random.randint(1, 3)}",
        'Product Code': f"Product{random.randint(100, 999)}",
        'Revised Initial Transit Days': random.randint(1, 15),
        'Delivery Company Name': f"Company{random.randint(1, 10)}",
        'Event Address Line 1': f"Address Line 1 {random.randint(1, 100)}",
        'Event Address Line 2': f"Address Line 2 {random.randint(1, 100)}",
        'Event City': f"EventCity{random.randint(1, 10)}",
        'Event Province': f"EventProvince{random.randint(1, 10)}",
        'Event Country': f"EventCountry{random.randint(1, 10)}",
        'Event Postal Code': f"PostalCode{random.randint(1000, 9999)}",
        'Delivery SNR Pin': generate_piece_code(),
        'Delivery OSNR Flag': random.choice(["Yes", "No"]),
        'Cross Reference Pin': generate_piece_code(),
        'Container Id': generate_piece_code(),
        'Container Type': f"Type{random.randint(1, 5)}",
        'Pickup Delivery Location': f"Location{random.randint(1, 10)}",
        'Scan Srouce System Code': f"SourceCode{random.randint(1, 10)}",
        'Scan Source Reference Code': generate_piece_code(),
        'Source Code': f"Source{random.randint(1, 10)}"
    }
    print(f"Generated Piece Pin: {data['Piece Pin']}")  # Print generated Piece Pin for debugging
    return data

# Store the generated data in memory for quick access
mock_data_store = [generate_random_data() for _ in range(100)]

@app.route('/search', methods=['POST'])
def search_pieces():
    data = request.json
    piece_pins_to_search = data.get('piece_pins', [])  # Updated to 'piece_pins'

    # Filter the mock data based on the 'Piece Pin' column
    results = [entry for entry in mock_data_store if entry['Piece Pin'] in piece_pins_to_search]

    return jsonify(results)

@app.route('/generate_data', methods=['GET'])
def generate_data():
    data = [generate_random_data() for _ in range(100)]  # Generate 100 lines of data
    return jsonify(data)

if __name__ == '__main__':
    app.run(debug=True)

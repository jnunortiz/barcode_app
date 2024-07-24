from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import List
import io
import csv
import random

app = FastAPI()

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # You can specify allowed origins here
    allow_credentials=True,
    allow_methods=["*"],  # Allows all HTTP methods
    allow_headers=["*"],  # Allows all headers
)

# Define the model for the search request
class SearchRequest(BaseModel):
    piece_pins: List[str]

# Mock data storage
data_store = {}

# Generate mock data for demonstration
def generate_mock_data(count: int):
    global data_store
    data_store = {
        f"{random.randint(10000000000000, 99999999999999)}": {
            "Piece Pin": f"{random.randint(10000000000000, 99999999999999)}",
            "Shipment Pin": f"{random.randint(10000000000000, 99999999999999)}",
            "Scan Date": "2024-07-23",
            "Scan Time": "12:00",
            "System Update Date": "2024-07-23",
            "Terminal Name": f"Terminal {i}",
            "Terminal Id": f"T{i:05}",
            "Route": f"Route {i}",
            "Scan Code": f"Scan{i:05}",
            "Event Reason Code": f"Event{i:05}",
            "Event Code Desc[Eng]": f"Desc Eng {i:05}",
            "Event Code Desc[Fr]": f"Desc Fr {i:05}",
            "Comment": f"Comment {i:05}",
            "Delivery Signature": f"Signature {i:05}",
            "Expected Delivery Date": "2024-07-30",
            "Service Date": "2024-07-23",
            "Origin Terminal Name": f"Origin Terminal {i}",
            "Origin Terminal Id": f"OT{i:05}",
            "Origin City": "City A",
            "Origin Province": "Province A",
            "Origin FSA": "FSA A",
            "Origin PC": "PC A",
            "Origin Country Code": "CA",
            "Destination Terminal Id": f"DT{i:05}",
            "Destination Terminal Name": f"Destination Terminal {i}",
            "Destination City": "City B",
            "Destination Province": "Province B",
            "Destination FSA": "FSA B",
            "Destination PC": "PC B",
            "Destination Country Code": "US",
            "Account Number": f"Account{i:05}",
            "Exp Mode of Trans": "Mode A",
            "Product Code": f"Product{i:05}",
            "Revised Initial Transit Days": "5",
            "Delivery Company Name": "Company A",
            "Event Address Line 1": f"Address 1 {i:05}",
            "Event Address Line 2": f"Address 2 {i:05}",
            "Event City": "Event City",
            "Event Province": "Event Province",
            "Event Country": "Event Country",
            "Event Postal Code": "Postal Code",
            "Delivery SNR Pin": f"SNR{i:05}",
            "Delivery OSNR Flag": "Flag A",
            "Cross Reference Pin": f"CR{i:05}",
            "Container Id": f"Container{i:05}",
            "Container Type": "Type A",
            "Pickup Delivery Location": "Location A",
            "Scan Source System Code": "System Code",
            "Scan Source Reference Code": "Reference Code",
            "Source Code": "Source Code",
        }
        for i in range(count)
    }

# Generate initial data on startup
@app.on_event("startup")
async def startup_event():
    generate_mock_data(100)

# Endpoint to search piece pins
@app.post("/search")
async def search_piece_pins(request: SearchRequest, page: int = 1, size: int = 10):
    piece_pins = request.piece_pins
    results = [data_store.get(pin, {}) for pin in piece_pins]

    # Pagination
    start = (page - 1) * size
    end = start + size
    paginated_results = results[start:end]
    
    return {
        "results": paginated_results,
        "total": len(results)
    }

# Endpoint to get all piece pins for testing
@app.get("/get_data")
async def get_data():
    if not data_store:
        return {"message": "No data available. Please generate data first."}
    return {"piece_pins": list(data_store.keys())}

# Endpoint to generate mock data
@app.post("/generate_data")
async def generate_data(count: int):
    generate_mock_data(count)
    return {"message": f"Generated {count} data entries"}

# Function to generate CSV data
def generate_csv():
    output = io.StringIO()
    if not data_store:
        return output
    fieldnames = list(next(iter(data_store.values())).keys())
    writer = csv.DictWriter(output, fieldnames=fieldnames)
    writer.writeheader()
    for item in data_store.values():
        writer.writerow(item)
    output.seek(0)
    return output

# Endpoint to export all data as CSV
@app.get("/export_csv")
async def export_csv():
    buffer = generate_csv()
    return StreamingResponse(
        buffer,
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=data_store.csv"}
    )

# Root endpoint
@app.get("/")
async def root():
    return {"message": "Welcome to the Barcode API"}

# Run the application
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=5000, reload=True)

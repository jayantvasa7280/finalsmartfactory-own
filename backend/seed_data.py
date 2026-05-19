import os
import json
from dotenv import load_dotenv
from azure.cosmos import CosmosClient

load_dotenv("../.env")

conn_str = os.getenv("COSMOS_CONN_WRITE")

if not conn_str:
    print("Error: COSMOS_CONN_WRITE not found in .env")
    exit(1)

client = CosmosClient.from_connection_string(conn_str)
db = client.get_database_client("llmops-data")

def seed_container(filepath, container_name):
    print(f"\n--- Seeding '{filepath}' into '{container_name}' ---")
    try:
        container = db.get_container_client(container_name)
        with open(filepath, "r") as f:
            data_list = json.load(f)
            
            # Simple check if it's a list
            if not isinstance(data_list, list):
                print("Error: The JSON file must contain a list of objects.")
                return
                
            count = 0
            for item in data_list:
                container.upsert_item(body=item)
                count += 1
            print(f"Successfully inserted {count} items into '{container_name}'.")
            
    except FileNotFoundError:
        print(f"Error: File '{filepath}' not found. Did you type the path correctly?")
    except Exception as e:
        print(f"Error encountered: {str(e)}")

if __name__ == "__main__":
    # --- Base Setup ---
    # These will always run unless commented out
    seed_container("../example_evaluators.json", "evaluators")
    seed_container("../example_templates.json", "templates")
    
    # --- Bulk Data Ingestion ---
    # Comment out the block below if you only want to ingest templates and evaluators
    
    data_dir = "../data"
    if os.path.exists(data_dir):
        print(f"\n--- Starting Bulk Ingestion from {data_dir} ---")
        for filename in os.listdir(data_dir):
            if filename.endswith(".json"):
                container_name = filename[:-5] # Strip the '.json' to get the container name
                filepath = os.path.join(data_dir, filename)
                seed_container(filepath, container_name)
    else:
        print(f"\nData directory '{data_dir}' not found. Skipping bulk ingestion.")
    

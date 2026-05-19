import os
import json
from dotenv import load_dotenv
from azure.cosmos import CosmosClient

# Load variables from project root
load_dotenv("../.env")
conn_str = os.getenv("COSMOS_CONN_WRITE")

if not conn_str:
    print("Error: COSMOS_CONN_WRITE not found in .env")
    exit(1)

client = CosmosClient.from_connection_string(conn_str)
db = client.get_database_client("llmops-data")

containers_to_export = [
    "raw_traces", 
    "traces", 
    "evaluations", 
    "leases", 
    "leases-evaluator", 
    "leases-rca", 
    "audit_logs", 
    "rca_results"
]

# We want the data directory to be in the project root
output_dir = "../data"
os.makedirs(output_dir, exist_ok=True)

for container_name in containers_to_export:
    print(f"Fetching data from '{container_name}'...")
    try:
        container = db.get_container_client(container_name)
        
        # Fetch all items from the container
        items = list(container.query_items(
            query="SELECT * FROM c",
            enable_cross_partition_query=True
        ))
        
        output_path = os.path.join(output_dir, f"{container_name}.json")
        with open(output_path, "w") as f:
            json.dump(items, f, indent=4)
            
        print(f"Successfully saved {len(items)} items to '{output_path}'.")
        
    except Exception as e:
        print(f"Failed to fetch data from '{container_name}': {e}")

print("\nData export complete!")

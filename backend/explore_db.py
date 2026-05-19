import sys
from azure.cosmos import CosmosClient

import os
from dotenv import load_dotenv

# Load variables from project root
load_dotenv("../.env")

conn_str = os.getenv("COSMOS_CONN_WRITE")

if not conn_str:
    print("Error: COSMOS_CONN_WRITE not found in .env")
    sys.exit(1)

print("\nConnecting to local Cosmos DB...")
client = CosmosClient.from_connection_string(conn_str)

try:
    db = client.get_database_client("llmops-data")
except Exception:
    print("Could not find database 'llmops-data'. Did you run setup_db.py?")
    sys.exit(1)

containers = [c['id'] for c in list(db.list_containers())]

print("\n--- LLMOps Local Database Explorer ---")
for idx, c_name in enumerate(containers):
    print(f"[{idx}] {c_name}")

print("\nType the number of the container you want to view (or 'q' to quit):")
choice = input("> ")

if choice.lower() == 'q':
    sys.exit(0)

try:
    container_idx = int(choice)
    selected_container = containers[container_idx]
except (ValueError, IndexError):
    print("Invalid selection.")
    sys.exit(1)

container = db.get_container_client(selected_container)
items = list(container.query_items(
    query="SELECT * FROM c OFFSET 0 LIMIT 10",
    enable_cross_partition_query=True
))

print(f"\n--- Top 10 items in '{selected_container}' ---")
if not items:
    print("Container is empty!")
else:
    import json
    for item in items:
        print(json.dumps(item, indent=2))
        print("-" * 40)

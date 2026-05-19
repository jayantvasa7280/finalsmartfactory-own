from azure.cosmos import CosmosClient, PartitionKey
import sys

import os
from dotenv import load_dotenv

# Load variables from project root
load_dotenv("../.env")

endpoint = os.getenv("COSMOS_ENDPOINT")
key = os.getenv("COSMOS_KEY")

print("Connecting to local Cosmos DB Emulator...")
client = CosmosClient(endpoint, credential=key)

print("Creating database: llmops-data...")
db = client.create_database_if_not_exists(id="llmops-data")

containers = ["traces", "evaluations", "metrics", "templates", "evaluators", "audit_logs", "rca_results", "raw_traces"]

for name in containers:
    print(f"Creating container: {name}...")
    db.create_container_if_not_exists(id=name, partition_key=PartitionKey(path="/id"))

print("Local Database setup complete!")

import os
from dotenv import load_dotenv
from azure.cosmos import CosmosClient

load_dotenv("../.env")
client = CosmosClient(os.getenv("COSMOS_ENDPOINT"), credential=os.getenv("COSMOS_KEY"))
db = client.get_database_client("llmops-data")

containers_to_clear = ["evaluations", "leases-evaluator", "templates"]

for name in containers_to_clear:
    print(f"Deleting container: {name}...")
    try:
        db.delete_container(name)
        print(f"Successfully deleted {name}.")
    except Exception as e:
        print(f"Could not delete {name}. It might not exist. Error: {e}")

print("\nContainers cleared! Run 'python setup_db.py' to recreate empty ones.")

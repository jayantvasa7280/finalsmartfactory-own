import os
from azure.cosmos import CosmosClient, PartitionKey
from dotenv import load_dotenv

# Load environment variables
load_dotenv()
os.environ["AZURE_COSMOS_DISABLE_SSL_CERTIFICATE_VALIDATION"] = "True"

# We try to get the connection string from .env, but default to the standard local emulator one
COSMOS_CONN = os.getenv("COSMOS_CONN_WRITE") or os.getenv("COSMOS-CONN-WRITE")

DATABASE_NAME = "llmops-data"

CONTAINERS = [
    "raw_traces",
    "traces",
    "evaluations",
    "evaluators",
    "templates",
    "audit_logs",
    "rca_results",
    "metrics" 
]

def setup_database():
    print(f"Connecting to Cosmos DB Emulator...")
    print(f"Connection String: {COSMOS_CONN}")
    
    # In local emulator, we often need to disable SSL verification 
    # because of the self-signed certificate. 
    # We pass connection_verify=False to handle this.
    try:
        client = CosmosClient.from_connection_string(
            COSMOS_CONN, 
            connection_verify=False
        )
        
        # 1. Create the Database
        print(f"\nCreating Database '{DATABASE_NAME}'...")
        db = client.create_database_if_not_exists(id=DATABASE_NAME)
        print(f"✅ Database '{DATABASE_NAME}' is ready.")

        # 2. Create Containers
        print("\nCreating Containers...")
        for container_name in CONTAINERS:
            # We use '/id' as a safe default partition key. 
            # In production, you might optimize this per container.
            db.create_container_if_not_exists(
                id=container_name,
                partition_key=PartitionKey(path="/id")
            )
            print(f"✅ Container '{container_name}' is ready.")
            
        print("\n🎉 Database setup complete! All containers are successfully created.")
        
    except Exception as e:
        print(f"\n❌ Error setting up database: {e}")
        print("Please ensure your Cosmos DB Emulator Docker container is running and accessible.")

if __name__ == "__main__":
    import urllib3
    # Suppress InsecureRequestWarning for the local emulator's self-signed cert
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    
    setup_database()

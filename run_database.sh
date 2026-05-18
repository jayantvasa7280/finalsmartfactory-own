#!/bin/bash

# ==============================================================================
# Smart Factory — Local Database & Azurite Environment Runner
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# Define cleanup function for graceful termination on Ctrl+C (SIGINT)
cleanup() {
    echo ""
    echo "========================================================================"
    echo "Caught Ctrl+C! Stopping and removing local Docker containers..."
    echo "========================================================================"
    docker stop cosmosdb-emulator azurite 2>/dev/null || true
    docker rm cosmosdb-emulator azurite 2>/dev/null || true
    echo "Cleanup complete! Local database environment shut down."
    exit 0
}

# Register the cleanup trap
trap cleanup INT

echo "========================================================================"
echo "Starting Smart Factory Local Database & Azurite environment..."
echo "========================================================================"

# 1. Setup local.settings.json in azure-functions/ if it doesn't exist
SETTINGS_FILE="azure-functions/local.settings.json"
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "Creating $SETTINGS_FILE..."
    mkdir -p azure-functions
    cat <<EOT > "$SETTINGS_FILE"
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "COSMOS_CONN_TRIGGER": "AccountEndpoint=http://localhost:8081/;AccountKey=C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==;",
    "COSMOS-CONN-WRITE": "AccountEndpoint=http://localhost:8081/;AccountKey=C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==;"
  }
}
EOT
    echo "$SETTINGS_FILE created successfully."
fi

# 2. Setup .env file at project root if it doesn't exist
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        echo "Creating .env from .env.example..."
        cp .env.example .env
        # Replace placeholder endpoints and keys with local emulator equivalents
        # macOS compatibility with fallback to standard Linux sed
        sed -i '' 's|https://your-cosmos-db-account.documents.azure.com:443/|http://localhost:8081/|g' .env 2>/dev/null || sed -i 's|https://your-cosmos-db-account.documents.azure.com:443/|http://localhost:8081/|g' .env
        sed -i '' 's|your_write_key_here|C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==|g' .env 2>/dev/null || sed -i 's|your_write_key_here|C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==|g' .env
        sed -i '' 's|your_read_key_here|C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==|g' .env 2>/dev/null || sed -i 's|your_read_key_here|C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==|g' .env
        echo ".env file created and configured for local emulator."
    else
        echo "WARNING: .env.example not found. Please manually configure your .env file."
    fi
fi

# 3. Check and start Azurite Docker Container
if [ "$(docker ps -a -q -f name=azurite)" ]; then
    echo "Azurite container already exists. Starting it..."
    docker start azurite
else
    echo "Creating and starting Azurite container..."
    docker run -d -p 10000:10000 -p 10002:10002 --name azurite mcr.microsoft.com/azure-storage/azurite
fi

# 4. Check and start Cosmos DB Emulator Docker Container
if [ "$(docker ps -a -q -f name=cosmosdb-emulator)" ]; then
    echo "Cosmos DB Emulator container already exists. Starting it..."
    docker start cosmosdb-emulator
else
    echo "Creating and starting Cosmos DB Emulator container (this may take a few seconds)..."
    docker run -d --name=cosmosdb-emulator -p 10251-10251:10251-10251 -p 8081:8081 -m 4g mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator:vnext-preview
fi

# 5. Smart wait for Cosmos DB Emulator to become active
echo -n "Waiting for Cosmos DB Emulator to be ready"
for i in {1..30}; do
    if curl -s -k http://localhost:8081/ > /dev/null; then
        echo " - Connected!"
        break
    fi
    echo -n "."
    sleep 2
done

# 6. Verify virtual environment in backend/
cd backend
if [ ! -d ".venv" ]; then
    echo "Creating Python virtual environment in backend/.venv..."
    python3 -m venv .venv
    source .venv/bin/activate
    echo "Installing backend dependencies from requirements.txt..."
    pip install --upgrade pip
    pip install -r requirements.txt
else
    echo "Backend virtual environment found. Activating..."
    source .venv/bin/activate
fi

# 7. Run database setup and seeding
echo "Running database setup..."
python setup_db.py

echo "Seeding database with default templates and evaluators..."
python seed_data.py

cd ..

echo "========================================================================"
echo "Database environment setup and seeded successfully!"
echo "Keep this terminal open. Press [Ctrl+C] to stop and remove Docker containers."
echo "========================================================================"

# Infinite loop to keep the script active for the Ctrl+C cleanup trap
while true; do
    sleep 1
done

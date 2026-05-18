#!/bin/bash

# ==============================================================================
# Smart Factory — System Services Starter (Backend & Frontend)
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# Store process IDs of started background services
BACKEND_PID=""
FRONTEND_PID=""

# Define cleanup function for graceful termination on Ctrl+C (SIGINT)
cleanup() {
    echo ""
    echo "========================================================================"
    echo "Caught Ctrl+C! Stopping all background services..."
    echo "========================================================================"
    
    if [ -n "$FRONTEND_PID" ]; then
        echo "Stopping Frontend (Process Group: $FRONTEND_PID)..."
        kill -TERM -"$FRONTEND_PID" 2>/dev/null || true
    fi
    
    if [ -n "$BACKEND_PID" ]; then
        echo "Stopping FastAPI Backend (Process Group: $BACKEND_PID)..."
        kill -TERM -"$BACKEND_PID" 2>/dev/null || true
    fi

    # Wait to ensure all processes have fully exited
    wait 2>/dev/null || true
    echo "All processes successfully terminated. Goodbye!"
    exit 0
}

# Register the cleanup trap
trap cleanup INT

echo "========================================================================"
echo "Starting Smart Factory System..."
echo "========================================================================"

# --- 1. PREPARE BACKEND ---
echo "Checking FastAPI Backend environment..."
cd backend
if [ ! -d ".venv" ]; then
    echo "Creating Python virtual environment in backend/.venv..."
    python3 -m venv .venv
    source .venv/bin/activate
    echo "Installing Backend dependencies from requirements.txt..."
    pip install --upgrade pip
    pip install -r requirements.txt
else
    echo "Backend virtual environment found. Activating..."
    source .venv/bin/activate
fi
echo "Starting FastAPI Backend (Uvicorn) in the background..."
set -m
uvicorn main:app --reload &
BACKEND_PID=$!
set +m
cd ..

# --- 2. PREPARE FRONTEND ---
echo "Checking Frontend environment..."
cd frontend
if [ ! -d "node_modules" ]; then
    echo "Node modules not found. Installing frontend dependencies..."
    npm install
fi
echo "Starting Vite Frontend in the background..."
set -m
npm run dev &
FRONTEND_PID=$!
set +m
cd ..

echo "========================================================================"
echo "Smart Factory services are spinning up in the background:"
echo "  - FastAPI Backend (PID: $BACKEND_PID)"
echo "  - Vite Frontend (PID: $FRONTEND_PID)"
echo ""
echo "All logs are being streamed to this terminal."
echo "Press Ctrl+C at any time to cleanly terminate all processes."
echo "========================================================================"

# Keep the script running to stream logs and catch INT signal
wait

# Smart Factory AI - LLMOps & GenAI Observability Platform

## 1. Introduction
The **Smart Factory AI** project is a comprehensive LLMOps (Large Language Model Operations) and GenAI Observability platform designed specifically for industrial and manufacturing environments. As factories adopt AI to process sensor data, automate maintenance, and assist engineers, ensuring the reliability of these AI models is critical. 

This platform allows operators to capture, monitor, evaluate, and perform root-cause analysis (RCA) on AI interactions (traces) in real-time. It provides a centralized dashboard to track costs, latencies, model performance, and evaluate whether the AI is hallucinating or providing factually grounded responses based on factory manuals and documentation.

---

## 2. How to setup locally

1. git clone repo
2. copy the contents of .env.example file into the .env file: `cp .env.example .env`
3. fill in the values in the .env file
4. change directory to frontend folder: `cd frontend/`
5. run these commands under it:
   ```bash
   npm install 
   npm install -g azure-functions-core-tools@4 --unsafe-perm true
   ```
6. next, come back to the project root and create the python virtual environment and activate it:
   `python3 -m venv .venv && source .venv/bin/activate`
7. install the dependencies in it: `pip install -r requirements.txt`

The setup is done. Now you can run the provided bash scripts:
1. `bash run_database.sh`: creates the Comosdb Database and azurite docker containers and sets up the database and the containers
2. `bash start_system.sh`: starts the frontend and the backend.

To start the azure functions, run these commands in the terminal of the project root:
1. `source .venv/bin/activate`
2. `cd azure-functions/` 
3. `func start`

---

## 3. Technologies Used

* **Frontend:** React, Vite, TypeScript, Tailwind CSS
* **Backend:** FastAPI (Python), Uvicorn
* **Background Processing:** Azure Functions (Python)
* **Database:** Azure Cosmos DB (NoSQL)
* **LLM Providers:** Azure OpenAI, Google Gemini
* **Secret Management:** Azure Key Vault (Optional integration)

---

## 4. Architecture & Workflow

The system utilizes a modern, event-driven microservices architecture hosted primarily on Azure. 

1. **Trace Ingestion & Normalisation:** 
   When a user interacts with the Smart Factory AI, the raw interaction (trace) is captured. The **`Normalisation` Azure Function** intercepts this, standardizes the payload into a canonical schema, and saves it to Cosmos DB.
2. **Asynchronous Evaluation (`EvaluatorRunner`):** 
   Triggered by the arrival of a new trace, this Azure Function loads active evaluation templates (e.g., Groundedness, Relevance, Tone). It uses LLMs as judges (or deterministic metrics) to score the trace. It supports LLM ensembles to reduce evaluation variance.
3. **Root Cause Analysis (`RCAEngine`):** 
   Once a trace has been fully evaluated, the RCA Engine reviews the scores. If a trace performed poorly, it analyzes the data (e.g., checking if the retrieved context was insufficient) to generate human-readable findings, evidence, and actionable suggestions.
4. **Data Aggregation (`Aggregator`):** 
   A timer-triggered job periodically crunches all traces and evaluations to compile high-level metrics like total cost, average latency, total tokens per model, and average evaluation scores.
5. **Dashboard Visualization:** 
   The React frontend continuously polls the FastAPI backend to visualize these aggregated metrics, allowing operators to drill down into specific sessions or failed traces.

---

## 5. Real-World Usage & Importance

### Why is this important?
In a "Smart Factory", AI might be asked: *"Why is the turbine pressure dropping?"* 
If the AI hallucinates and gives the wrong diagnosis, it could lead to millions of dollars in damages or severe safety hazards. Traditional software can be tested deterministically, but Generative AI is non-deterministic. This project bridges that gap by providing **continuous, automated quality assurance for AI**.

### Real-World Scenario
1. **The Interaction:** A maintenance engineer queries the internal AI assistant about an anomaly in a robotic arm. The AI searches the factory manuals and generates an answer.
2. **The Observation:** The platform silently captures this trace—including the engineer's prompt, the manual excerpts retrieved by the AI, and the AI's final answer.
3. **The Evaluation:** The `EvaluatorRunner` cross-references the AI's answer strictly against the retrieved manual excerpts. It detects that the AI mentioned a "calibration sequence" that wasn't actually in the manual (a hallucination).
4. **The RCA & Alert:** The platform flags the response with a low "Groundedness" score. The `RCAEngine` notes: *"The AI generated steps not found in the source context."* 
5. **The Resolution:** The AI Operations team sees this failure on the dashboard, updates the system prompt to be more strictly grounded, and prevents future hazardous recommendations.

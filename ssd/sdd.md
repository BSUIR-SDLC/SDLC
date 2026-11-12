# Software Design Description (SDD)
## Project: IoT Device Emulator (Variant 8)

### 1. System Requirements
The emulator must operate as an autonomous background service continuously generating telemetry while hosting an HTTP server listening on `/command` for real-time control directives.

### 2. Functional Requirements & Priorities
| ID | Feature Description | Priority |
|---|---|---|
| FR-1 | **Telemetry Generation:** Periodically generate JSON packets (device_id, timestamp, temperature, motion) every N seconds. | 10 (Highest) |
| FR-2 | **HTTP Command Listener:** Expose `POST /command` endpoint to accept remote JSON directives. | 10 (Highest) |
| FR-3 | **Dynamic Interval Update:** Modify transmission frequency (N) on-the-fly without system restarts. | 20 |
| FR-4 | **State Mutation:** Adjust simulated sensor values (temperature offset, alert mode) dynamically. | 20 |
| FR-5 | **CLI Parameterization:** Provide launch arguments for host, port, initial interval, and device ID. | 40 |
| FR-6 | **Execution Logging:** Structured console logging for outbound packets and inbound commands. | 50 (Lowest) |

### 3. Non-Functional Requirements
| ID | Feature Description | Priority |
|---|---|---|
| NFR-1 | **Latency:** Endpoint `/command` latency must remain under 100ms. | 30 |
| NFR-2 | **Stability:** Service must run uninterrupted for at least 24 hours without resource leaks. | 20 |
| NFR-3 | **Portability:** Cross-platform execution (Windows/Linux) targeting Python 3.10+ / Node.js. | 30 |
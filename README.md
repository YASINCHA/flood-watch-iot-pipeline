# 🌊 FLOOD·WATCH — IoT Real-Time Flood Monitoring System

[![Hardware](https://img.shields.io/badge/Hardware-ESP32%20%7C%20FreeRTOS-blue.svg)]()
[![Backend](https://img.shields.io/badge/Backend-Node.js%20%7C%20Express%20%7C%20JSON--FS-orange.svg)]()
[![Frontend](https://img.shields.io/badge/Mobile-Flutter%20%7C%20Dart-cyan.svg)]()
[![Alerting](https://img.shields.io/badge/Alerts-SIM800L%20GSM%20%2F%20SMS-red.svg)]()

FLOOD·WATCH is an end-to-end, high-reliability Internet of Things (IoT) solution designed for real-time environmental telemetry, early flood detection, and automated disaster mitigation. The system features a deterministic edge layer processing hardware metrics at a 3mm precision threshold, a lightweight file-persisted ingestion backend, and a reactive mobile dashboard mapping real-time civic safety data.

---

## 🎯 Key Architectural & Engineering Highlights

* **Multi-Threaded Hardware Concurrency:** Built on an **ESP32 dual-core architecture** leveraging **FreeRTOS task scheduling**. Telemetry acquisition, edge-filtering, and network execution are decoupled into non-blocking, prioritized tasks to eliminate main-loop latency.
* **Precision Telemetry Engineering:** Integrates ultrasonic sensor arrays optimized to achieve **$\pm$3mm distance calculation accuracy**, filtering out raw physical sensor noise directly at the edge layer before data transmission.
* **Fail-Safe Cellular Fallback System:** Engineered with an autonomous **SIM800L GSM module** integration. In the event of localized Wi-Fi disconnection or cloud platform outages during a disaster event, the device directly bypasses the IP infrastructure to broadcast critical alert SMS notifications to safety coordinators.
* **Lightweight JSON Storage Pipeline:** Implements a fast, low-overhead memory store utilizing runtime state variables and non-blocking **JSON file-system serialization** (`fs` module). Telemetry data arrays are parsed, managed in-memory, and persisted to structured local flat-files—eliminating heavy database overhead for efficient edge computing environments.
* **Full-Stack Reactive Communication:** Features a high-throughput **Node.js & Express** backend engine feeding live analytical updates directly to a cross-platform **Flutter mobile app** styled with dynamic animated gauges and synchronized data via the `OpenWeatherMap API`.
* **Secure Network Ingress:** Implements secure local-to-cloud perimeter network traversal utilizing an optimized network tunnel (`Ngrok`) to safely bridge edge nodes with local backend ingestion servers.

---

---

## 🧱 Core Tech Stack

### 📡 Edge Layer (Hardware)
* **Microcontroller:** ESP32 (Dual-core, 240MHz)
* **Real-Time Operating System:** FreeRTOS (Deterministic task preemption)
* **Sensors:** Calibrated Ultrasonic Distance Transducers
* **Telecommunications:** SIM800L GSM/GPRS hardware module

### ⚙️ Cloud & Ingestion Layer (Backend)
* **Runtime:** Node.js
* **Framework:** Express.js (RESTful API streaming & routing)
* **Storage Engine:** In-memory volatile architecture paired with persistent **JSON File System Storage** (`fs` module)
* **Network Traversal:** Ngrok tunneling protocols

### 📱 Presentation Layer (User Interface)
* **Framework:** Flutter (Reactive Canvas)
* **Language:** Dart
* **Integrations:** OpenWeatherMap API for synchronized real-time atmospheric tracking

---

## 🚀 Local Deployment & Verification

### 1. Hardware Initialization
1. Open the core firmware directory in the Arduino IDE or PlatformIO.
2. Verify pinout mappings for the Ultrasonic transceiver (Trigger/Echo) and the SIM800L hardware serial (TX/RX) lanes.
3. Flash the binary to the target ESP32 board.

### 2. Backend Environment Setup
Ensure your local system storage paths are ready, then initiate the node server:
```bash
cd backend
npm install
npm start

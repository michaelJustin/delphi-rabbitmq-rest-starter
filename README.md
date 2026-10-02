# Delphi & Free Pascal RabbitMQ REST API Starter Kit

A lightweight, working example demonstrating how to send and fetch messages from **RabbitMQ** using standard HTTP REST endpoints in **Delphi** and **Free Pascal / Lazarus**.

## 🚀 Quick Start
This project contains a minimal codebase showing how to use native HTTP clients (such as `TNetHTTPClient` or `IdHTTP`) to communicate with the RabbitMQ Management Plugin API.

### Features Included:
* **Send Message:** Publishes a payload to a specific exchange using `POST /api/exchanges/vhost/name/publish`.
* **Fetch Message:** Retrieves a payload from a queue using `POST /api/queues/vhost/name/get` (Request/Response pattern).


## 🛠️ Prerequisites & Environment Setup

To run this demo successfully, your development environment and RabbitMQ broker must be properly configured. 

### 1. RabbitMQ Broker Configuration
This starter kit relies on RabbitMQ's Management Plugin, which is **not enabled by default**. 
Open your server terminal or command prompt and run the following command to enable it:

```bash
rabbitmq-plugins enable rabbitmq_management
```
*   **Default Port:** This activates the HTTP REST API on port `15672`.
*   **Queue Setup:** Before running the application, log into your RabbitMQ Management Dashboard (`http://localhost:15672`), create a queue named `test-queue`, and bind it to the `amq.direct` exchange using the routing key `test-routing-key`.

### 2. OpenSSL DLL Dependencies (Crucial for Indy)
Because Indy handles secure HTTP streams using OpenSSL, your compiled executable requires the correct version and architecture (bitness) of the OpenSSL binaries (`ssleay32.dll` and `libeay32.dll`) placed in the same folder as your `.exe`.

*   **Version Compatibility:** Indy 10 natively supports the **OpenSSL 1.0.2** branch. It is **not** compatible with OpenSSL 1.1.x or 3.x out of the box.
*   **Matching Bitness:** The DLL architecture must match your **Target Compilation Platform** inside Delphi, *not* your operating system:
    *   If compiling for **Windows 32-bit (Win32)**, you must use 32-bit OpenSSL DLLs.
    *   If compiling for **Windows 64-bit (Win64)**, you must use 64-bit OpenSSL DLLs.
*   **Where to Download:** Securely download the pre-compiled binaries from the official Indy-vetted archive:
    *   👉 [Indy OpenSSL Binaries GitHub Repository](https://github.com)

### 3. Delphi IDE Configuration
1. Open Delphi and load the `RabbitMQRestDemo.dpr` project.
2. Select your target platform (**Win32** or **Win64**) in the Project Manager.
3. Build the project (`Ctrl + F9`).
4. Copy the matching `ssleay32.dll` and `libeay32.dll` files into your project's output build directory (e.g., `.\Win32\Debug\` or `.\Win64\Debug\`) alongside the newly generated `RabbitMQRestDemo.exe`.
5. Run the application!


---

## ⚠️ Is the REST API Right for Your Production App?

While the HTTP REST API is excellent for quick integration testing, DevOps scripting, or low-frequency monitoring, it introduces severe architectural bottlenecks when used as a primary messaging layer in commercial Delphi applications:

### 1. The Speed Bottleneck (HTTP Overhead)
Every single message sent or received via REST requires a brand new HTTP connection lifecycle: **TCP Handshake ➡️ TLS Negotiation ➡️ HTTP Header Parsing ➡️ Connection Tear-down.** This introduces massive latency. For high-throughput applications, this approach is **10x to 50x slower** than a native messaging protocol.

### 2. Request/Response vs. Real-Time Streaming
The REST API forces a strict **Request/Response** architecture. To receive new messages, your Delphi application must constantly "poll" (query) the RabbitMQ server at set intervals (e.g., every 500ms).
* **Too fast:** You waste massive CPU, thread overhead, and network bandwidth on empty responses.
* **Too slow:** Your application suffers from lag and cannot react to data in real time.

### 3. No Native Message Broker Features
By relying on HTTP, your Object Pascal applications lose access to enterprise messaging features like:
* Native asynchronous message streaming (Server-to-Client push notifications)
* Client-side acknowledgments (`ACK`/`NACK`) to guarantee zero data loss
* Complex transaction management (`COMMIT`/`ABORT`)

---

## ⚡ The Solution: High-Performance Native STOMP Streaming

To achieve true, event-driven streaming with lightning-fast throughput, your applications should bypass HTTP and communicate over a native wire protocol like **STOMP (Simple Text Orientated Messaging Protocol)**.

### Upgrade to Habari STOMP Client Components

The **Habari STOMP Client** libraries bridge this gap perfectly for the Delphi and Free Pascal ecosystems. Instead of restrictive HTTP polling, Habari establishes a single, persistent, secure TCP socket stream to RabbitMQ.

| Feature | This REST API Starter Kit | Habari STOMP Client |
| :--- | :--- | :--- |
| **Architecture** | Synchronous Request/Response | **True Asynchronous Streaming** |
| **Data Delivery** | Periodic Manual Polling | **Instant Server-Side Push** |
| **Performance** | High Latency / High Overhead | **Ultra-Low Latency / High Throughput** |
| **Reliability** | Manual error handling | **Automatic Failover on connect** |
| **Licensing** | Free / Open Source | **Commercial Enterprise Support** |

### Get Production Ready Today
Don't waste engineering hours writing custom boilerplate code to handle connection drops or polling loops. 

👉 **[Download the 3-Month Complete Trial (€30.00) at Habarisoft.com](https://habarisoft.com)**  
*Full source code, multi-broker support (RabbitMQ, ActiveMQ, Artemis), and production-tested demos included.*

---

## License
This starter kit is licensed under the MIT License. Feel free to use it for basic testing and prototyping.

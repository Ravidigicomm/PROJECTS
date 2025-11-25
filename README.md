A key clarification for SOC context:
*   **Full Duplex** typically means a client can be both a Master (initiating write requests) and a Slave (responding to configuration reads/writes) on the same interface, which is true for most of these components.
*   **Half Duplex** is more common for simple peripherals that are only Slaves (like UART, I2C, etc.) or for protocol-specific interfaces like I2S. However, in a bus-based system like AHB/APB, even simple slaves are technically "half duplex" in the sense that the data bus itself is not simultaneously transmitting and receiving. For clarity, I have interpreted it as the client's capability.

Here is the table:

| S.No. | Client Name              | Operating Frequency                      | Type of Communication | Behavior              |
| :---- | :----------------------- | :--------------------------------------- | :-------------------- | :-------------------- |
| **AXI Clients**                                                                                                                              |
| 1     | CPU                      | 1.0 - 3.0 GHz                            | Full Duplex           | Master                |
| 2     | GPU                      | 500 MHz - 1.5 GHz                        | Full Duplex           | Master                |
| 3     | DDR4 Controller          | 1600 MHz (DRAM Clock)                    | Full Duplex           | Slave                 |
| 4     | L3 Cache                 | 0.5 - 2.0 GHz                            | Full Duplex           | Slave                 |
| 5     | PCIe                     | 250 MHz - 1 GHz (Core)                   | Full Duplex           | Slave                 |
| 6     | NPU                      | 800 MHz - 1.2 GHz                        | Full Duplex           | Slave                 |
| **AHB Clients**                                                                                                                             |
| 7     | System DMA               | 200 - 400 MHz                            | Full Duplex           | Master                |
| 8     | Ethernet Controller      | 50 - 250 MHz (Core) / 100-200 MHz (IF)   | Full Duplex           | Master    |
| 9     | NAND Flash Controller    | 50 - 200 MHz                             | Half Duplex           | Slave                 |
| 10    | SRAM Controller          | 100 - 200 MHz                            | Full Duplex           | Slave                 |
| 11    | Camera Controller        | 100 - 200 MHz                            | Half Duplex           | Slave                 |
| 12    | Network (Ethernet) Ctrl | 100 - 200 MHz                            | Half Duplex           | Slave                 |
| **APB Clients**                                                                                                                             |
| 13    | Power Management         | 50 - 100 MHz                             | Full Duplex           | Master                |
| 14    | Test Control             | 10 - 100 MHz                             | Full Duplex           | Master                |
| 15    | UART                     | 50 - 100 MHz                             | Half Duplex           | Slave                 |
| 16    | PWM                      | 50 - 100 MHz                             | Half Duplex           | Slave                 |
| 17    | SPI                      | 50 - 100 MHz                             | Half Duplex           | Slave                 |
| 18    | I2S                      | 50 - 100 MHz                             | Half Duplex           | Slave                 |
| 19    | WDT (Watchdog Timer)     | 50 - 100 MHz                             | Half Duplex           | Slave                 |
| 20    | I2C                      | 50 - 100 MHz                             | Half Duplex           | Slave                 |
| 21    | GPIO                     | 50 - 100 MHz                             | Half Duplex           | Slave                 |
| 22    | RTC                      | 32.768 kHz / 50 MHz (APB)                | Half Duplex           | Slave                 |

### **Important Notes:**

1.  **Full vs. Half Duplex:** The classification here is based on the functional role of the IP on the bus.
    *   **Full Duplex** clients are those that actively initiate transactions (Master behavior) or are complex slaves that require high-bandwidth read/write capabilities (like memory controllers).
    *   **Half Duplex** clients are simple slaves that are primarily configured and read from, with data flow being largely unidirectional at the system bus level for their core function.
2.  **Clock Domains:** You have numerous clock domains. A robust Clock Domain Crossing (CDC) strategy is critical for the bridges and interconnect between these different frequency regions (e.g., between the high-speed AXI domain and the lower-speed AHB domain).



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

### **Proposed SOC Architecture with FlooNOC**

**Central Interconnect:** **FlooNOC** (AXI-based Network-on-Chip)

#### **MASTER SIDE (AXI Initiator Ports on FlooNOC)**

*   **Port M0:** Dedicated to **CPU (AXI-M1)**
*   **Port M1:** Dedicated to **GPU (AXI-M2)**
*   **Port M2:** Shared by **AHB Masters** via an **AHB-to-AXI Bridge**.
    *   Connected Masters: `System DMA (AHB-M1)`, `Ethernet (AHB-M2)`
*   **Port M3:** Shared by **APB Masters** via an **APB-to-AXI Bridge**.
    *   Connected Masters: `Power Mgmt (APB-M1)`, `Test Ctrl (APB-M2)`

#### **SLAVE SIDE (AXI Target Ports on FlooNOC)**

*   **Port S0:** Dedicated to **DDR4 Controller (AXI-S1)**
*   **Port S1:** Dedicated to **L3 Cache (AXI-S2)**
*   **Port S2:** Dedicated to **PCIe (AXI-S3)**
*   **Port S3:** Dedicated to **NPU (AXI-S4)**
*   **Port S4:** Shared by **AHB Slaves** via an **AXI-to-AHB Bridge**.
    *   Connected Slaves: `NAND Flash Ctrl (AHB-S1)`, `SRAM Ctrl (AHB-S2)`, `Camera Ctrl (AHB-S3)`, `Network Ctrl (AHB-S4)`
*   **Port S5:** Shared by **APB Slaves** via an **AXI-to-APB Bridge**.
    *   Connected Slaves: All 8 APB Peripherals (`UART`, `PWM`, `SPI`, `I2S`, `WDT`, `I2C`, `GPIO`, `RTC`)

---

### **Architecture Diagram (Text-Based)**

```
+----------------------------------------------------------------------------------------------------+
|                                                SOC                                                 |
|                                                                                                    |
|  +-------------+      +-------------+      +-----------------+      +-----------------+            |
|  |    CPU      |      |     GPU     |      |  AHB-to-AXI     |      |  APB-to-AXI     |            |
|  |  (AXI-M1)   |      |  (AXI-M2)   |      |     Bridge      |      |     Bridge      |            |
|  +-------------+      +-------------+      +-----------------+      +-----------------+            |
|        |                    |                    |                            |                    |
|    [AXI Port]           [AXI Port]          [AXI Port]                   [AXI Port]                |
|        |                    |                    |                            |                    |
|        +--------------------+--------------------+----------------------------+                    |
|                                     |                                                                
|                            +================+                                                       |
|                            |   FLOO NOC     |                                                       |
|                            |  (AXI Fabric)  |                                                       |
|                            +================+                                                       |
|         |                    |                    |                            |                    |
|    [AXI Port]           [AXI Port]          [AXI Port]                   [AXI Port]                |
|         |                    |                    |                            |                    |
|  +-------------+      +-------------+      +-----------------+      +-----------------+            |
|  |    DDR4     |      |   L3 Cache  |      |  AXI-to-AHB     |      |  AXI-to-APB     |            |
|  | Controller  |      |   (AXI-S2)  |      |     Bridge      |      |     Bridge      |            |
|  |  (AXI-S1)   |      |             |      +-----------------+      +-----------------+            |
|  +-------------+      +-------------+              |                            |                    |
|                                                    |                            |                    |
|                                          +-------------------+       +----------------------+      |
|                                          |                   |       |                      |      |
|                                    +----------+         +----------+  |  +----+ +----+ +----+ ...  |
|                                    | NAND Ctrl|         | SRAM Ctrl|  |  |UART| | SPI| | I2C| (x8) |
|                                    | (AHB-S1) |         | (AHB-S2) |  |  +----+ +----+ +----+      |
|                                    +----------+         +----------+  |                      |      |
|                                    | Camera   |         | Ethernet|  |    All APB Slaves    |      |
|                                    | Ctrl(S3) |         | Ctrl(S4)|  |      (S1-S8)         |      |
|                                    +----------+         +----------+  +----------------------+      |
|                                          |                   |                                      |
|                                          +-------------------+                                      |
|                                                                                                    |
+----------------------------------------------------------------------------------------------------+
```

### **Key Advantages of This Architecture:**

1.  **FlooNOC Native Compatibility:** All connections to the FlooNOC are pure AXI, as required.
2.  **Performance Isolation:** High-performance AXI masters (CPU, GPU) and slaves (DDR, L3, PCIe, NPU) get dedicated ports, minimizing contention.
3.  **Area Efficiency:** Lower-performance AHB and APB buses share single AXI ports via bridges, saving costly NoC ports.
4.  **Logical Grouping:** The AHB domain (DMA, Ethernet, peripherals) is grouped together, and the APB control domain is grouped together, making the address map and system control more straightforward.
5.  **Scalability:** This structure is clean and scalable. If you need to add another AXI master or slave, you can add a new port to the FlooNOC. If you need more AHB peripherals, you simply connect them to the existing AXI-to-AHB bridge.

This architecture effectively uses FlooNOC as the high-performance backbone while cleanly integrating the legacy AHB and APB protocols through standardized bridges.

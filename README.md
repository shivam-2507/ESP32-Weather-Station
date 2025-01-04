# ESP32 Wi-Fi Weather Station 🌦️

A weather station project that measures temperature, humidity, and heat index using an **ESP32** and **DHT11 sensor**. The data is displayed on an **I2C LCD** and served over Wi-Fi through a **JSON API**. The iOS app fetches and displays the data, with an added fan control feature based on the temperature.

---

## Features
### ESP32
- Measures **temperature**, **humidity**, and **heat index** using **DHT11 sensor**.
- Displays Wi-Fi status on **16x2 I2C LCD**.
- Serves data via a RESTful **JSON API**.
- Controls a fan motor through GPIO pins to adjust fan speed based on temperature.
  - **Manual mode** allows users to adjust fan speed via a slider.
  - **Auto mode** automatically adjusts the fan speed based on temperature readings.

### iOS App (SwiftUI)
- Fetches data from the ESP32 over Wi-Fi.
- Displays data with dynamic backgrounds based on temperature/heat index.
- Shows error messages with alerts for any issues (like failed data fetch).
- Provides **manual control** for adjusting fan speed using a slider.
- Provides **auto mode** to adjust fan speed automatically based on temperature thresholds.

---

## Getting Started

### Clone this Repository

1. Clone the repository to your local machine using Git:

   ```bash
   git clone https://github.com/yourusername/esp32-weather-station.git
   ```

### ESP32 Setup
1. **PlatformIO** and **Visual Studio Code** is used for ESP32 development. 
2. The ESP32 code is located in the `src/main.cpp` file.
3. To connect the ESP32 to Wi-Fi, open `src/main.cpp` and enter your **Wi-Fi SSID** and **password** in the designated fields:

   ```cpp
   const char* ssid = "your_wifi_ssid";  // Enter your Wi-Fi SSID here
   const char* password = "your_wifi_password";  // Enter your Wi-Fi password here
   	```
4. To get the ESP32’s IP address, run the Wi-Fi Test file located in the src folder. This will print the IP address to the serial monitor. Paste this IP address into the iOS app to establish the connection
5. Get the LCD memory address by running `src/screenMemoryAddress.cpp` and reading the serial monitor

   ```cpp
	int lcdColumns = 16;
	int lcdRows = 2;
	LiquidCrystal_I2C lcd(0x3F, lcdColumns, lcdRows);
	```
6. Replacing the 0x3F with the correct memory address will allow the LCD Screen to work.
7. Motor control pins are configured in the ESP32 code to adjust the fan speed based on temperature readings.

### iOS App Setup
1. Xcode is used for the iOS app development.
2. The app code is located in ESP32 Temp App/ContentView.swift.
3. In ContentView.swift, replace the placeholder <ESP32_IP> in the fetchData() function with the IP address of your ESP32 from the previous step:

	```swift
	guard let url = URL(string: "http://<ESP32_IP>/data") else {
 	     showErrorMessage("Invalid URL")
 	     return
	}
	```
   
4. This will enable the iOS app to fetch and display the data from the ESP32.
5. The app can also be downloaded to any iOS device by following the instruction in the Xcode IDE.

---

### Hardware Requirements
- ESP32 Development Board
- DHT11 Temperature & Humidity Sensor
- 16x2 I2C LCD
- DC Motor (for fan control)
- Motor Driver (e.g., L298N) to control the fan
- Breadboard and jumper wires

| **Component**        | **Pin**          | **GPIO Pin**    |
|----------------------|------------------|-----------------|
| LCD SDA              | GPIO 21          | 21              |
| LCD SCL              | GPIO 22          | 22              |
| DHT 2 (Sensor)       | GPIO 4           | 4               |
| Motor Enable 1       | GPIO 14          | 14              |
| Motor IN1            | GPIO 27          | 27              |
| Motor IN2            | GPIO 26          | 26              |

### Software Requirements
- PlatformIO for ESP32 development
- Xcode for iOS app development
- Libraries:
- DHT (for the DHT11 sensor)
- LiquidCrystal_I2C (for the LCD)
- ESPAsyncWebServer (for the RESTful API)

### Motor Control (Fan)

The fan is controlled using GPIO pins and can operate in two modes:

#### 1. Manual Mode
In manual mode, the user can adjust the fan speed using a slider in the iOS app. The user can select a speed between 0 (off) and 1 (full speed).
- The app sends the desired fan speed value to the ESP32 using the `sendFanSpeed()` function.
- The motor speed is controlled using PWM, and the fan speed is updated accordingly.

#### 2. Auto Mode
In auto mode, the fan speed is automatically adjusted based on the temperature readings from the DHT11 sensor. The temperature is categorized into different ranges, and the fan speed is set accordingly:
- **0°C - 10°C**: Fan Off (Speed 0%)
- **10°C - 20°C**: Fan Slow (Speed 25%)
- **20°C - 22°C**: Fan Medium (Speed 50%)
- **22°C - 23°C**: Fan Fast (Speed 75%)
- **Above 23°C**: Fan Full Speed (100%)

The app can toggle auto mode on and off using a button. When enabled, the fan speed is adjusted in real-time based on the current temperature, fetched every 5 seconds.


---
### Troubleshooting
- Ensure that the Wi-Fi credentials are correct in both the ESP32 code and the iOS app.
- Check the ESP32 serial monitor for any connection issues or errors.
- If the app fails to fetch data, verify that the ESP32 is correctly serving data on the provided IP address.
- If the motor doesn’t respond, check that the motor driver is connected properly and that the motor pins are correctly configured in the ESP32 code.
- If the fan is not responding in auto mode, make sure the temperature readings from the DHT11 sensor are correct and that the auto mode feature is enabled.

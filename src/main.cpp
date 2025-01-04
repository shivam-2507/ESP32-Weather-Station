// libraries and dependencies
#include <Arduino.h>
#include "DHT.h"
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <WiFi.h>
#include <ESPAsyncWebServer.h>
#include <ArduinoJson.h>

// initialize DHT sensor
#define DHTPIN 4
#define DHTTYPE DHT11

DHT dht(DHTPIN, DHTTYPE);

// initialize LCD
int lcdColumns = 16;
int lcdRows = 2;
LiquidCrystal_I2C lcd(0x3F, lcdColumns, lcdRows);

// initialize Wi-Fi
const char *ssid = "";
const char *password = "";

// initialize motor
int motor1Pin1 = 27;
int motor1Pin2 = 26;
int enable1Pin = 14;
float fanSpeed = 0.5;
int motorSpeed = fanSpeed * 255;

const int freq = 30000;
const int pwmChannel = 0;
const int resolution = 8;

int dutyCycle = 200;

// initialize web server
AsyncWebServer server(80);
TaskHandle_t wifiTaskHandle = NULL;
TaskHandle_t sensorTaskHandle = NULL;
TaskHandle_t lcdTaskHandle = NULL;
TaskHandle_t motorTaskHandle = NULL;

// create data structure to hold sensor data
struct SensorData
{
  float humidity;
  float temperatureC;
  float heatIndexC;
};

SensorData sensorData;

// wifi task
void wifiTask(void *parameter)
{
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED)
  {
    delay(1000);
    Serial.println("Connecting to Wi-Fi...");
  }

  Serial.println("Connected to Wi-Fi");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

  server.on("/data", HTTP_GET, [](AsyncWebServerRequest *request)
            {
    String jsonResponse;
    DynamicJsonDocument doc(256);
    doc["humidity"] = sensorData.humidity;
    doc["temperatureC"] = sensorData.temperatureC;
    doc["heatIndexC"] = sensorData.heatIndexC;
    serializeJson(doc, jsonResponse);
    request->send(200, "application/json", jsonResponse); });

  server.on("/set_speed", HTTP_POST, [](AsyncWebServerRequest *request) {}, NULL, [](AsyncWebServerRequest *request, uint8_t *data, size_t len, size_t index, size_t total)
            {
      String body = String((char *)data).substring(0, len);
      DynamicJsonDocument doc(256);
      DeserializationError error = deserializeJson(doc, body);

      if (error) {
        Serial.print("JSON parse error: ");
        Serial.println(error.c_str());
        request->send(400, "application/json", "{\"status\": \"error\", \"message\": \"Invalid JSON\"}");
        return;
      }

      if (doc.containsKey("fanSpeed")) {
        float parsedSpeed = doc["fanSpeed"];
        if (parsedSpeed >= 0.0 && parsedSpeed <= 1.0) {
          fanSpeed = parsedSpeed;
          motorSpeed = fanSpeed * 255;
          Serial.print("Fan Speed set to: ");
          Serial.println(fanSpeed);
          request->send(200, "application/json", "{\"status\": \"success\"}");
        } else {
          Serial.println("Invalid fanSpeed value. It must be between 0.0 and 1.0.");
          request->send(400, "application/json", "{\"status\": \"error\", \"message\": \"Invalid fanSpeed value\"}");
        }
      } else {
        request->send(400, "application/json", "{\"status\": \"error\", \"message\": \"Missing fanSpeed key\"}");
      } });

  server.begin();
  vTaskDelete(NULL);
}

// sensor task
void sensorTask(void *parameter)
{
  while (true)
  {
    sensorData.humidity = dht.readHumidity();
    sensorData.temperatureC = dht.readTemperature();

    if (isnan(sensorData.humidity) || isnan(sensorData.temperatureC))
    {
      sensorData.humidity = -1;
      sensorData.temperatureC = -1;
    }
    else
    {
      sensorData.heatIndexC = dht.computeHeatIndex(sensorData.temperatureC, sensorData.humidity, false);
    }

    vTaskDelay(5000 / portTICK_PERIOD_MS);
  }
}

// lcd task
void lcdTask(void *parameter)
{
  while (true)
  {
    lcd.setCursor(0, 0);

    if (WiFi.status() != WL_CONNECTED)
    {
      lcd.print("Wi-Fi Disconnected");
      lcd.setCursor(0, 1);
      lcd.print("Reconnecting...");
    }
    else
    {
      lcd.clear();
      lcd.print("Wi-Fi Connected");
      lcd.setCursor(0, 1);
      lcd.print(WiFi.localIP().toString());
    }

    vTaskDelay(5000 / portTICK_PERIOD_MS);
  }
}

// motor task
void motorTask(void *parameter)
{
  while (true)
  {
    Serial.print("Motor Speed: ");
    Serial.println(motorSpeed);

    if (motorSpeed > 0)
    {
      digitalWrite(motor1Pin1, LOW);
      digitalWrite(motor1Pin2, HIGH);
    }
    else
    {
      digitalWrite(motor1Pin1, LOW);
      digitalWrite(motor1Pin2, LOW);
    }

    ledcWrite(pwmChannel, motorSpeed);
    vTaskDelay(1000 / portTICK_PERIOD_MS);
  }
}

// initialize esp32
void setup()
{
  Serial.begin(115200);
  Serial.println(F("DHTxx test!"));

  pinMode(motor1Pin1, OUTPUT);
  pinMode(motor1Pin2, OUTPUT);

  ledcSetup(pwmChannel, freq, resolution);
  ledcAttachPin(enable1Pin, pwmChannel);

  dht.begin();
  lcd.init();
  lcd.backlight();

  xTaskCreate(wifiTask, "WiFi Task", 4096, NULL, 1, &wifiTaskHandle);
  xTaskCreate(sensorTask, "Sensor Task", 4096, NULL, 1, &sensorTaskHandle);
  xTaskCreate(lcdTask, "LCD Task", 4096, NULL, 1, &lcdTaskHandle);
  xTaskCreate(motorTask, "Motor Task", 4096, NULL, 1, &motorTaskHandle);
}

// tasks do all the loops
void loop()
{
}
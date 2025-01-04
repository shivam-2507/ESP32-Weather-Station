/*#include <Arduino.h>

// Motor A
int motor1Pin1 = 27;
int motor1Pin2 = 26;
int enable1Pin = 14;

// PWM properties
const int freq = 30000;
const int pwmChannel = 0;
const int resolution = 8;
int dutyCycle = 200;

void setup()
{
    pinMode(motor1Pin1, OUTPUT);
    pinMode(motor1Pin2, OUTPUT);

    // Setup PWM
    ledcSetup(pwmChannel, freq, resolution);
    ledcAttachPin(enable1Pin, pwmChannel);

    Serial.begin(115200);
    Serial.println("Testing DC Motor...");
}

void moveMotor(int pin1State, int pin2State, int speed)
{
    digitalWrite(motor1Pin1, pin1State);
    digitalWrite(motor1Pin2, pin2State);
    ledcWrite(pwmChannel, speed);
}

void stopMotor()
{
    moveMotor(LOW, LOW, 0);
}

void loop()
{
    // Forward
    Serial.println("Moving Forward");
    moveMotor(LOW, HIGH, 255);
    delay(2000);

    // Stop
    Serial.println("Motor stopped");
    stopMotor();
    delay(1000);

    // Backward
    Serial.println("Moving Backwards");
    moveMotor(HIGH, LOW, 255);
    delay(2000);

    // Stop
    Serial.println("Motor stopped");
    stopMotor();
    delay(1000);

    // Forward with increasing speed
    Serial.println("Increasing Speed Forward");
    moveMotor(LOW, HIGH, 0);
    for (dutyCycle = 200; dutyCycle <= 255; dutyCycle += 5)
    {
        ledcWrite(pwmChannel, dutyCycle);
        Serial.print("Forward with duty cycle: ");
        Serial.println(dutyCycle);
        delay(500);
    }
}*/
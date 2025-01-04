//
//  SensorAttributes.swift
//  ESP32 Temp App
//
//  Created by Shivam Walia on 2024-12-28.
//

import ActivityKit

// Define the attributes for the Live Activity
struct SensorAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // This will hold the temperature to be displayed in the Live Activity
        var temperature: Float
    }

    // Static attributes for the Live Activity
    var name: String
}

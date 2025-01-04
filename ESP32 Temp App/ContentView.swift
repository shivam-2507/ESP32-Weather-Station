import SwiftUI
import Foundation

struct SensorData: Codable {
    var humidity: Float
    var temperatureC: Float
    var heatIndexC: Float
}

struct ContentView: View {
    @State private var sensorData: SensorData?
    @State private var errorMessage: String?
    @State private var showAlert: Bool = false
    @State private var currentTab: Int = 0
    @State private var showFanSlider: Bool = false
    @State private var fanSpeed: Double = 0.5
    @State private var fanRotation: Double = 0.0
    @State private var isAutoMode: Bool = false
    @State private var previousTemperature: Float = 0.0
    @State private var debounceTimer: Timer?

    @Environment(\.colorScheme) var colorScheme

    func fetchData() {
        guard let url = URL(string: "http://<ESP32 Address>/data") else {
            showErrorMessage("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                showErrorMessage("Failed to fetch data: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                showErrorMessage("No data received")
                return
            }

            let decoder = JSONDecoder()
            do {
                let decodedData = try decoder.decode(SensorData.self, from: data)
                DispatchQueue.main.async {
                    withAnimation(.easeInOut) {
                        sensorData = decodedData
                    }
                    errorMessage = nil
                    if isAutoMode, let temp = sensorData?.temperatureC {
                        adjustFanSpeedIfNeeded(temp)
                    }
                }
            } catch {
                showErrorMessage("Failed to decode JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    func sendFanSpeed(_ speed: Double) {
        print("Sending fan speed: \(speed)")

        guard let url = URL(string: "http://<ESP32 Address>/set_speed") else {
            showErrorMessage("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let speedData: [String: Double] = ["fanSpeed": speed]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: speedData, options: []) else {
            showErrorMessage("Failed to encode JSON")
            return
        }

        request.httpBody = httpBody

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                showErrorMessage("Failed to send speed: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                showErrorMessage("Server error: \(httpResponse.statusCode)")
            }
        }.resume()
    }

    func showErrorMessage(_ message: String) {
        DispatchQueue.main.async {
            errorMessage = message
            showAlert = true
        }
    }

    func adjustFanSpeedIfNeeded(_ temperature: Float) {
        //debouncing
        guard abs(temperature - previousTemperature) >= 0.05 else { return }

        previousTemperature = temperature

        if temperature >= 0 && temperature < 10 {
            fanSpeed = 0.0
        } else if temperature >= 19 && temperature < 20 {
            fanSpeed = 0.25
        } else if temperature >= 20 && temperature < 21 {
            fanSpeed = 0.5
        } else if temperature >= 21 && temperature < 22 {
            fanSpeed = 0.75
        } else if temperature >= 23 {
            fanSpeed = 1.0
        }
        sendFanSpeed(fanSpeed)
    }

    func startContinuousPolling() {
        debounceTimer?.invalidate() // Invalidate any existing timer

        debounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let temp = sensorData?.temperatureC, isAutoMode {
                adjustFanSpeedIfNeeded(temp)
            }
        }
    }

    var body: some View {
        ZStack {
            if currentTab == 0 {
                Color.blue.edgesIgnoringSafeArea(.all)
            } else if currentTab == 1 {
                getBackgroundColor(for: sensorData?.temperatureC ?? 0)
                    .edgesIgnoringSafeArea(.all)
            } else {
                getBackgroundColor(for: sensorData?.heatIndexC ?? 0)
                    .edgesIgnoringSafeArea(.all)
            }

            VStack {
                HStack {
                    Button(action: {
                        if !isAutoMode {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                showFanSlider.toggle()
                            }
                            if showFanSlider {
                                withAnimation(.linear(duration: 0.5)) {
                                    fanRotation += 360
                                }
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "fanblades")
                                .font(.system(size: 24))
                                .rotationEffect(.degrees(fanRotation))
                                .animation(.linear(duration: 0.5), value: fanRotation)

                            if showFanSlider && !isAutoMode {
                                Slider(value: $fanSpeed, in: 0...1, step: 0.01, onEditingChanged: { _ in
                                    sendFanSpeed(fanSpeed)
                                })
                                    .transition(.move(edge: .leading))
                                    .disabled(isAutoMode)
                            }
                        }
                        .padding(10)
                        .background(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .cornerRadius(8)
                        .shadow(radius: 5)
                    }
                    Spacer()
                }
                .padding()

                Spacer()

                TabView(selection: $currentTab) {
                    VStack {
                        if let sensorData = sensorData {
                            Text("Humidity: \(sensorData.humidity, specifier: "%.1f")%")
                                .font(.system(size: 28, weight: .bold))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .cornerRadius(8)
                                .padding(.horizontal)
                        } else {
                            Text("Loading data...")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                        }
                        refreshButton
                    }
                    .tag(0)

                    VStack {
                        if let sensorData = sensorData {
                            Text("Temperature: \(sensorData.temperatureC, specifier: "%.1f")°C")
                                .font(.system(size: 28, weight: .bold))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .cornerRadius(8)
                                .padding(.horizontal)
                        } else {
                            Text("Loading data...")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                        }
                        refreshButton
                    }
                    .tag(1)

                    VStack {
                        if let sensorData = sensorData {
                            Text("Heat Index: \(sensorData.heatIndexC, specifier: "%.1f")°C")
                                .font(.system(size: 28, weight: .bold))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .cornerRadius(8)
                                .padding(.horizontal)
                        } else {
                            Text("Loading data...")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                        }
                        refreshButton
                    }
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))

                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            isAutoMode.toggle()
                            if isAutoMode, let temp = sensorData?.temperatureC {
                                adjustFanSpeedIfNeeded(temp)
                            } else {
                                debounceTimer?.invalidate() // Stop continuous polling if auto mode is off
                            }
                        }) {
                            Text(isAutoMode ? "Auto Mode ON" : "Auto Mode OFF")
                                .font(.headline)
                                .padding(10)
                                .background(isAutoMode ? Color.green : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding()
                    }
                }
            }
            .onAppear {
                fetchData()
                startContinuousPolling()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
        }
    }

    func getBackgroundColor(for temperature: Float) -> Color {
        switch temperature {
        case ..<0:
            return Color.blue
        case 0..<10:
            return Color.cyan
        case 10..<20:
            return Color.green
        case 20..<30:
            return Color.orange
        default:
            return Color.red
        }
    }

    var refreshButton: some View {
        Button(action: fetchData) {
            Text("Refresh Data")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(15)
                .background(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

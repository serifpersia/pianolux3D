#define udpPort 12345
WiFiUDP udp;

void taskWiFiCommunication(void* parameter) {
  // Initialize UDP server here
  udp.begin(udpPort);
  Serial.println("UDP server started, listening on port " + String(udpPort));

  while (true) {
    // WiFi communication logic goes here
    receiveUDPData();
    vTaskDelay(1 / portTICK_PERIOD_MS); // Slight delay to avoid CPU hogging
  }
}

void receiveUDPData() {
  // Check if data is available to read
  int packetSize = udp.parsePacket();
  if (packetSize) {
    byte packetBuffer[packetSize]; // Create a buffer to hold the packet data
    udp.read(packetBuffer, packetSize); // Read the packet into packetBuffer

    // Process the packet based on its type
    switch (packetSize) {
      case 1:
        handleNoteOff(packetBuffer);
        break;
      case 2:
        handleNoteOn(packetBuffer);
        break;
      case 11: // Special packet size for requesting ESP32 IP info
        sendESP32IPInfo(); // Send ESP32 IP info in response
        break;
      default:
        break;
    }
  }
}

void sendESP32IPInfo() {
  IPAddress localIP = WiFi.localIP();

  byte responseBuffer[4]; // Assuming IPv4 address
  responseBuffer[0] = localIP[0];
  responseBuffer[1] = localIP[1];
  responseBuffer[2] = localIP[2];
  responseBuffer[3] = localIP[3];

  udp.beginPacket(udp.remoteIP(), udp.remotePort());
  udp.write(responseBuffer, 4); // Assuming IPv4 address
  udp.endPacket();
  WebSerial.println("Requested ESP32's IP sent");
  WebSerial.println(localIP);
}

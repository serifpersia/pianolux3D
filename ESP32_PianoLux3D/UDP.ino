#define udpPort 12345
WiFiUDP udp;

void taskWiFiCommunication(void* parameter) {
  udp.begin(udpPort);
  while (true) {
    receiveUDPData();
    vTaskDelay(1 / portTICK_PERIOD_MS);
  }
}

void receiveUDPData() {
  int packetSize = udp.parsePacket();
  if (packetSize > 0) {
    byte packetBuffer[packetSize];
    udp.read(packetBuffer, packetSize);

    if (packetSize == 11 && strncmp((char*)packetBuffer, "ScanRequest", 11) == 0) {
      sendESP32IPInfo();
      return;
    }

    byte first_byte = packetBuffer[0];

    // Check if the Note On flag (MSB) is set
    if (first_byte & 0x80) {
      if (packetSize == 2) {
        // Pass the entire buffer to the handler
        handleNoteOn(packetBuffer);
      }
    } else {
      if (packetSize == 1) {
        // Pass the entire buffer to the handler
        handleNoteOff(packetBuffer);
      }
    }
  }
}
void sendESP32IPInfo() {
  IPAddress localIP = WiFi.localIP();
  byte responseBuffer[4];
  responseBuffer[0] = localIP[0];
  responseBuffer[1] = localIP[1];
  responseBuffer[2] = localIP[2];
  responseBuffer[3] = localIP[3];
  udp.beginPacket(udp.remoteIP(), udp.remotePort());
  udp.write(responseBuffer, 4);
  udp.endPacket();
}

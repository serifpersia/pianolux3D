bool inUse = false;

void webSocketEvent(uint8_t num, WStype_t type, uint8_t *payload, size_t length) {
  switch (type) {

    case WStype_CONNECTED:
      numConnectedClients++;
      if (numConnectedClients == 1 && !inUse) {
        changeLEDModeAction(0);
        inUse = true;
      }
      break;

    case WStype_DISCONNECTED:
      numConnectedClients--;
      break;

    case WStype_TEXT:
      // Parse the JSON message
      StaticJsonDocument<200> doc;
      DeserializationError error = deserializeJson(doc, payload);

      if (error) {
        Serial.print("JSON parsing error: ");
        Serial.println(error.c_str());
        return;
      }

      String action = doc["action"];

      if (action == "ChangeLEDModeAction") {
        serverMode = doc["value"];
        changeLEDModeAction(serverMode);
        Serial.println("LED ID: ");
        Serial.print(serverMode);
      } else if (action == "ChangeAnimationAction") {
        animationIndex = doc["value"];
        Serial.println("Animation ID: ");
        Serial.print(animationIndex);
      } else if (action == "Hue") {
        uint8_t value = doc["value"];
        sliderAction(1, value);
      } else if (action == "Saturation") {
        uint8_t value = doc["value"];
        sliderAction(6, value);
      } else if (action == "Brightness") {
        uint8_t value = doc["value"];
        sliderAction(2, value);
      } else if (action == "Fade") {
        uint8_t value = doc["value"];
        sliderAction(3, value);
      } else if (action == "Splash") {
        uint8_t value = doc["value"];
        sliderAction(4, value);
      } else if (action == "Background") {
        uint8_t value = doc["value"];
        sliderAction(5, value);
      } else if (action == "CurrentAction") {
        LED_CURRENT = doc["value"];
        FastLED.setMaxPowerInVoltsAndMilliamps(5, LED_CURRENT);
        updateConfigFile("LED_CURRENT", LED_CURRENT);
      } else if (action == "LedDataPinAction") {
        LED_PIN = doc["value"];
        updateConfigFile("LED_PIN", LED_PIN);
        delay(1000);    // Debounce the button
        ESP.restart();  // Restart the ESP32
      }
      else if (action == "ChangeColorOrderAction") {
        COLOR_ORDER = doc["colorOrder"];
        updateConfigFile("COLOR_ORDER", COLOR_ORDER);
        delay(1000);    // Debounce the button
        ESP.restart();  // Restart the ESP32
      }
      else if (action == "ColorPresetAction") {
        hue = doc["colorPresetHue"];
        saturation = doc["colorPresetSaturation"];
        COLOR_PRESET = doc["colorPresetID"];
      }
      else if (action == "BGAction") {
        bgToggle = doc["value"];
        if (bgToggle == 1) {
          setBG(CHSV(hue, saturation, bgBrightness));
        } else if (bgToggle == 0) {
          setBG(CHSV(0, 0, 0));
        }
      } else if (action == "DirectionAction") {
        reverseToggle = doc["value"];
        if (reverseToggle == 1) {
          STRIP_DIRECTION = 1;
        } else if (reverseToggle == 0) {
          STRIP_DIRECTION = 0;
        }
      } else if (action == "BGUpdateAction") {
        bgUpdateToggle = doc["value"];
        setBG(CHSV(hue, saturation, bgBrightness));
      }
      break;
  }
}

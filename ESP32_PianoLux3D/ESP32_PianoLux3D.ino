/*
  PianoLux3D is an open-source project that aims to provide MIDI-based LED control to the masses.
  It is developed by a one-person team.

  To use this version of the code, install esp32 arduino core version 2.0.14,
  install required libraries via .bat or .sh scripts depending on
  what os you are using.After libs install, restart Arduino IDE 1.8.x.
  Select your board under Tools>Board> ESP32, ESP32-S2 or ESP32S3
  (*other boards are not tested and aren't guaranteed to work with the project)
  Edit config.cfg file in the data folder to change pin number for led strip data pin default
  is pin 18, also u can change led color order and led strip max current in mA
  Under Tools>ESP32PartitionTool will open my tool for uploading, select LittleFS
  under SPIFFS section and press Merge binary and upload.
  With no errors you can connect via wifi capable device to PianoLux3D AP WIFi and
  setup your local network WiFi, after that you are ready to use PianoLux3D app on your OS

  If you modify this code and redistribute the PianoLux3D project, please ensure that you
  don't remove this disclaimer or appropriately credit the original author of the project
  by linking to the project's source on GitHub: github.com/serifpersia/pianolux3d/
  Failure to comply with these terms would constitute a violation of the project's
  MIT license under which PianoLux3D is released.

  Copyright © 2024 Serif Rami, aka serifpersia

*/

String firmwareVersion = "v1.0";

#define USE_ELEGANT_OTA 1 // Set to 1 to use ElegantOTA, 0 to not use

// WIFI Libs
#include <WiFiManager.h>
#include <ESPmDNS.h>
//#include <WebSerial.h>

#include <ArduinoJson.h>
#include <ESPAsyncWebServer.h>
#include <WebSocketsServer.h>

#if USE_ELEGANT_OTA
#include <ElegantOTA.h>
#endif

// ESP Storage Lib
#include <LittleFS.h>

//FastLED Lib
#include <FastLED.h>
#include "FadingRunEffect.h"
#include "FadeController.h"

// Initialization of webserver and websocket
AsyncWebServer server(80);
WebSocketsServer webSocket(81);

TaskHandle_t WiFiCommunicationTask;

// Constants for LED strip
#define UPDATES_PER_SECOND 60
#define MAX_NUM_LEDS 176         // How many LEDs do you want to control
#define MAX_EFFECTS 128

#define USE_NEOPIXEL_STRIP 1

//RMT LED STRIP INIT
#include "w2812-rmt.hpp"  // Include the custom ESP32RMT_WS2812B class
ESP32RMT_WS2812B<GRB>* wsstripGRB;
ESP32RMT_WS2812B<RGB>* wsstripRGB;
ESP32RMT_WS2812B<BRG>* wsstripBRG;

FadingRunEffect* effects[MAX_EFFECTS];
FadeController* fadeCtrl = new FadeController();


uint8_t DEFAULT_BRIGHTNESS = 255;
uint8_t NUM_LEDS = 176;       // How many LEDs you want to control
uint8_t STRIP_DIRECTION = 0;  // 0 - left-to-right

uint8_t generalFadeRate = 255;
uint8_t numEffects = 0;


uint8_t  getHueForPos(uint8_t pos) {
  return pos * 255 / NUM_LEDS;
}

uint8_t ledNum(uint8_t i) {
  return STRIP_DIRECTION == 0 ? i : (NUM_LEDS - 1) - i;
}

CRGB leds[MAX_NUM_LEDS];
CRGB bgColor = CRGB::Black;
CRGB guideColor = CRGB::Black;

boolean bgOn = false;
boolean keysOn[MAX_NUM_LEDS];

boolean isOnStrip(uint8_t pos) {
  return pos >= 0 && pos < NUM_LEDS;
}

uint8_t hue = 0;
uint8_t brightness = 255;
uint8_t saturation = 255;
uint8_t bgBrightness = 128;

#define HUE_CHANGE_SPEED 1 // Adjust this value to control the speed of hue change

uint8_t currentHue[MAX_NUM_LEDS] = {0}; // Array to store current hue value for each LED

uint8_t bgToggle;
uint8_t reverseToggle;
uint8_t bgUpdateToggle = 1;

uint8_t LED_PIN;
uint8_t COLOR_PRESET;
uint8_t COLOR_ORDER;
uint16_t LED_CURRENT = 450;

unsigned long currentTime = 0;
unsigned long previousTime = 0;
unsigned long previousFadeTime = 0;

unsigned long interval = 20;      // General refresh interval in milliseconds
unsigned long fadeInterval = 20;  // General fade interval in milliseconds

const uint8_t MAX_VELOCITY = 127;

const uint8_t COMMAND_SET_COLOR = 255;
const uint8_t COMMAND_FADE_RATE = 254;
const uint8_t COMMAND_ANIMATION = 253;
const uint8_t COMMAND_BLACKOUT = 252;
const uint8_t COMMAND_SPLASH = 251;
const uint8_t COMMAND_SET_BRIGHTNESS = 250;
const uint8_t COMMAND_KEY_OFF = 249;
const uint8_t COMMAND_SPLASH_MAX_LENGTH = 248;
const uint8_t COMMAND_SET_BG = 247;
const uint8_t COMMAND_VELOCITY = 246;

uint8_t MODE = COMMAND_SET_COLOR;

uint8_t serverMode;

uint8_t animationIndex;

uint8_t splashMaxLength = 8;
uint8_t SPLASH_HEAD_FADE_RATE = 5;

uint8_t numConnectedClients = 0;

CRGBPalette16 currentPalette;
TBlendType currentBlending;

extern CRGBPalette16 myRedWhiteBluePalette;
extern const TProgmemPalette16 myRedWhiteBluePalette_p PROGMEM;

float distance(CRGB color1, CRGB color2) {
  return sqrt(pow(color1.r - color2.r, 2) + pow(color1.g - color2.g, 2) + pow(color1.b - color2.b, 2));
}

void loadConfig() {
  File configFile = LittleFS.open("/config.cfg", "r");
  if (configFile) {
    size_t size = configFile.size();
    std::unique_ptr<char[]> buf(new char[size]);
    configFile.readBytes(buf.get(), size);

    DynamicJsonDocument doc(1024);
    deserializeJson(doc, buf.get());

    // Update configuration variables
    LED_PIN = doc["LED_PIN"] | LED_PIN;
    COLOR_ORDER = doc["COLOR_ORDER"] | COLOR_ORDER;
    LED_CURRENT = doc["LED_CURRENT"] | LED_CURRENT;
    // Add more variables as needed

    configFile.close();
  } else {
    Serial.println("Failed to open config file for reading");
  }
}

void updateConfigFile(const char* configKey, uint16_t newValue) {
  DynamicJsonDocument doc(1024);

  // Read the existing config file
  File configFile = LittleFS.open("/config.cfg", "r");
  if (configFile) {
    size_t size = configFile.size();
    std::unique_ptr<char[]> buf(new char[size]);
    configFile.readBytes(buf.get(), size);
    configFile.close();

    // Deserialize the JSON document
    deserializeJson(doc, buf.get());

    // Update the specified config key with the new value
    doc[configKey] = newValue;

    // Save the updated config file
    File updatedConfigFile = LittleFS.open("/config.cfg", "w");
    if (updatedConfigFile) {
      serializeJson(doc, updatedConfigFile);
      updatedConfigFile.close();
      Serial.println("Config file updated successfully");
    } else {
      Serial.println("Failed to open config file for writing");
    }
  } else {
    Serial.println("Failed to open config file for reading");
  }
}

void initializeLEDStrip(uint8_t colorMode) {

  if (USE_NEOPIXEL_STRIP)
  {
    switch (colorMode) {
      case 0:
        wsstripGRB = new ESP32RMT_WS2812B<GRB>(LED_PIN);
        FastLED.addLeds(wsstripGRB, leds, NUM_LEDS);
        break;
      case 1:
        wsstripRGB = new ESP32RMT_WS2812B<RGB>(LED_PIN);
        FastLED.addLeds(wsstripRGB, leds, NUM_LEDS);
        break;
      case 2:
        wsstripBRG = new ESP32RMT_WS2812B<BRG>(LED_PIN);
        FastLED.addLeds(wsstripBRG, leds, NUM_LEDS);
        break;
      // Add more cases if needed
      default:
        // Handle default case if colorMode is not 0, 1, or 2
        break;
    }
  }
  else
  {
    // Pick one of the strips below or look at FastLED repo for all supported strips
    //144leds/m 2m strips are needed no matter the type!

    //FastLED.addLeds<WS2812B, DATA_PIN, GRB>(leds, NUM_LEDS);
    // FastLED.addLeds<NEOPIXEL, DATA_PIN>(leds, NUM_LEDS);
    // FastLED.addLeds<WS2812, DATA_PIN, RGB>(leds, NUM_LEDS);
    // FastLED.addLeds<WS2852, DATA_PIN, RGB>(leds, NUM_LEDS);
    // FastLED.addLeds<WS2812B, DATA_PIN, RGB>(leds, NUM_LEDS);
    // FastLED.addLeds<WS2811, DATA_PIN, RGB>(leds, NUM_LEDS);
    // FastLED.addLeds<WS2813, DATA_PIN, RGB>(leds, NUM_LEDS);
    // FastLED.addLeds<APA104, DATA_PIN, RGB>(leds, NUM_LEDS);
    // FastLED.addLeds<WS2811_400, DATA_PIN, RGB>(leds, NUM_LEDS);
    // FastLED.addLeds<WS2801, DATA_PIN, CLOCK_PIN, RGB>(leds, NUM_LEDS);
    // FastLED.addLeds<WS2803, DATA_PIN, CLOCK_PIN, RGB>(leds, NUM_LEDS);
    // FastLED.addLeds<SK6812, DATA_PIN, RGB>(leds, NUM_LEDS);
  }
  FastLED.setMaxPowerInVoltsAndMilliamps(5, LED_CURRENT);  // set power limit
  FastLED.setBrightness(DEFAULT_BRIGHTNESS);
}

void StartupAnimation() {
  for (uint8_t i = 0; i < NUM_LEDS; i++) {
    leds[i] = CHSV(getHueForPos(i), 255, 255);
    FastLED.show();
    leds[i] = CHSV(0, 0, 0);
  }
  FastLED.show();
}

bool startPortal = true;  // Start WiFi Manager Captive Portal

const uint8_t wmJumperPin = 15;  // Jumper pin for WiFi Manager Captive Portal
const uint8_t apJumperPin = 16;      // Jumper pin for AP mode

void startWmPortal(WiFiManager& wifiManager) {
  if (!wifiManager.startConfigPortal("PianoLux3D Portal")) {
    ESP.restart();
  }
}

void startAP() {
  // Start ESP32 in AP mode
  WiFi.softAP("PianoLux3D AP");
}

void startSTA(WiFiManager& wifiManager) {

  startPortal = false;

  // Start WiFi Manager for configuring STA mode

  //Try to connect within 5 seconds
  wifiManager.setConnectTimeout(5);
  // Set callback to be invoked when configuration is updated
  wifiManager.setSaveConfigCallback([]() {
    Serial.println("Configurations updated");
    ESP.restart();
  });

  if (!wifiManager.autoConnect("PianoLux3D Portal")) {
    wifiManager.resetSettings();
    ESP.restart();
  }
}

bool handleFileRead(AsyncWebServerRequest *request) {
  String path = request->url();
  Serial.println("Request for file: " + path);
  if (path.endsWith("/")) {
    path += "index.html";
  }

  String contentType = getContentType(path);
  if (!LittleFS.exists(path)) {
    Serial.println("File not found: " + path);
    return false;
  }

  // Open the file for reading
  File file = LittleFS.open(path, "r");
  if (!file) {
    Serial.println("Failed to open file: " + path);
    return false;
  }

  // Send the file content to the client
  request->send(LittleFS, path, contentType);

  Serial.println("File served: " + path);
  return true;
}

String getContentType(String filename) {
  if (filename.endsWith(".html")) return "text/html";
  if (filename.endsWith(".css"))  return "text/css";
  if (filename.endsWith(".js"))   return "application/javascript";
  if (filename.endsWith(".ico"))  return "image/x-icon";
  return "text/plain";
}

#if USE_ARDUINO_OTA
void setupArduinoOTA()
{
  ArduinoOTA.setHostname("PianoLux3D-ESP32-OTA");

  ArduinoOTA
  .onStart([]() {
    String type;
    if (ArduinoOTA.getCommand() == U_FLASH)
      type = "sketch";
    else // U_LittleFS
      type = "filesystem";

    // NOTE: if updating LittleFS this would be the place to unmount LittleFS using LittleFS.end()
    Serial.println("Start updating " + type);
  })
  .onEnd([]() {
    Serial.println("\nEnd");
  })
  .onProgress([](unsigned int progress, unsigned int total) {
    Serial.printf("Progress: %u%%\r", (progress / (total / 100)));
  })
  .onError([](ota_error_t error) {
    Serial.printf("Error[%u]: ", error);
    if (error == OTA_AUTH_ERROR) Serial.println("Auth Failed");
    else if (error == OTA_BEGIN_ERROR) Serial.println("Begin Failed");
    else if (error == OTA_CONNECT_ERROR) Serial.println("Connect Failed");
    else if (error == OTA_RECEIVE_ERROR) Serial.println("Receive Failed");
    else if (error == OTA_END_ERROR) Serial.println("End Failed");
  });

  ArduinoOTA.begin();
}
#endif

void setup() {
  // Start Serial at 115200 baud rate
  Serial.begin(115200);
  while (!Serial) {
    // Wait for Serial to be ready
  }
  Serial.println("Serial started at 115200");

  pinMode(wmJumperPin, INPUT_PULLUP);
  pinMode(apJumperPin, INPUT_PULLUP);

  // Create WiFiManager object inside setup
  WiFiManager wifiManager;

  if (digitalRead(wmJumperPin) == LOW) {
    // wmJumperPin is pulled to GND, use WiFi Manager Captive Portal
    startWmPortal(wifiManager);
  } else if (digitalRead(apJumperPin) == LOW) {
    // apJumperPin is pulled to GND, use AP mode
    startAP();
  } else {
    // None of the pins are grounded, STA mode
    startSTA(wifiManager);
  }

  //Print ESP32's IP Address
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());


  // Initialize and start mDNS
  if (MDNS.begin("pianolux3d")) {
    Serial.println("MDNS Responder Started!");
  }

  // Initialize LittleFS
  if (!LittleFS.begin()) {
    Serial.println("An error occurred while mounting LittleFS");
    return;
  }
  Serial.println("LittleFS mounted successfully");

  // Route for serving static files
  server.onNotFound([](AsyncWebServerRequest * request) {
    if (!handleFileRead(request)) {
      request->send(404, "text/html", "<html><body><h1>No website files found on ESP32</h1></body></html>");
    }
  });


  // Load configuration from file
  loadConfig();

#if USE_ELEGANT_OTA
  ElegantOTA.begin(&server);
#endif

  //  server.on("/", HTTP_GET, [](AsyncWebServerRequest * request) {
  //    request->send(200, "text/plain", "Hi! This is WebSerial demo. You can access webserial interface at http://" + WiFi.localIP().toString() + "/webserial");
  //  });

  // WebSerial is accessible at "<IP Address>/webserial" in browser
  //  WebSerial.begin(&server);

  //  /* Attach Message Callback */
  //  WebSerial.onMessage([&](uint8_t *data, size_t len) {
  //    Serial.printf("Received %u bytes from WebSerial: ", len);
  //    Serial.write(data, len);
  //    Serial.println();
  //    WebSerial.println("Received Data...");
  //    String d = "";
  //    for (size_t i = 0; i < len; i++) {
  //      d += char(data[i]);
  //    }
  //    WebSerial.println(d);
  //  });


  server.begin();

  // Add service to mDNS for HTTP
  MDNS.addService("http", "tcp", 80);

  // Initialize LED strip based on the loaded configuration
  initializeLEDStrip(COLOR_ORDER);

  webSocket.begin();
  webSocket.onEvent(webSocketEvent);

  StartupAnimation();
  if (!startPortal) {
    setIPLeds();
  }

  // Initialize WiFi communication task
  xTaskCreatePinnedToCore(
    taskWiFiCommunication,
    "WiFiTask",
    4096,
    NULL,
    1,
    &WiFiCommunicationTask,
    1
  );

}

void loop() {

#if USE_ELEGANT_OTA
  ElegantOTA.loop();
#endif

  webSocket.loop();
  //  WebSerial.loop();

  if (serverMode == 2) {
    // Update hue for LEDs that are currently on
    for (uint8_t i = 0; i < NUM_LEDS; i++) {
      if (keysOn[i]) {
        currentHue[i] = (currentHue[i] + HUE_CHANGE_SPEED) % 256;
        controlLeds(i, currentHue[i], saturation, brightness);
      }
    }
  }

  currentTime = millis();

  //slowing it down with interval
  if (currentTime - previousTime >= interval) {
    for (uint8_t i = 0; i < numEffects; i++) {
      if (effects[i]->finished()) {
        delete effects[i];
        removeEffect(effects[i]);
      } else {
        effects[i]->nextStep();
      }
    }
    previousTime = currentTime;
  }
  if (currentTime - previousFadeTime >= fadeInterval) {
    if (numEffects > 0 || generalFadeRate > 0) {
      fadeCtrl->fade(generalFadeRate);
    }
    previousFadeTime = currentTime;
  }
  switch (MODE) {
    case COMMAND_ANIMATION:
      if (animationIndex == 7) {
        // If the selected animation is 7, run the sineWave() animation
        sineWave();
      } else if (animationIndex == 8) {
        // If the selected animation is 7, run the sineWave() animation
        sparkleDots();
      } else if (animationIndex == 9) {
        // If the selected animation is 7, run the sineWave() animation
        Snake();
      } else {
        // For other animations (0 to 6), use the palette-based approach
        Animatons(animationIndex);
        static uint8_t startIndex = 0;
        startIndex = startIndex + 1; /* motion speed */
        FillLEDsFromPaletteColors(startIndex);
      }
      break;
  }
  FastLED.show();
}

void controlLeds(uint8_t ledNo, uint8_t hueVal, uint8_t saturationVal, uint8_t brightnessVal) {
  if (ledNo < 0 || ledNo >= NUM_LEDS) {
    Serial.println("Invalid LED index");
    return;
  }
  // Convert HSB values to RGB values
  CRGB color = CHSV(hueVal, saturationVal, brightnessVal);
  leds[ledNum(ledNo)] = color;  // Set the LED color
  FastLED.show();               // Update the LEDs with the new color
}

void sliderAction(uint8_t sliderNumber, uint8_t value) {
  if (sliderNumber == 1) {
    hue = value;
  } else if (sliderNumber == 2) {
    DEFAULT_BRIGHTNESS = value;
    FastLED.setBrightness(DEFAULT_BRIGHTNESS);
  } else if (sliderNumber == 3) {
    generalFadeRate = value;
  } else if (sliderNumber == 4) {
    splashMaxLength = value;
  } else if (sliderNumber == 5) {
    bgBrightness = value;
  } else if (sliderNumber == 6) {
    saturation = value;
  }
  Serial.print("Slider ");
  Serial.print(sliderNumber);
  Serial.print(" Value: ");
  Serial.println(value);
}

//Change LED Mode
void changeLEDModeAction(uint8_t serverMode) {
  blackout();
  generalFadeRate = 255;

  //Default Mode
  if (serverMode == 0) {
    MODE = COMMAND_SET_COLOR;
  }
  //Splash Mode
  else if (serverMode == 1) {
    generalFadeRate = 50;
    MODE = COMMAND_SPLASH;

  }

  //Velocity Mode
  else if (serverMode == 3) {
    MODE = COMMAND_VELOCITY;
  }
  //Animation Mode
  else if (serverMode == 4) {
    MODE = COMMAND_ANIMATION;
    generalFadeRate = 0;
  }
}
void blackout() {
  fill_solid(leds, NUM_LEDS, bgColor);
  MODE = COMMAND_BLACKOUT;
}

void setColorFromVelocity(uint8_t velocity, uint8_t& hue, uint8_t& saturation, uint8_t& brightness) {
  static uint8_t previousVelocity = 0;

  // Calculate the smoothed velocity as a weighted average
  uint8_t smoothedVelocity = (velocity + previousVelocity * 3) / 4;
  previousVelocity = smoothedVelocity;

  // Map smoothed velocity to hue value (green is 0° and red is 120° in HSV color space)
  hue = map(smoothedVelocity, 16, 80, 75, 255);

  // Clamp the hue value within the valid range
  hue = constrain(hue, 75, 255);

  // Map smoothed velocity to brightness value (higher velocity means higher brightness)
  brightness = map(smoothedVelocity, 16, 80, 65, 255);

  // Clamp the brightness value within the valid range
  brightness = constrain(brightness, 65, 255);

  // Set saturation to a fixed value (e.g., 255 for fully saturated color)
  saturation = 255;
}

// Add a new effect
void addEffect(FadingRunEffect* effect) {
  if (numEffects < MAX_EFFECTS) {
    effects[numEffects] = effect;
    numEffects++;
  }
}

// Remove an effect
void removeEffect(FadingRunEffect* effect) {
  for (uint8_t i = 0; i < numEffects; i++) {
    if (effects[i] == effect) {
      // Shift the remaining effects down
      for (uint8_t j = i; j < numEffects - 1; j++) {
        effects[j] = effects[j + 1];
      }
      numEffects--;
      break;
    }
  }
}

void setBG(CRGB colorToSet) {
  fill_solid(leds, NUM_LEDS, colorToSet);
  bgColor = colorToSet;
  FastLED.show();
}

void setIPLeds() {
  IPAddress localIP = WiFi.localIP();
  String ipStr = localIP.toString();

  // Define colors
  CRGB redColor = CRGB(255, 0, 0);        // Red
  CRGB blueColor = CRGB(0, 0, 255);       // Blue
  CRGB blackColor = CRGB(0, 0, 0);        // Black (off)
  CRGB whiteColor = CRGB(255, 255, 255);  // White

  // Define LED index and spacing
  uint8_t ledIndex = 0;
  uint8_t spacing = 1;

  // Loop through each character in the IP address
  for (uint8_t i = 0; i < ipStr.length(); i++) {
    char c = ipStr.charAt(i);

    if (c == '.') {
      // Display a blue LED for the dot
      leds[ledIndex] = blueColor;
      ledIndex++;
    } else if (c == '0') {
      // Display white LED for 0
      leds[ledIndex] = whiteColor;
      ledIndex++;
    } else if (c >= '1' && c <= '9') {
      // Convert character to an integer
      uint8_t number = c - '0';

      // Display red LEDs for other numbers
      for (uint8_t j = 0; j < number; j++) {
        leds[ledIndex] = redColor;
        ledIndex++;
      }
    }

    // Display black LED for spacing
    leds[ledIndex] = blackColor;
    ledIndex++;
  }

  // Show the entire IP address
  generalFadeRate = 0;
  FastLED.show();
}

void sendESP32Log(String logMessage) {
  JsonDocument doc;

  doc["LOG_MESSAGE"] = logMessage;

  // Serialize the JSON document to a string
  String jsonStr;
  serializeJson(doc, jsonStr);

  // Send the JSON data to all connected clients
  Serial.println("Sending Data To Clients");
  webSocket.broadcastTXT(jsonStr);
}

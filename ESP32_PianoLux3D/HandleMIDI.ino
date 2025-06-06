void handleNoteOn(byte* packetBuffer) {
  byte note = packetBuffer[0] & 0x7F;
  byte velocity = packetBuffer[1];
  noteOn(note, velocity);
  if (numConnectedClients != 0)
  {
    sendESP32Log("UDP MIDI IN: LED ON INDEX: " + String(note) + " Velocity: " + String(velocity));
  }
}

void handleNoteOff(byte* packetBuffer) {
  byte note = packetBuffer[0];
  noteOff(note);
  if (numConnectedClients != 0)
  {
    sendESP32Log("UDP MIDI IN: LED OFF INDEX: " + String(note));
  }
}

unsigned long previousNoteOnTime = 0;
uint8_t previousRandomHue = 0;
uint8_t firstNoteHue = 0;

void noteOn(uint8_t note, uint8_t velocity) {
  keysOn[note] = true;

  if (serverMode == 0) {
    controlLeds(note, hue, saturation, brightness);  // Both use the same index
  } else if (serverMode == 1) {
    CHSV hsv(hue, saturation, brightness);
    addEffect(new FadingRunEffect(splashMaxLength, note, hsv, SPLASH_HEAD_FADE_RATE, velocity));
  } else if (serverMode == 2) {
    // Check time difference between the current note-on and the previous one
    unsigned long currentTime = millis();
    unsigned long timeDifference = currentTime - previousNoteOnTime;

    // Assign the same hue as the first note within the chord time window
    if (timeDifference <= 600) {  // Adjust this chord threshold as needed
      currentHue[note] = firstNoteHue;
    } else if (timeDifference <= 50) {  // Adjust this second threshold as needed
      // Use a slightly different hue for notes close to the first note within the chord time window
      currentHue[note] = firstNoteHue + 10; // Adjust the increment value as needed
    } else {
      // Generate a new random hue for this note-on event
      uint8_t newRandomHue = random(256);
      currentHue[note] = newRandomHue;

      // Update the time and hue of the first note within the chord time window
      previousNoteOnTime = currentTime;
      firstNoteHue = newRandomHue;
    }
    controlLeds(note, currentHue[note], saturation, brightness);
  } else if (serverMode == 3) {
    uint8_t hue, saturation, brightness;
    setColorFromVelocity(velocity, hue, saturation, brightness);
    controlLeds(note, hue, saturation, brightness);
  }
}

void noteOff(uint8_t note) {
  keysOn[note] = false;
}

// Updated function to handle MIDI NOTE_ON
void handleNoteOn(byte* packetBuffer) {
  byte note = packetBuffer[0];
  byte velocity = packetBuffer[1];
  noteOn(note, velocity);
}

// Updated function to handle MIDI NOTE_OFF
void handleNoteOff(byte* packetBuffer) {
  byte note = packetBuffer[0];
  noteOff(note);
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
  //Split Mode
  else if (serverMode == 5) {
    // Split Mode
    uint8_t splitIndex = map(note, splitLeftMinPitch, splitRightMaxPitch, 0, 100);

    if (splitIndex <= splitPosition) {
      // Use left color
      controlLeds(note, splitLeftColor.h, splitLeftColor.s, splitLeftColor.v);
    } else {
      // Use right color
      controlLeds(note, splitRightColor.h, splitRightColor.s, splitRightColor.v);
    }
  }
}

void noteOff(uint8_t note) {
  keysOn[note] = false;
}

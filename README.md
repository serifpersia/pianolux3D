<div align="center">
  
![pianolux_logo](https://github.com/serifpersia/pianolux-esp32/assets/62844718/41b64e47-2d2b-4114-b2ca-05d3ef084215)

<h1><span class="piano-text" style="color: white;">PianoLux</span></h1> 

  [![Release](https://img.shields.io/github/release/serifpersia/pianolux-godot.svg?style=flat-square)](https://github.com/serifpersia/pianolux-godot/releases)
  [![License](https://img.shields.io/github/license/serifpersia/pianolux-godot?color=blue&style=flat-square)](https://raw.githubusercontent.com/serifpersia/pianolux-godot/master/LICENSE)
  [![Discord](https://img.shields.io/discord/1077195120950120458.svg?colorB=blue&label=discord&style=flat-square)](https://discord.gg/MAypyD7k86)
</div>

PianoLux is Godot Game Engine port of PianoLux Java and ESP32 versions of the application. Midi visualization and WS2812B led strip controller application.

## Join Our Community

Be part of the PianoLux Discord Server Community where you can connect with fellow users, ask questions, and share your experiences:

[![Discord Server](https://discordapp.com/api/guilds/1077195120950120458/widget.png?style=banner2)](https://discord.gg/MAypyD7k86)
## Demo
<div align="center">

https://github.com/serifpersia/pianolux-arduino/assets/62844718/6342ae71-eb57-4ae7-88c2-e7f4cdfcc62f

</div>

## MIDI Visualization

https://github.com/user-attachments/assets/d336ac71-31f6-4dcd-815a-4ed50319e2d1

## LED Strip Compatibility

PianoLux is compatible with officially supported strips by FastLED library default are NeoPixels/WS2812B. Density must be 144 which is supported on all modes of the app and 72 density for few basic modes. You can find list of FastLED supported leds below:

*Main arduino code ino has to be modified to align with strip you will use

|LED Type| Configuration|
|---------------------|-|
| Clockless Types     |
| WS2812              |
| WS2852              |
| WS2812B             |
| SK6812              |RGB non RGBW variant|
| WS2811              |
| WS2813              |
| WS2811_400          |
| GW6205              |
| GW6205_400          |
| LPD1886             |
| LPD1886_8BIT        |
| Clocked (SPI) Types |
| LPD6803             |
| LPD8806             |
| WS2801              |
| WS2803              |
| SM16716             |
| P9813               | 
| DOTSTAR             |
| APA102              |
| SK9822              |
| 12V| Strips like WS2815 configured as WS2812 GRB or RGB|
| RGBW Not Supported  |SK6812W or any other RGBW|

*Make sure you check latest FastLED github repo for updates on supported led chipsets

PianoLux currently requires native USB Arduino boards with an Atmega32U4 CPU, such as:

- Arduino Leonardo
- Pro Micro

Some arm32 based native usb boards will also work latest arduino code needs to be adapted to work with them.
- Arduino Due
- *Serial lines should be replaced with SerialUSB and native usb port should be used
- Arduino Zero

ESP32 platform boards also are supported
- ESP32/S2/S3

## Download

You can download the latest release of PianoLux here:

 [![Release](https://img.shields.io/github/release/serifpersia/pianolux-godot.svg?style=flat-square)](https://github.com/serifpersia/pianolux-godot/releases)

## Connecting the LED Strip and Arduino

To set up PianoLux, follow the connection diagram below:

![LED Strip + Arduino Leonardo Connection Diagram](https://user-images.githubusercontent.com/62844718/221054671-316bdee3-8a36-4753-bfb5-a574059c51ca.png)

## Enhance Brightness with External Power

For maximum brightness, consider using an external power source. Here's how you can do it:

1. Use a minimum 3A 5V-capable USB charger.
2. Cut a spare USB cable and connect the positive (usually red) and negative (usually black) wires to the LED strip's red and white wires, respectively.
Don't forget to link this ground connection to arduino's ground pin. This to to avoid ground loop issues since we are using two power sources we need to link both grounds
together.
4. Adjust the current limit to match the power supply's current rating in mA (1A = 1000mA, so 3A = 3000mA).

![External Power Setup](https://github.com/serifpersia/pianolux-arduino/assets/62844718/767c5a59-e80c-4aa8-97db-f6af03f68f24.png)

## Mounting the LED Strip

For an 88-key piano, align the third LED with the first black key, as shown below:

![image](https://user-images.githubusercontent.com/62844718/235168165-9b97120a-66ed-44f5-a7fb-11cc164cf945.png)

## Instructions for Windows OS

To use PianoLux on Windows, follow these steps:

1. [Download Arduino IDE](https://www.arduino.cc/en/software)

3. You will need the Arduino IDE application to upload the `.ino` file to your Arduino board. Ensure that you install FastLED library

![Arduino IDE and Drivers](https://github.com/serifpersia/pianolux-arduino/assets/62844718/67236214-f701-4f23-bba4-663ad9c5babd.png)

4. Once you see the "Upload Complete" prompt, you are ready to use the PianoLux app.

## Instructions for Linux

To use PianoLux on Linux, follow these steps:

- Install Arduino IDE 2 and upload the PianoLux code to your Arduino board.

## Gettings Started

- To run the app:

   Unzip the downloaded windows or linux zip file to a location of your choice.

1. **Run the App**

   - For **Windows**: Run `PianoLux.exe`.
   - For **Linux**: Execute following command in the terminal `sudo PianoLux.x86_64`

2. **Configure Serial**

   - Select Serial port and press Open button to start optional serial communication

## Usage

- Start the app using the provided executable.
- Free MIDI devices on user's PC will be automatically be used by the app
- Change Color, led control specific parameters & start optional serial communication
- Add the PianoLux window to Recording Software of choice, OBS is recommended, layer webcam/video capture device
- Record/Stream
- Have fun!

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

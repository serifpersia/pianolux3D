<div align="center">
  
![pianolux_logo](https://github.com/serifpersia/pianolux-esp32/assets/62844718/41b64e47-2d2b-4114-b2ca-05d3ef084215)

<h1><span class="piano-text" style="color: white;">PianoLux3D</span></h1> 

  [![Release](https://img.shields.io/github/release/serifpersia/pianolux-godot.svg?style=flat-square)](https://github.com/serifpersia/pianolux-godot/releases)
  [![License](https://img.shields.io/github/license/serifpersia/pianolux-godot?color=blue&style=flat-square)](https://raw.githubusercontent.com/serifpersia/pianolux-godot/master/LICENSE)
  [![Discord](https://img.shields.io/discord/1077195120950120458.svg?colorB=blue&label=discord&style=flat-square)](https://discord.gg/MAypyD7k86)
</div>

PianoLux3D is Godot Game Engine port of PianoLux Java and ESP32 versions of the application. Midi visualization and WS2812B led strip controller application.

Supports Windows, Linux and MacOS x64 bit

*MacOS LED Strip control only via network(esp32) devices since serial library used by the project doesnt have MacOS version serial connection isn't supported on MacOS.

![image](https://github.com/user-attachments/assets/6a532e6a-6f25-4389-82c1-04f52caa7a41)

## Demo
<div align="center">
  
https://github.com/user-attachments/assets/9e596e92-1543-4f85-b95d-3ffbcf5fbea2

</div>

## Join Our Community

Be part of the PianoLux Discord Server Community where you can connect with fellow users, ask questions, and share your experiences:

[![Discord Server](https://discordapp.com/api/guilds/1077195120950120458/widget.png?style=banner2)](https://discord.gg/MAypyD7k86)

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
* You can send midi and led control commands over wifi if you use esp32 arduino code(initial wifi setup required after upload, instructions are inside esp32 version of the arduino code)
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


## Compile
To be able to compile for arduino only install FastLED 3.7.0
For ESP32 run install_libs.bat/.sh files to auto install libs needed
*Modify ElegantOTA.h file in this lib's src directory change #define ELEGANTOTA_USE_ASYNC_WEBSERVER 0 to 1
By default NEOPIXEL/WS2812B strip is used, change USE_NEOPIXEL_STRIP to 0 to use custom strip by uncommenting specific led strip code line

## Auto Install
You can auto install esp32 firmware by going to auto install [page](https://serifpersia.github.io/pianolux3D/) on any chromium based web browsers(Google Chrome, Brave, Edge...)

## Usage

- Start the app using the provided executable.
- Free MIDI devices on user's PC will be automatically be used by the app
- Change Color, led control specific parameters & start optional serial communication
- Add the PianoLux window to Recording Software of choice, OBS is recommended, layer webcam/video capture device
- Record/Stream
- Have fun!

## Loading the Godot Project

To get started with the project, follow these steps:

1. **Requirements**: Ensure you have Godot 4.2 installed. You will also need the following addons:
   - [Serial](https://github.com/matrixant/serial_port/releases/tag/v0.1.0)
   - [Discord-RCP](https://github.com/vaporvee/discord-rpc-godot/releases)

2. **Addons Installation**:
   - Download the addons and extract the zip files into the `addons` directory of your Godot project.
   - Your folder structure should look like this:
     ```
     PianoLux Godot project/
     └── addons/
         ├── serialports/
         └── discord-rcp/
     ```

3. **Configuration**:
   - The SerialPorts addon does not require any additional setup.
   - For the Discord-RCP addon, enable it by navigating to `Project Settings > Plugins` in Godot.

4. **Directory Setup**:
   - If the `addons` directory does not exist, create it manually.
   - Note that this directory is included in the `.gitignore` by default to keep the repository as clean as possible. You will need to create this directory and add the necessary addons yourself.


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

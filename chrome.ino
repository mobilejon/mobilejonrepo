/*
  Copyright (c) 2020, Amplified IT
  See the full description at http://labs.amplifiedit.com/centipede

  Support forums are available at https://plus.google.com/communities/100599537603662785064

  Published under an MIT License https://opensource.org/licenses/MIT

*/

#include <Keyboard.h>

/* Modify the following definitions to fit your wireless and enrollment credentials. */

#define device_version 83 // Change to the ChromeOS version you expect to use with Centipede; Changes have been reported in the following ranges 58-68, 69, 70
#define powerwash 0 //[0,1] Set to 0 after confirmation that script works through the enrollment process (Default 1).  
//Powerwash the device BEFORE enrollment is completed - NOTE: Will not work on ENROLLED devices. Used for Setting up Centipede.

#define wifi_name "" // Define SSID for your wireless connection.
#define wifi_pass "" // Define the password for your wireless connection.
#define wifi_security 2 //[0,1,2] Set to 0 for open, 1 for WEP, 2 for WPA
#define username "" // Define the user name for enrolling the device.
#define ssousername ""
#define password "" // The password for the enrollment GAFE account.

// Use these options to determine if you want to disable analytics, skip asset ID, or if you need to slow down the Centipede

#define sendUsageToGoogle 0   //[0,1] Set to 0 if you want to un-check the box to send usage analytics to Google
#define shutdown_when_finished 0 //[0,1] Set to 0 if you want Centipede to stop at the asset ID and location screen
#define selected_on_boot 3
//[0,1,2,3]  Active location when device poweron : 3 - "Let's go"(Default), 2 - accessibility, 1 - language, 0 - menu 

/* These are advanced options. The defaults should be fine, but feel free to tweak values below. */

#define setWiFi true //[true,false] Set to false for devices that already have WiFi setup and have accepted Terms of Service (ToS) 

// Use this area for advanced network setup options
#define advancedNetworkSetup false //[true,false] Set to true for EAP configuration, and fill out the definitions below
#define eapMethod "LEAP" // Valid options are "LEAP" "PEAP" "EAP-TLS" or "EAP-TTLS" - Note that they require the quotes to work properly
#define phaseTwoAuthentication 2 //[0,1,2,3,4,5,6] Set to 0 for automatic, 1 for EAP-MD5, 2 for MSCHAP(v2 pre v69; v1 V69+, 3 for MSCHAPv2, 4 for PAP, 5 for CHAP, 6 for GTC; v69+)
#define serverCaCertificateCheck 0 //[0,1] 0 is default, 1 is "Do not check"
#define subjectMatch "" // Fill in subject match here if needed for advanced wireless
#define identity "identity" // Fill in identity here if needed for advanced wireless
#define anonymousIdentity "" // Fill in anonymous identity here for advanced wireless
#define saveIdentityAndPassword 0 //[0,1] Set to 1 to save identity and password. NOT RECOMMENDED
#define sso 1 //[0,1] Set to 1 if using Single Sign On - NOTE: May need additional configuration in Advanced Network Setup around line 182.

// Use this section for additional non-traditional methods
#define longer_enrollment_time 0 // Set to additional seconds to wait for Device Configuration and Enrollment
#define sign_in 1 //[0,1] Set to 1 to sign-in to the device after enrollment
#define remove_enrollment_wifi 1 //[0,1] Set to 1 to remove the enrollment wifi network. *sign_in also must be true* - NOTE: Only set to true when Chrome Device Network has been pulled down
#define enroll_device_cert 0 //[0,1] Set to 1 if enrolling device wide certificate *sign_in also must be true* - NOTE: Works best if user _*only*_ has Certificate Enrollment extension force installed

#define slowMode 0 // [0,1] Set to 1 if Centipede appears to be moving too quickly at any screen. This will slow down the entire process
#define update_wait_time 15 // Set to seconds to wait for mandatory updates to be downloaded

/* Do not modify anything below this line unless you're confident that you understand how to program Arduino or C */

// Version Definition
#define VERSION_69 (device_version >= 69)
#define VERSION_70 (device_version >= 70)
#define VERSION_78 (device_version >= 78)
#define VERSION_83 (device_version >= 83)

// Special characters definition
#define KEY_LEFT_CTRL   0x80
#define KEY_LEFT_SHIFT  0x81
#define KEY_LEFT_ALT    0x82
#define KEY_RIGHT_CTRL  0x84
#define KEY_RIGHT_SHIFT 0x85
#define KEY_RIGHT_ALT   0x86
#define KEY_UP_ARROW    0xDA
#define KEY_DOWN_ARROW  0xD9
#define KEY_LEFT_ARROW  0xD8
#define KEY_RIGHT_ARROW 0xD7
#define KEY_BACKSPACE   0xB2
#define KEY_TAB         0xB3
#define KEY_ENTER       0xB0
#define KEY_ESC         0xB1
#define KEY_CAPS_LOCK   0xC1

int buttonPin = 2;  // Set a button to any pin
int RXLED = 17;
static uint8_t __clock_prescaler = (CLKPR & (_BV(CLKPS0) | _BV(CLKPS1) | _BV(CLKPS2) | _BV(CLKPS3)));

void setup()
{
  setPrescaler(); // Set prescaler to highest clock speed
  Keyboard.begin(); // Start they keyboard emulator
  pinMode(buttonPin, INPUT);  // Set up the debugging pin. If you want to debug the code, use a length of wire to connect pins 2 and GND on the board
  digitalWrite(buttonPin, HIGH);

  pinMode(RXLED, OUTPUT); // Configure the on-board LED
  digitalWrite(RXLED, LOW);
  TXLED1;
  if (digitalRead(buttonPin) == 0) {
    showSuccess();
  }
  wait(5); // Wait for all services to finish loading
}

void loop() { // Main Function - workflow is called within loop();
  if (digitalRead(buttonPin) == 1 ) { // Check for debugging. If not debugging, run the program
    showVersion();
    enterEnrollment();
    if (setWiFi){
      wifiConfig(); // Enter the wifi configuration method (written down below)
      welcomeScreen();
      ToS(); // Accept Terms of Service
    }   
    TXLED1; // Toggle the TX on-board LED
    wait(15 + longer_enrollment_time); // Wait device to download configuration
    while (digitalRead(buttonPin) != 1) {
      bootLoop();
    }
    TXLED0;
    
    wait(update_wait_time); // wait for device to update
    enterCredentials(); // Max progress with powerwash set to true - Will Powerwash after typing the password but before submitting
    wait(35); // wait for Enrollment to complete
    Keyboard.write(KEY_ENTER);
    wait(35);
    enterCredentials();
  Keyboard.write(KEY_TAB);
  Keyboard.write(KEY_TAB);
  Keyboard.write(KEY_ENTER);
  wait(5);
  Keyboard.write(KEY_TAB);
  Keyboard.write(KEY_ENTER);
    showSuccess();
  }
  bootLoop();
}

void bootLoop() {
  //      digitalWrite(RXLED, LOW);   // set the LED on
  TXLED0; //TX LED is not tied to a normally controlled pin
  delay(200);              // wait for a second
  TXLED1;
  delay(200);
  TXLED0; //TX LED is not tied to a normally controlled pin
  delay(200);              // wait for a second
  TXLED1;
  delay(800);
}

void showSuccess() {
  digitalWrite(RXLED, HIGH);  // set the LED off
  while (true) {
    bootLoop();
  }
}

void repeatKey(byte key, int num) {
  for (int i = 0; i < num; i++) {
    Keyboard.write(key);
    wait(2);
  }
}

void blink() {
  digitalWrite(RXLED, LOW);
  //  TXLED1;
  delay(250);
  digitalWrite(RXLED, HIGH);
  //  TXLED0;
  delay(250);
}

void wait(int cycles) {
  for (int i = 0; i < cycles; i++) {
    blink();
    if (slowMode) {
      delay(250);
    }
  }
}

void enterCredentials() {
  wait(15);
  Keyboard.print(username);
  wait(3);
  Keyboard.write(KEY_ENTER);
  wait(20);
   Keyboard.print(ssousername);
   Keyboard.write(KEY_TAB);
   Keyboard.print(password);
   Keyboard.write(KEY_ENTER);
   wait(2);
  wait(3);
  wait(30);
}


void enterEnrollment() {
  Keyboard.press(KEY_LEFT_CTRL);
  Keyboard.press(KEY_LEFT_ALT);
  Keyboard.write('e');
  Keyboard.release(KEY_LEFT_ALT);
  Keyboard.release(KEY_LEFT_CTRL);
  wait(1);
}

void ToS(){
// Terms of Service screen //Changed in v78
  wait(2);
  if(VERSION_83){
    Keyboard.press(KEY_LEFT_SHIFT);
    wait(2);
  }
  repeatKey(KEY_TAB, 2 + VERSION_83);
  if(VERSION_83){
    Keyboard.release(KEY_LEFT_SHIFT);
    wait(2);
  }
  if (!sendUsageToGoogle) {
    Keyboard.write(KEY_ENTER);
    wait(2);
  }
  repeatKey(KEY_TAB, 3);
  wait(2);
  Keyboard.write(KEY_ENTER);
}

void wifiConfig() {
  // Access the Network option from the system tray (Status Area).
  Keyboard.press(KEY_LEFT_SHIFT);
  Keyboard.press(KEY_LEFT_ALT);
  Keyboard.write('s');
  Keyboard.release(KEY_LEFT_ALT);
  Keyboard.release(KEY_LEFT_SHIFT);
  wait(2);
  //to select the Network
  repeatKey(KEY_TAB, 3 + VERSION_70);  // 3 for pre v70, 4 for ver 70 (black menu)
  wait(1);
  Keyboard.write(KEY_ENTER);
  wait(1);
  //to select the 'add Wifi' icon
  repeatKey(KEY_TAB, 3);
  Keyboard.write(KEY_ENTER);
  wait(2);
  // SSID
  Keyboard.print(wifi_name);
  wait(1);
  // TAB
  Keyboard.write(KEY_TAB);
  wait(1);
  if (wifi_security == 0) {
    repeatKey(KEY_TAB, 2);
  } else {
      if (advancedNetworkSetup) {
        setupAdvancedNetworkConfig();
      }
      else{
        repeatKey(KEY_DOWN_ARROW, wifi_security); //[1]WEP, [2]PSK (WPA or RSN), [3]EAP;
      
    // TAB
    Keyboard.write(KEY_TAB); //[1,2]password, [3]EAP method;
    wait(1);
    // type wifi password
    Keyboard.print(wifi_pass);
    repeatKey(KEY_TAB, 3);
   }
  }
  wait(1);
  // Enter
  Keyboard.write(KEY_ENTER); // Connect
  // Delay 15 seconds to connect
  wait(15);
}

void welcomeScreen() {
  repeatKey(KEY_TAB, 3 - selected_on_boot);
  wait(2);
  Keyboard.write(KEY_ENTER); // Click "Let's Go"
  wait(1);
  if (!VERSION_78){
    repeatKey(KEY_TAB, 2 + VERSION_70); // 3 for version 70+ (black menu)
  // After connecting, enter the enrollment key command to skip checking for update at this point in the process
  }
  enterEnrollment();
  wait(1);
  Keyboard.write(KEY_ENTER); // Click "Next"
}

void shutDown() { // Shutdown if not signed in, Sign out if signed in
  // Access the Network option from the system tray (Status Area).
  Keyboard.press(KEY_LEFT_SHIFT);
  Keyboard.press(KEY_LEFT_ALT);
  Keyboard.write('s');
  Keyboard.release(KEY_LEFT_ALT);
  Keyboard.release(KEY_LEFT_SHIFT);
  wait(2);
  repeatKey(KEY_TAB, 1 + sign_in);
  repeatKey(KEY_ENTER, 1);
}

void setupAdvancedNetworkConfig() {
  //Starting at Security box
  if (VERSION_69 == 1){
    repeatKey(KEY_DOWN_ARROW, 3); // Select Security "EAP" (v69);
        Keyboard.write(KEY_TAB);
  }else{
    //ARROW_DOWN x3 WEP, PSK, EAP
    repeatKey(KEY_TAB, 2);
    Keyboard.write(KEY_ENTER);
    wait(1);
    //SSID (again);
    Keyboard.print(wifi_name);
    Keyboard.write(KEY_TAB);
    //@EAP Method
  }

  if (eapMethod == "LEAP") {
    // Default is LEAP v69+
    repeatKey(KEY_DOWN_ARROW, 1 - VERSION_69);
    Keyboard.write(KEY_TAB);
    // Identity
    Keyboard.print(identity);
    Keyboard.write(KEY_TAB);
    wait(1);
    Keyboard.print(wifi_pass);
    repeatKey(KEY_TAB, 2);
    wait(1);
    Keyboard.write(KEY_ENTER); // Save Identity and Password (true);
    repeatKey(KEY_TAB, 2);
    Keyboard.write(KEY_ENTER); // Connect;
  } else if (eapMethod == "PEAP") {
    // Select PEAP method
    repeatKey(KEY_DOWN_ARROW, 2 - VERSION_69);
    Keyboard.write(KEY_TAB);
    wait(1);
    // EAP Phase 2 authentication
    // If phase two authentication is defined, select it
    if (phaseTwoAuthentication) {
      repeatKey(KEY_DOWN_ARROW, phaseTwoAuthentication); // [0]Automatic, [1]EAP-MD5, [2]MSCHAP(v2 pre-v69;v1 v69+, [3]MSCHAPv2, [4]PAP, [5]CHAP, [6]GTC : v69)
    }
    Keyboard.write(KEY_TAB);
    // Server CA Certificate
    if (serverCaCertificateCheck) {
      Keyboard.write(KEY_DOWN_ARROW);//change to "DO NOT CHECK"
    }
    Keyboard.write(KEY_TAB);

    // Identity
    Keyboard.print(identity);
    Keyboard.write(KEY_TAB);
    wait(1);
    Keyboard.print(wifi_pass);
    repeatKey(KEY_TAB, 2);

    // Anonymous Identity
    Keyboard.print(anonymousIdentity);
    Keyboard.write(KEY_TAB);
    Keyboard.write(KEY_ENTER); //Save ID and PW
    repeatKey(KEY_TAB, 1 + VERSION_69); //End on Connect  /v69+
  } else if (eapMethod ==  "EAP-TLS") {
    // Select EAP-TLS method
    repeatKey(KEY_DOWN_ARROW, 2);
    Keyboard.write(KEY_TAB);
    //EAP Phase 2 authentication
    // If phase two authentication is defined, select it
    if (phaseTwoAuthentication) {
      repeatKey(KEY_DOWN_ARROW, phaseTwoAuthentication); // [0]Automatic, [1]EAP-MD5, [2]MSCHAP(v2 pre-v69;v1 v69+, [3]MSCHAPv2, [4]PAP, [5]CHAP, [6]GTC : v69)
    }
    Keyboard.write(KEY_TAB);
    // Server CA Certificate
    if (serverCaCertificateCheck) {
      Keyboard.write(KEY_DOWN_ARROW); // Change to "DO NOT CHECK"
    }
    Keyboard.write(KEY_TAB);

    // Subject match
    Keyboard.print(subjectMatch);
    Keyboard.write(KEY_TAB);

    // Identity
    Keyboard.print(identity);
    repeatKey(KEY_TAB, 3);

  } else if (eapMethod == "EAP-TTLS") {
    repeatKey(KEY_DOWN_ARROW, 4);
    Keyboard.write(KEY_TAB);

    // If phase two authentication is defined, select it
    if (phaseTwoAuthentication) {
      repeatKey(KEY_DOWN_ARROW, phaseTwoAuthentication);
    }
    Keyboard.write(KEY_TAB);

    // Server CA Certificate
    if (serverCaCertificateCheck) {
      Keyboard.write(KEY_DOWN_ARROW);
    }

    // Identity
    Keyboard.print(identity);
    Keyboard.write(KEY_TAB);
    Keyboard.print(wifi_pass);
    repeatKey(KEY_TAB, 2);

    // Anonymous Identity
    Keyboard.print(anonymousIdentity);
    repeatKey(KEY_TAB, 2);
  } else if (eapMethod ==  "EAP-TLS") {
    // Select EAP-TLS method
    repeatKey(KEY_DOWN_ARROW, 3);
    Keyboard.write(KEY_TAB);

    // Server CA Certificate
    if (serverCaCertificateCheck) {
      Keyboard.write(KEY_DOWN_ARROW);
    }
    Keyboard.write(KEY_TAB);

    // Subject match
    Keyboard.print(subjectMatch);
    Keyboard.write(KEY_TAB);

    // Identity
    Keyboard.print(identity);
    repeatKey(KEY_TAB, 3);

    // Anonymous Identity
    Keyboard.print(anonymousIdentity);
    repeatKey(KEY_TAB, 2);
  }
}

void reloadPolicies(){
  wait(3);
  newTab();
  Keyboard.print("chrome://policy");
  Keyboard.write(KEY_ENTER);
  wait(2);
  repeatKey(KEY_TAB, 1);
  wait(1);
  Keyboard.write(KEY_ENTER);
  wait(1);
  closeTab();
}

void removeEnrollmentWifi(){
  wait(7);
  reloadPolicies();
  newTab();
  Keyboard.print("chrome://settings/knownNetworks?type=WiFi");
  Keyboard.write(KEY_ENTER);
  wait(5);
  repeatKey(KEY_TAB, 3); // Select the Top Network's "More options"
  wait(1);
  Keyboard.write(KEY_ENTER);
  wait(2);
  repeatKey(KEY_DOWN_ARROW, 3); // Select "Forget";
  wait(2);
  Keyboard.write(KEY_ENTER);
  wait(5);
  closeTab();
}

void newTab(){
  Keyboard.press(KEY_RIGHT_CTRL);
  Keyboard.print("n");
  wait(1);
  Keyboard.release(KEY_RIGHT_CTRL);
  wait(2);
}
void closeTab(){
  Keyboard.press(KEY_RIGHT_CTRL);
  Keyboard.print("w");
  wait(1);
  Keyboard.release(KEY_RIGHT_CTRL);
  wait(1);
}
void showVersion(){
  Keyboard.press(KEY_RIGHT_ALT);
  Keyboard.print("v");
  wait(1);
  Keyboard.release(KEY_RIGHT_ALT);
}
void Powerwash(){
  Keyboard.press(KEY_RIGHT_SHIFT);
  Keyboard.press(KEY_RIGHT_CTRL);
  Keyboard.press(KEY_RIGHT_ALT);
  Keyboard.print("r");
  wait(1);
  Keyboard.release(KEY_RIGHT_SHIFT);
  Keyboard.release(KEY_RIGHT_CTRL);
  Keyboard.release(KEY_RIGHT_ALT);
  wait(1);
  if(VERSION_78){
    Keyboard.write(KEY_TAB);
    wait(1);
  }
  Keyboard.write(KEY_ENTER);
  wait(2);
  Keyboard.write(KEY_TAB);
  Keyboard.write(KEY_ENTER);
}
void certificateEnrollment() {
  wait(5);
  repeatKey(KEY_TAB, 2);
  Keyboard.print(username); //Enter Username for Certificate Enrollment
  Keyboard.write(KEY_TAB);
  wait(1);
  Keyboard.print(password); //Enter Password for Certificate Enrollment
  Keyboard.write(KEY_TAB);
  wait(1);
  Keyboard.write(KEY_ENTER); //Enable Device Wide certificate for Certificate Enrollment
  wait(1);
  repeatKey(KEY_TAB, 4);
  wait(1);
  Keyboard.write(KEY_ENTER);
  wait(40);
}
void setPrescaler() {
  // Disable interrupts.
  uint8_t oldSREG = SREG;
  cli();

  // Enable change.
  CLKPR = _BV(CLKPCE); // write the CLKPCE bit to one and all the other to zero

  // Change clock division.
  CLKPR = 0x0; // write the CLKPS0..3 bits while writing the CLKPE bit to zero

  // Copy for fast access.
  __clock_prescaler = 0x0;

  // Recopy interrupt register.
  SREG = oldSREG;
}

//TODO:
#define in_developer_mode 0 // Set to 1 if device is in developer mode 


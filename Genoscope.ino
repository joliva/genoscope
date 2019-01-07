#include <ESP8266WiFi.h>
#include <ESP8266mDNS.h>
#include <WiFiUdp.h>
#include <ArduinoOTA.h>

#include <FastLED.h>
#include <LEDMatrix.h>

#include <Ticker.h>

// --------------------------------------------------------------------------

// forward declarations
void anim1_loop(void);
void anim2_loop(void);
void anim3_loop(void);
void anim4_loop(void);
void anim5_loop(void);

// *** LEDMatrix config - Start
#define DATA_PIN 6
#define COLOR_ORDER     GRB
#define CHIPSET         WS2812B

#define MATRIX_WIDTH    4
#define MATRIX_HEIGHT   6
#define MATRIX_TYPE     HORIZONTAL_ZIGZAG_MATRIX
#define MATRIX_SIZE     (MATRIX_WIDTH*MATRIX_HEIGHT)
#define NUMPIXELS       MATRIX_SIZE
// *** LEDMatrix config - End

cLEDMatrix<MATRIX_WIDTH, -MATRIX_HEIGHT, MATRIX_TYPE> Leds;

#define ANIM_TIME 45.0
#define BASE_VAL 120

void (*anims[])(void) = {anim1_loop, anim2_loop, anim4_loop, anim5_loop};
//void (*anims[])(void) = {anim5_loop};
unsigned char anim_idx = 0;
size_t num_anims = sizeof(anims) / sizeof(anims[0]);
void (*cur_anim)(void) = anims[anim_idx];

// --------------------------------------------------------------------------

void setup_app() {
  static Ticker ticker;

  Serial.begin(230400);
  Serial.println("Booting");

  FastLED.setMaxPowerInVoltsAndMilliamps(5,1200);
  
  // initial FastLED by using CRGB led source from our matrix class
  FastLED.addLeds<CHIPSET, DATA_PIN, COLOR_ORDER>(Leds[0], Leds.Size()).setCorrection(TypicalSMD5050);
  FastLED.setBrightness(BASE_VAL);
  FastLED.clear(true);

  ticker.attach(ANIM_TIME, update_anim); // 5sec period
}

// --------------------------------------------------------------------------

void setup_wifi() {
  const char* ssid = "Carrots";
  const char* password = "Happiness";

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  
  while (WiFi.waitForConnectResult() != WL_CONNECTED) {
    Serial.println("Connection Failed! Rebooting...");
    delay(5000);
    ESP.restart();
  }

  // Port defaults to 8266
  // ArduinoOTA.setPort(8266);

  // Hostname defaults to esp8266-[ChipID]
  // ArduinoOTA.setHostname("myesp8266");

  // No authentication by default
  // ArduinoOTA.setPassword("admin");

  // Password can be set with it's md5 value as well
  // MD5(admin) = 21232f297a57a5a743894a0e4a801fc3
  // ArduinoOTA.setPasswordHash("21232f297a57a5a743894a0e4a801fc3");

  ArduinoOTA.onStart([]() {
    String type;
    if (ArduinoOTA.getCommand() == U_FLASH) {
      type = "sketch";
    } else { // U_SPIFFS
      type = "filesystem";
    }

    // NOTE: if updating SPIFFS this would be the place to unmount SPIFFS using SPIFFS.end()
    Serial.println("Start updating " + type);
  });
  
  ArduinoOTA.onEnd([]() {
    Serial.println("\nEnd");
  });
  
  ArduinoOTA.onProgress([](unsigned int progress, unsigned int total) {
    Serial.printf("Progress: %u%%\r", (progress / (total / 100)));
  });
  
  ArduinoOTA.onError([](ota_error_t error) {
    Serial.printf("Error[%u]: ", error);
    if (error == OTA_AUTH_ERROR) {
      Serial.println("Auth Failed");
    } else if (error == OTA_BEGIN_ERROR) {
      Serial.println("Begin Failed");
    } else if (error == OTA_CONNECT_ERROR) {
      Serial.println("Connect Failed");
    } else if (error == OTA_RECEIVE_ERROR) {
      Serial.println("Receive Failed");
    } else if (error == OTA_END_ERROR) {
      Serial.println("End Failed");
    }
  });
  
  ArduinoOTA.begin();
  Serial.println("Ready");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

// --------------------------------------------------------------------------

void update_anim() {
  anim_idx++;
  if (anim_idx == num_anims) anim_idx = 0;
  cur_anim = anims[anim_idx];
  FastLED.clear();
}

// --------------------------------------------------------------------------

void anim1_loop() {
  #define VAL BASE_VAL
  #define SAT 255
  #define DELTAC 20
  #define DELAY 20

  static bool initialized = false;
  static unsigned char color[NUMPIXELS];

  if (!initialized) {
    for (int i=0; i<NUMPIXELS; i++) {
      color[i] = i*DELTAC;
    }
    
    initialized = true;
  }
  
  for (int i=0; i<NUMPIXELS; i++)
      *Leds[i]=CHSV(color[i], SAT, VAL);
  
  FastLED.show();
  delay(DELAY);
      
  for (int i=0; i<NUMPIXELS; i++) {
      color[i] += 7;
  }
}

// --------------------------------------------------------------------------

void anim2_loop() {
  #define VAL BASE_VAL
  #define SAT 255
  #define DELAY 100
  #define STATE_UP 0
  #define STATE_DOWN 1
  #define DELTAC 12

  const int DELTA_V = int(floor(VAL*1.0/18));

  static unsigned char colors[NUMPIXELS], color;
  static int idx=0;
  static bool initialized = false;
  static unsigned char state=STATE_UP;

  if (!initialized) {
    FastLED.clear();
    color = 0;
    initialized = true;
  }

  if (state == STATE_UP) {
    color += DELTAC;
    colors[idx] = color;
    *Leds[idx]=CHSV(colors[idx], SAT, VAL);
    for (int i=idx-1; i>=0; i--) {
      *Leds[i] = CHSV(colors[i], SAT, constrain(VAL + (i-idx)*DELTA_V,0,255));
    }
    idx++;

    FastLED.show();
    delay(DELAY);
  
    if (idx == NUMPIXELS) {
      idx = NUMPIXELS - 2;
      FastLED.clear();
      state = STATE_DOWN;
    }
  } else if (state == STATE_DOWN) {
    color += DELTAC;
    colors[idx] = color;
    *Leds[idx]=CHSV(colors[idx], SAT, VAL);
    for (int i=idx+1; i<NUMPIXELS; i++) {
      *Leds[i] = CHSV(colors[i], SAT, constrain(VAL + (idx-i)*DELTA_V,0,255));
    }
    idx--;

    FastLED.show();
    delay(DELAY);
  
    if (idx == -1) {
      idx = 1;
      state = STATE_UP;
      FastLED.clear();
    }
  } else {
    idx=0; state = STATE_UP;
  }
}

// --------------------------------------------------------------------------

void anim3_loop() {
  #define VAL BASE_VAL
  #define SAT 255
  #define DELTAC 5
  #define DELAY 10

  static bool initialized = false;
  static unsigned char color = 0;

  if (!initialized) {
    FastLED.clear();    
    initialized = true;
  }
  
  for (int i=0; i<NUMPIXELS; i++) {
    *Leds[i]=CHSV(color, SAT, VAL);
  }
  
  FastLED.show();
  delay(DELAY);
      
  color += 1;
}

// --------------------------------------------------------------------------

void anim4_loop() {
  #define VAL BASE_VAL
  #define SAT 255
  #define DELTAC 7
  #define DELAY 50

  int16_t x=random8(MATRIX_WIDTH),y=random8(MATRIX_HEIGHT),r=random8(2);
  int8_t h=random8();
  Leds.DrawFilledCircle(x,y,r,CHSV(h,SAT,VAL));
  
  FastLED.show();
  delay(DELAY);
}

// --------------------------------------------------------------------------

void anim5_loop() {
  #define VAL BASE_VAL
  #define SAT 255
  #define DELTAC 7
  #define DELAY 30
  #define DTHETA (256*DELAY/3000)

  static int angle = 0;
  static uint8_t hue = 0;

  int16_t v = VAL*sin8(angle)/255;

  for (int i=0; i<NUMPIXELS; i++) {
    *Leds[i] = CHSV(hue,SAT,v);
  }

  angle = (angle+DTHETA)%256;
  hue++;
  
  FastLED.show();
  delay(DELAY);
}

// --------------------------------------------------------------------------

void setup() {
  setup_app();
  setup_wifi();
}

// --------------------------------------------------------------------------

void loop() {
  ArduinoOTA.handle();
  cur_anim();
}
// --------------------------------------------------------------------------

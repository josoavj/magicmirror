#include "WiFi.h"
#include "esp_camera.h"
#include "HTTPClient.h"

// WIFI
const char* ssid = "YOUR_WIFI";
const char* password = "YOUR_PASSWORD";

// API endpoint
const char* serverUrl = "http://your-api.com/upload";

// Configuration caméra (ESP32-CAM AI Thinker)
camera_config_t config;

void setupCamera() {
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = 5;
  config.pin_d1 = 18;
  config.pin_d2 = 19;
  config.pin_d3 = 21;
  config.pin_d4 = 36;
  config.pin_d5 = 39;
  config.pin_d6 = 34;
  config.pin_d7 = 35;
  config.pin_xclk = 0;
  config.pin_pclk = 22;
  config.pin_vsync = 25;
  config.pin_href = 23;
  config.pin_sscb_sda = 26;
  config.pin_sscb_scl = 27;
  config.pin_pwdn = 32;
  config.pin_reset = -1;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;

  config.frame_size = FRAMESIZE_VGA;
  config.jpeg_quality = 10;
  config.fb_count = 1;

  esp_camera_init(&config);
}

void connectWiFi() {
  WiFi.begin(ssid, password);
  Serial.print("Connexion WiFi...");
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nConnecté !");
}

void sendImage() {
  camera_fb_t * fb = esp_camera_fb_get();

  if (!fb) {
    Serial.println("Erreur capture image");
    return;
  }

  HTTPClient http;
  http.begin(serverUrl);
  http.addHeader("Content-Type", "image/jpeg");

  int response = http.POST(fb->buf, fb->len);

  Serial.print("Réponse serveur : ");
  Serial.println(response);

  http.end();
  esp_camera_fb_return(fb);
}

void setup() {
  Serial.begin(115200);
  connectWiFi();
  setupCamera();
}

void loop() {
  sendImage();
  delay(10000); // envoi toutes les 10 secondes
}
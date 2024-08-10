#include <WiFi.h>
#include <WiFiClient.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <EEPROM.h>
#include <mbedtls/md.h>
#define n 2
const int PINS[2] = { 22, 23 };

JsonDocument doc;

const char* ssid = "xyz";
const char* password = "xyz";
const int roomid = 543;
int deviceid[2]={89,90};
int status[n];

const char* macAddress = "E8:68:E7:2E:BA:58";
char macHashStr[65];

const char* server_address_devices_template = "xyz";

void setup() {
  for (int i = 0; i < n; i++) {
    pinMode(PINS[i], OUTPUT);
  }
  pinMode(2, OUTPUT);
  Serial.begin(115200);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    //Serial.println("Connecting to WiFi...");
  }
  if (WiFi.status() == WL_CONNECTED) {
    digitalWrite(2, HIGH);
  }
  //Serial.println("Connected to WiFi");

  // Create a SHA256 hash of the MAC address
  unsigned char sha256Result[32];
  mbedtls_md_context_t ctx;
  mbedtls_md_init(&ctx);
  mbedtls_md_setup(&ctx, mbedtls_md_info_from_type(MBEDTLS_MD_SHA256), 0);
  mbedtls_md_starts(&ctx);
  mbedtls_md_update(&ctx, (const unsigned char*)macAddress, strlen(macAddress));
  mbedtls_md_finish(&ctx, sha256Result);
  mbedtls_md_free(&ctx);

  // Convert hash to a string
  for (int i = 0; i < 32; i++) {
    sprintf(&macHashStr[i * 2], "%02x", sha256Result[i]);
  }
  //Serial.println();
}

void loop() {
  char server_address_devices[200];
  snprintf(server_address_devices, sizeof(server_address_devices), server_address_devices_template, roomid, macHashStr);
  // Get device list from the server
  getDataFromServer(server_address_devices, true);

  for (int i = 0; i < n; i++) {
    if (status[i] == 2) {
      digitalWrite(PINS[i], LOW);
    } else if (status[i] == 1) {
      digitalWrite(PINS[i], HIGH);
    }
  }
  delay(1000);
}

void getDataFromServer(const char* server_address, bool isDeviceList) {
  HTTPClient client;

  //Serial.print("Connecting to server at: ");
  //Serial.println(server_address);

  client.begin(server_address);

  int httpResponseCode = client.GET();

  if (httpResponseCode > 0) {
    //Serial.print("Server responded with code: ");
    //Serial.println(httpResponseCode);

    if (httpResponseCode == HTTP_CODE_OK) {
      String response = client.getString();
      //Serial.println("Response: " + response);

      // Parse the JSON response
      JsonObject root = doc.to<JsonObject>();
      DeserializationError error = deserializeJson(doc, response);

      if (error) {
        Serial.print("Failed to parse JSON: ");
        Serial.println(error.c_str());
        return;
      }
      if (isDeviceList) {
        // Parse device list
        JsonArray array = doc.as<JsonArray>();
        for (int i = 0; i < array.size() && i < n; i++) {
          if(deviceid[i]==array[i]["device_id"])
          {
            status[i] = array[i]["state"];
          }
        }
      } else {
        // Parse status
        JsonObject obj = doc.as<JsonObject>();
        int receivedDeviceId = obj["device_id"];
        int receivedStatus = obj["state"];

        // Find the corresponding device and update its status
        for (int i = 0; i < n; i++) {
          if (deviceid[i] == receivedDeviceId) {
            status[i] = receivedStatus;
            break;
          }
        }
      }
    }
  } else {
    Serial.print("Error in GET request. HTTP response code: ");
    Serial.println(httpResponseCode);
  }
  client.end();
}

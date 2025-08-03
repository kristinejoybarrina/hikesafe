// Common includes
#include <SPI.h>
#include <LoRa.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define LORA_FREQ 915E6
#define SERVICE_UUID        "12345678-1234-1234-1234-1234567890ab"
#define CHAR_UUID           "87654321-4321-4321-4321-ba0987654321"

// Set ROLE_TX=true on A, false on B
#define ROLE_TX true

BLECharacteristic *audioChar;

class AudioCallbacks: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *c) {
    std::string data = c->getValue();
    if (ROLE_TX) {
      LoRa.beginPacket();
      LoRa.write((uint8_t*)data.data(), data.size());
      LoRa.endPacket();
    }
  }
};

void setup(){
  Serial.begin(115200);
  LoRa.begin(LORA_FREQ);
  BLEDevice::init("LoRaAudio");
  BLEServer *srv = BLEDevice::createServer();
  BLEService *svc = srv->createService(SERVICE_UUID);
  audioChar = svc->createCharacteristic(CHAR_UUID,
                      ROLE_TX ? BLECharacteristic::PROPERTY_WRITE : BLECharacteristic::PROPERTY_NOTIFY);
  audioChar->addDescriptor(new BLE2902());
  if (ROLE_TX) {
    audioChar->setCallbacks(new AudioCallbacks());
  }
  svc->start();
  BLEDevice::startAdvertising();
  Serial.println(ROLE_TX ? "TX BLE ready" : "RX BLE ready");
}

void loop(){
  if (!ROLE_TX) {
    int sz = LoRa.parsePacket();
    if (sz) {
      uint8_t buf[sz];
      LoRa.readBytes(buf, sz);
      audioChar->setValue(buf, sz);
      audioChar->notify();
    }
  }
  delay(10);
}

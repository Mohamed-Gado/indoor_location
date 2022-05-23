import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'models/beacon_info.dart';
import 'UmbrellaBeaconTools/beacon_tools.dart';

final _random = Random();

// Used in main.dart
int randomNumber(int min, int max) => min + _random.nextInt(max - min);

// Used in beacon_tools.dart
int byteToInt8(int b) => Uint8List.fromList([b]).buffer.asByteData().getInt8(0);

int twoByteToInt16(int v1, int v2) =>
    Uint8List.fromList([v1, v2]).buffer.asByteData().getUint16(0);

String byteListToHexString(List<int> bytes) => bytes
    .map((i) => i.toRadixString(16).padLeft(2, '0'))
    .reduce((a, b) => (a + b));

beaconDebugInfo(BeaconInfo pBeacon, Beacon b) {
  debugPrint("Beacon ${pBeacon.phoneMake}+${pBeacon.beaconUUID} is nearby!");
  if (kDebugMode) {
    print("tx power: ${b.tx}");
    print("Raw rssi: ${b.rawRssi}");
    print("Filtered rssi: ${b.kfRssi}");
    print("Log distance with raw rssi: ${b.rawRssiLogDistance}");
    print("Log distance with filtered rssi: ${b.kfRssiLogDistance}");
    print("RadiusNetworks distance with raw rssi: ${b.rawRssiLibraryDistance}");
    print(
        "RadiusNetworks distance with filtered rssi: ${b.kfRssiLibraryDistance}");
  }
}

// https://arxiv.org/ftp/arxiv/papers/1912/1912.07801.pdf
errorRateforCoordinate(
    double realX, double estimatedX, double realY, double estimatedY) {
  return sqrt(pow((realX - estimatedX), 2) + pow((realY - estimatedY), 2));
}

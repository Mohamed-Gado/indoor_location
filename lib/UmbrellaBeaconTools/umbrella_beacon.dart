library umbrella_beacon;

import 'package:flutter_blue/flutter_blue.dart';

import 'beacon_tools.dart';
export 'beacon_tools.dart';

class UmbrellaBeacon {
  // Singleton
  UmbrellaBeacon._();

  static final UmbrellaBeacon _instance = UmbrellaBeacon._();

  static UmbrellaBeacon get instance => _instance;

  Future<Beacon> scan(FlutterBlue bleManager) async {
    final result = await bleManager.startScan(
        scanMode: ScanMode.lowLatency, allowDuplicates: true);
    return result
        .map((scanResult) {
          return Beacon.fromScanResult(scanResult);
        })
        .expand((b) => b)
        .where((b) => b != null);
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_blue/gen/flutterblue.pb.dart';
import 'package:indoor_location/UmbrellaBeaconTools/DistanceAlgorithms/android_beacon_library_model.dart';
import 'package:indoor_location/UmbrellaBeaconTools/DistanceAlgorithms/log_distance_path_loss_model.dart';
import 'package:indoor_location/utils.dart';
import 'Filters/kalman_filter.dart';
import 'package:quiver/core.dart';

const eddystoneServiceId = "0000feaa-0000-1000-8000-00805f9b34fb";

List<Beacon> beaconList = [];

KalmanFilter kf = KalmanFilter(0.065, 1.4, 0, 0);

// Adapted from: https://github.com/michaellee8/flutter_blue_beacon/blob/master/lib/beacon.dart
abstract class Beacon {
  final int tx;
  final ScanResult scanResult;

  double get rawRssi => scanResult.rssi.toDouble();

  double get kfRssi => kf.getFilteredValue(rawRssi);

  String get name => scanResult.device.name;

  String get id => scanResult.device.remoteId;

  int get hash;

  int get txAt1Meter => tx;

  double get rawRssiLogDistance {
    return LogDistancePathLossModel(rawRssi).getCalculatedDistance();
  }

  double get kfRssiLogDistance {
    return LogDistancePathLossModel(kfRssi).getCalculatedDistance();
  }

  double get rawRssiLibraryDistance {
    return AndroidBeaconLibraryModel()
        .getCalculatedDistance(rawRssi, txAt1Meter);
  }

  double get kfRssiLibraryDistance {
    return AndroidBeaconLibraryModel()
        .getCalculatedDistance(kfRssi, txAt1Meter);
  }

  const Beacon({required this.tx, required this.scanResult});

  static List<Beacon> fromScanResult(ScanResult scanResult) {
    try {
      EddystoneUID? eddystoneBeacon =
          EddystoneUID.getFromScanResult(scanResult);
      if (eddystoneBeacon != null) {
        beaconList.add(eddystoneBeacon);
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print("ERROR: $e");
      }
    }

    return beaconList;
  }
}

// Base class of all Eddystone beacons
abstract class Eddystone extends Beacon {
  const Eddystone(
      {required this.frameType,
      required int tx,
      required ScanResult scanResult})
      : super(tx: tx, scanResult: scanResult);

  final int frameType;

  @override
  int get txAt1Meter => tx - 59;
}

class EddystoneUID extends Eddystone {
  final String namespaceId;
  final String beaconId;

  const EddystoneUID({
    required int frameType,
    required this.namespaceId,
    required this.beaconId,
    required int tx,
    required ScanResult scanResult,
  }) : super(tx: tx, scanResult: scanResult, frameType: frameType);

  static EddystoneUID? getFromScanResult(ScanResult scanResult) {
    if (!scanResult.advertisementData.serviceData
        .containsKey(eddystoneServiceId)) {
      return null;
    }
    if (scanResult.advertisementData.serviceData[eddystoneServiceId]!.length <
        18) {
      return null;
    }
    if (scanResult.advertisementData.serviceData[eddystoneServiceId]?[0] !=
        0x00) {
      return null;
    }

    // print("Eddystone beacon detected!");

    List<int> rawBytes =
        scanResult.advertisementData.serviceData[eddystoneServiceId]!;
    var frameType = rawBytes[0];
    //  print("frameType: " + frameType.toString());
    var tx = byteToInt8(rawBytes[1]);
    //   print("tx power: " + tx.toString());
    var namespaceId = byteListToHexString(rawBytes.sublist(2, 12));
//    print("namespace id: " + namespaceId);
    var beaconId = byteListToHexString(rawBytes.sublist(12, 18));
    //   print("beacon id: " + beaconId);

    return EddystoneUID(
        frameType: frameType,
        namespaceId: namespaceId,
        beaconId: beaconId,
        tx: tx,
        scanResult: scanResult);
  }

  @override
  int get hash => hashObjects([
        "EddystoneUID",
        eddystoneServiceId,
        frameType,
        namespaceId,
        beaconId,
        tx
      ]);
}

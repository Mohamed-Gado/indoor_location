import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:beacon_broadcast/beacon_broadcast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../utils.dart';
import 'beacon_info.dart';
import 'ranged_beacon_data.dart';

class AppStateModel extends ChangeNotifier {
  // Singleton
  AppStateModel._();

  static final AppStateModel _instance = AppStateModel._();

  static AppStateModel get instance => _instance;

  bool wifiEnabled = false;
  bool bluetoothEnabled = false;
  bool gpsEnabled = false;
  bool gpsAllowed = false;

  PermissionStatus? locationPermissionStatus;

  BeaconBroadcast beaconBroadcast = BeaconBroadcast();
  String? beaconStatusMessage;
  bool isBroadcasting = false;
  bool isScanning = false;

  Uuid uuid = const Uuid();

  String id = "";

  String phoneMake = "";

  List<BeaconInfo>? anchorBeacons;

  CollectionReference anchorPath =
      FirebaseFirestore.instance.collection('AnchorNodes');

  CollectionReference rangedPath =
      FirebaseFirestore.instance.collection('RangedNodes');

  CollectionReference wtPath =
      FirebaseFirestore.instance.collection('WeightedTri');

  CollectionReference minmaxPath =
      FirebaseFirestore.instance.collection('MinMax');

  Stream<QuerySnapshot>? beaconSnapshots;

  // ignore: cancel_subscriptions
  StreamSubscription? beaconStream;

  void init() async {
    debugPrint("init() called");

    anchorBeacons = [];

    FirebaseFirestore.instance.clearPersistence();

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    phoneMake = androidInfo.model.toString();
    if (kDebugMode) {
      if (kDebugMode) {
        print('Running on $phoneMake');
      }
    }

    id = uuid.v1().toString();
    id = id.replaceAll(RegExp('-'), '');

    if (Platform.isAndroid) {
      // For Android, the user's uuid has to be 20 chars long to conform
      // with Eddystones NamespaceId length
      // Also has to be without hyphens
      id = id.substring(0, 20);

      if (id.length == 20) {
        debugPrint("Android users ID is the correct format");
      } else {
        debugPrint('user ID was of an incorrect format');
        debugPrint(id);
      }
    }
    streamAnchorBeacons();
  }

  void registerBeacon(BeaconInfo bc, String path) async {
    await anchorPath.doc(path).set(bc.toJson());
  }

  void removeBeacon(String path) async {
    await anchorPath.doc(path).delete();
  }

  void uploadRangedBeaconData(RangedBeaconData rbd, String beaconName) async {
    await rangedPath.doc(beaconName).set(
          rbd.toJson(),
          SetOptions(merge: false),
        );
  }

  void streamAnchorBeacons() {
    beaconSnapshots =
        FirebaseFirestore.instance.collection(anchorPath.path).snapshots();

    beaconStream = beaconSnapshots?.listen((s) {
      anchorBeacons?.clear();
      for (var document in s.docs) {
        log('document ${document.data()}');
        anchorBeacons = List.from(anchorBeacons!);
        anchorBeacons
            ?.add(BeaconInfo.fromJson(document.data() as Map<String, dynamic>));
      }
      debugPrint("REGISTERED BEACONS: ${anchorBeacons!.length}");
    });
  }

  List<BeaconInfo> getAnchorBeacons() {
    return anchorBeacons ?? [];
  }

  addWTXY(var coordinates) async {
    if (kDebugMode) {
      print("Data sent to Firestore: $coordinates");
    }
    await wtPath.add(coordinates);
  }

  addMinMaxXY(var coordinates) async {
    await minmaxPath.add(coordinates);
  }

  startBeaconBroadcast() async {
    BeaconBroadcast beaconBroadcast = BeaconBroadcast();

    var transmissionSupportStatus =
        await beaconBroadcast.checkTransmissionSupported();
    switch (transmissionSupportStatus) {
      case BeaconStatus.supported:
        if (kDebugMode) {
          print("Beacon advertising is supported on this device");
        }

        if (Platform.isAndroid) {
          debugPrint("User beacon uuid: $id");

          beaconBroadcast
              .setUUID(id)
              .setMajorId(randomNumber(1, 99))
              .setTransmissionPower(-59)
              .setLayout(BeaconBroadcast.EDDYSTONE_UID_LAYOUT)
              .start();
        }

        beaconBroadcast.getAdvertisingStateChange().listen((isAdvertising) {
          beaconStatusMessage = "Beacon is now advertising";
          //   isBroadcasting = true;
        });
        break;

      case BeaconStatus.notSupportedMinSdk:
        beaconStatusMessage =
            "Your Android system version is too low (min. is 21)";
        if (kDebugMode) {
          print(beaconStatusMessage);
        }
        break;
      case BeaconStatus.notSupportedBle:
        beaconStatusMessage = "Your device doesn't support BLE";
        if (kDebugMode) {
          print(beaconStatusMessage);
        }
        break;
      case BeaconStatus.notSupportedCannotGetAdvertiser:
        beaconStatusMessage = "Either your chipset or driver is incompatible";
        if (kDebugMode) {
          print(beaconStatusMessage);
        }
        break;
    }
  }

  stopBeaconBroadcast() {
    beaconStatusMessage = "Beacon has stopped advertising";
    beaconBroadcast.stop();
    if (kDebugMode) {
      print(beaconStatusMessage);
    }
  }

  checkGPS() async {
    if (!(await Geolocator.isLocationServiceEnabled())) {
      if (kDebugMode) {
        print("GPS disabled");
      }
      gpsEnabled = false;
    } else {
      if (kDebugMode) {
        print("GPS enabled");
      }
      gpsEnabled = true;
    }
  }

  // Adapted from: https://dev.to/ahmedcharef/flutter-wait-user-enable-gps-permission-location-4po2#:~:text=Flutter%20Permission%20handler%20Plugin&text=Check%20if%20a%20permission%20is,permission%20status%20of%20location%20service.
  // Future<bool> requestPermission(Permission permission) async {
  //   permission.request();
  //   final PermissionHandler _permissionHandler = PermissionHandler();
  //   var result = await _permissionHandler.requestPermissions([permission]);
  //   if (result[permission] == PermissionStatus.granted) {
  //     return true;
  //   }
  //   return false;
  // }

  // Adapted from: https://dev.to/ahmedcharef/flutter-wait-user-enable-gps-permission-location-4po2#:~:text=Flutter%20Permission%20handler%20Plugin&text=Check%20if%20a%20permission%20is,permission%20status%20of%20location%20service.
  Future<bool> requestLocationPermission(
      {Function()? onPermissionDenied}) async {
    PermissionStatus granted = await Permission.location.request();
    if (granted != PermissionStatus.granted) {
      gpsAllowed = false;
      requestLocationPermission();
    } else {
      gpsAllowed = true;
    }
    debugPrint('requestLocationPermission $granted');
    return granted == PermissionStatus.granted;
  }

  Future<void> checkLocationPermission() async {
    gpsAllowed =
        await Permission.location.request() == PermissionStatus.granted;
  }
}

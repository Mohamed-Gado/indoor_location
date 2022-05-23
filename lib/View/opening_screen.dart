import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:indoor_location/models/app_state_model.dart';
import 'package:indoor_location/models/beacon_info.dart';
import 'package:indoor_location/widgets.dart';
import '../styles.dart';
import 'package:wakelock/wakelock.dart';

class OpeningScreen extends StatefulWidget {
  const OpeningScreen({Key? key}) : super(key: key);

  @override
  OpeningScreenState createState() {
    return OpeningScreenState();
  }
}

class OpeningScreenState extends State<OpeningScreen> {
  AppStateModel appStateModel = AppStateModel.instance;
  String phoneMake = "";
  late BeaconInfo bc;
  late String beaconPath;
  BluetoothState blState = BluetoothState.off;

  late StreamSubscription networkChanges;
  ConnectivityResult? connectivityResult;

  late StreamSubscription bluetoothChanges;
  FlutterBlue flutterBlue = FlutterBlue.instance;

  TextEditingController xInput = TextEditingController();
  TextEditingController yInput = TextEditingController();
  bool allowTextInput = true;
  bool coordinatesAreOK = true;
  double? xCoordinate;
  double? yCoordinate;
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print("Showing Opening Screen");
    }
    appStateModel.requestLocationPermission();
    networkChanges = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      setState(() {
        connectivityResult = result;
        if (connectivityResult == ConnectivityResult.wifi ||
            connectivityResult == ConnectivityResult.mobile) {
          appStateModel.wifiEnabled = true;
          debugPrint("Network connected");
        } else {
          appStateModel.wifiEnabled = false;

          appStateModel.stopBeaconBroadcast();
          appStateModel.isBroadcasting = false;
        }
      });
    });

    bluetoothChanges = flutterBlue.state.listen((s) {
      setState(() {
        blState = s;
        debugPrint("Bluetooth State changed");
        if (blState == BluetoothState.on) {
          appStateModel.bluetoothEnabled = true;
          debugPrint("Bluetooth is on");
        } else {
          appStateModel.bluetoothEnabled = false;

          appStateModel.stopBeaconBroadcast();
          appStateModel.isBroadcasting = false;
        }
      });
    });
    Wakelock.enable();
    appStateModel.checkGPS();

    bc = BeaconInfo(
        phoneMake: phoneMake,
        beaconUUID: "",
        txPower: "-59",
        standardBroadcasting: "EddystoneUID");

    getBeaconInfo();
  }

  getBeaconInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    setState(() {
      phoneMake = androidInfo.model.toString();

      bc = BeaconInfo(
          phoneMake: phoneMake,
          beaconUUID: appStateModel.id,
          txPower: "-59",
          standardBroadcasting: "EddystoneUID");
    });

    beaconPath = "$phoneMake+${appStateModel.id}";
    if (kDebugMode) {
      print("Beacon path: $beaconPath");
    }
  }

  buildBroadcastButton() {
    if (appStateModel.isBroadcasting) {
      return FloatingActionButton(
          backgroundColor: Colors.redAccent,
          onPressed: () {
            allowTextInput = true;
            appStateModel.stopBeaconBroadcast();
            appStateModel.removeBeacon(beaconPath);
            setState(() {
              appStateModel.isBroadcasting = false;
            });
          },
          child: const Icon(Icons.stop));
    } else {
      return FloatingActionButton(
          backgroundColor: Colors.greenAccent,
          onPressed: () {
            // It is acceptable to leave both empty,
            // but you can't have one with text and the other without
            if (xInput.text.isEmpty & yInput.text.isEmpty) {
              coordinatesAreOK = false;
            } else {
              if (kDebugMode) {
                print("You have inputted something");
              }
              xCoordinate = double.tryParse(xInput.text);
              yCoordinate = double.tryParse(yInput.text);

              // If either field can't be parsed into a double,
              // set coordinatesAreDouble to false
              if (xCoordinate == null || yCoordinate == null) {
                coordinatesAreOK = false;
                if (kDebugMode) {
                  print("One of X and Y returned null when parse attempted");
                  print(
                      "xCoordinate : $xCoordinate, yCoordinate: $yCoordinate");
                }
              } else {
                coordinatesAreOK = true;
                if (kDebugMode) {
                  print(
                      "xCoordinate : $xCoordinate, yCoordinate: $yCoordinate");
                }
              }
            }

            appStateModel.checkGPS();
            appStateModel.checkLocationPermission();
            if (appStateModel.wifiEnabled &
                appStateModel.bluetoothEnabled &
                appStateModel.gpsEnabled &
                appStateModel.gpsAllowed &
                coordinatesAreOK) {
              allowTextInput = false;

              if (xCoordinate != null && yCoordinate != null) {
                bc.x = xCoordinate;
                bc.y = yCoordinate;
              }

              appStateModel.startBeaconBroadcast();
              appStateModel.registerBeacon(bc, beaconPath);
              setState(() {
                appStateModel.isBroadcasting = true;
              });
            } else if (!appStateModel.gpsAllowed) {
              showGenericDialog(context, "Location Permission Required",
                  "Location is needed to correctly advertise as a beacon");
            } else if (!appStateModel.gpsEnabled) {
              showGPSDialog(context);
            } else if (!coordinatesAreOK) {
              showGenericDialog(context, "Double check inputted coordinates",
                  "Values determined to be invalid");
            } else {
              showGenericDialog(
                  context,
                  "Wi-Fi, Bluetooth and GPS need to be on",
                  'Please check each of these in order to broadcast');
            }
          },
          child: const Icon(Icons.record_voice_over));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: createMaterialColor(const Color(0xFFE8E6D9)),
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Text(
              'Umbrella',
              style: TextStyle(color: Colors.black),
            ),
            Image(image: AssetImage('assets/icons8-umbrella-24.png'))
          ],
        ),
      ),
      floatingActionButton: buildBroadcastButton(),
      body: Stack(children: <Widget>[
        (connectivityResult == ConnectivityResult.none)
            ? buildAlertTile(context, "Wifi required to broadcast beacon")
            : Container(),
        (appStateModel.isBroadcasting) ? buildProgressBarTile() : Container(),
        (blState != BluetoothState.on)
            ? buildAlertTile(context, "Please check whether Bluetooth is on")
            : Container(),
        Align(
          child: SingleChildScrollView(
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                BeaconInfoContainer(beaconInfo: bc),
                Container(
                  margin: const EdgeInsets.only(top: 30, left: 30, right: 30),
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Enter Cartesian X and Y Coordinates to use beacon as anchor for trilateration [REQUIRED]",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          enabled: allowTextInput,
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          textAlign: TextAlign.center,
                          controller: xInput,
                          decoration: InputDecoration(
                            hintText: 'X (m)',
                            counterText: "",
                            contentPadding: const EdgeInsets.fromLTRB(
                                20.0, 10.0, 20.0, 10.0),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5.0)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          enabled: allowTextInput,
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          textAlign: TextAlign.center,
                          controller: yInput,
                          decoration: InputDecoration(
                            hintText: 'Y (m)',
                            counterText: "",
                            contentPadding: const EdgeInsets.fromLTRB(
                                20.0, 10.0, 20.0, 10.0),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5.0)),
                          ),
                        ),
                      ),
                      const Padding(padding: EdgeInsets.only(top: 20)),
                    ],
                  ),
                ),
              ],
            )),
          ),
        )
      ]),
    );
  }
}

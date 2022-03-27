import 'dart:async';
import 'dart:convert';
import "dart:typed_data";
import 'dart:ui';

import 'package:beanbot_app/screens/MainScreen.dart';
import 'package:beanbot_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart";

// Config
String BEANBOT_BT_NAME = "test";
List<String> STATUSES = [
  "Idle - Ready For Operation",
  "Processing - Order Being Processed"
];

void main() {
  print('start');
  runApp(BluetoothApp());
}

class BluetoothApp extends StatefulWidget {
  @override
  _BluetoothAppState createState() => _BluetoothAppState();
}

class _BluetoothAppState extends State<BluetoothApp> {
  String deviceName = "loading...";
  String deviceStatus = "loading...";

  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  late BluetoothConnection connection;

  // To track whether the device is still connected to Bluetooth
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    isConnected = false;

    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    establishConnection();

    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
        connectToBeanBot();
      });
    });
  }

  Future<void> establishConnection() async {
    await enableBluetooth();
    if (isConnected) {
      print("Beanbot succesfully connected");

      connection.input?.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
      });
      connection.output.add(ascii.encode("init_connection"));
    }
  }

  List<int> commandBuffer = [];

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    commandBuffer = commandBuffer + buffer;

    String dataString = String.fromCharCodes(commandBuffer);
    print(dataString);
    // Check for command
    List<String> commandArray = dataString.split(" ");

    for (var i = 0; i < commandArray.length; i++) {
      if (commandArray[i].startsWith("\$\{") & commandArray[i].endsWith("\}")) {
        List<String> command =
            commandArray[i].substring(2, commandArray[i].length - 1).split(":");

        switch (command[0]) {
          case "#data":
            {
              String key = command[1];
              String value = command[2].replaceAll("_", " ");

              switch (key) {
                case "name":
                  setState(() {
                    deviceName = value;
                  });
                  break;
                case "status":
                  print("${int.parse(value)}");
                  setState(() {
                    deviceStatus = STATUSES[int.parse(value)];
                  });
                  break;
              }
            }
        }

        List<String> d = List<String>.from(commandArray);
        d.remove(d[i]);
        String e = d.join(" ");
        commandBuffer = e.codeUnits;
      }
    }
  }

  Future<void> enableBluetooth() async {
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await connectToBeanBot();
      return;
    } else {
      await connectToBeanBot();
      return;
    }
  }

  Future<void> connectToBeanBot() async {
    List<BluetoothDevice> devices = [];

    try {
      devices = await _bluetooth.getBondedDevices();
    } on PlatformException {
      return;
    }

    for (var i = 0; i < devices.length; i++) {
      // TO DO
      BluetoothDevice device = devices[i];
      if (device.name == BEANBOT_BT_NAME) {
        await BluetoothConnection.toAddress(device.address).then((_connection) {
          setState(() {
            connection = _connection;
            isConnected = true;
          });
        }).catchError((error) {
          print(error);
        });
        return;
      }
    }
  }

  @override
  void reassemble() {
    print("Close");
    isConnected = false;
    try {
      connection.close();
    } catch (error) {
      print("error closing connection");
    }
    super.reassemble();
  }

  bool isDisconnecting = false;

  @override
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
    }

    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    double screenWidth = window.physicalSize.width;
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "BeanBot Bluetooth Control",
        theme: ThemeData(
            primaryColor: COLOR_WHITE,
            accentColor: COLOR_DARK_BLUE,
            textTheme:
                screenWidth < 500 ? TEXT_THEME_SMALL : TEXT_THEME_DEFAULT),
        home: MainScreen(
          isConnected: isConnected,
          deviceName: deviceName,
          deviceStatus: deviceStatus,
          connection: isConnected ? connection : null,
        ));
  }
}

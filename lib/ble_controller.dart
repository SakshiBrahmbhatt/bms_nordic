import 'dart:convert';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceInfo {
  final String name;
  final String id;

  DeviceInfo(this.name, this.id);

  // Convert DeviceInfo to JSON
  Map<String, dynamic> toJson() => {
    'name': name,
    'id': id,
  };

  // Create DeviceInfo from JSON
  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
    json['name'],
    json['id'],
  );
}

class BleController extends GetxController {
  FlutterBlue ble = FlutterBlue.instance;
  BluetoothDevice? selectedDevice;
  List<BluetoothService> availableServices = [];
  List<BluetoothCharacteristic> availableCharacteristics = [];
  BluetoothCharacteristic? selectedCharacteristic;
  BluetoothCharacteristic? characteristic;
  late String receivedData = "";

  void setSelectedDevice(BluetoothDevice? device) {
    selectedDevice = device;
    update();
  }

  Future<void> connectToSelectedDevice() async {
    if (selectedDevice != null) {
      await connectToDevice(selectedDevice!);
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      discoverServices(device);
      update(); // Notify listeners
    } catch (e) {
      print(e);
    }
  }

  Future<void> disconnectToSelectedDevice() async {
    if (selectedDevice != null) {
      await disconnectToDevice(selectedDevice!);
    }
  }

  Future<void> disconnectToDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      selectedDevice = null; // Reset selected device on disconnection
      availableServices.clear(); // Clear the list of services
      availableCharacteristics.clear(); // Clear the list of characteristics
      selectedCharacteristic = null; // Reset selected characteristic on disconnection
      characteristic = null; // Reset selected characteristic on disconnection
      update(); // Notify listeners
    } catch (e) {
      print(e);
    }
  }

  void discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic char in service.characteristics) {
        if (isDesiredCharacteristic(char)) {
          selectedCharacteristic = char;
          break;
        }
      }
      for (BluetoothCharacteristic char in service.characteristics) {
        if (isDesiredWriteCharacteristic(char)) {
          characteristic = char;
          break;
        }
      }
    }
  }

  bool isDesiredCharacteristic(BluetoothCharacteristic characteristic) {
    return characteristic.properties.notify;
  }

  bool isDesiredWriteCharacteristic(BluetoothCharacteristic characteristic) {
    return characteristic.properties.write;
  }

  Future<String> subscribeToNotifications(BluetoothDevice device) async {
    discoverServices(device);
    if (selectedCharacteristic != null && selectedCharacteristic!.properties.read) {
      try {
        await selectedCharacteristic!.setNotifyValue(true);
        await selectedCharacteristic!.read();
        selectedCharacteristic!.value.listen((value) {
          receivedData = String.fromCharCodes(value);
        });
      } catch (e) {
        print('Error setting notification value: $e');
      }
    } else {
      print('Characteristic does not support notifications');
    }

    return receivedData;
  }

  void sendMessage(BluetoothDevice device, String data){
    try {
      discoverServices(device);
      if (characteristic != null && characteristic!.properties.write) {
        characteristic!.write(utf8.encode(data), withoutResponse: true);
      } else {
        print('Characteristic does not support write operations');
      }
    } catch (e) {
      print('Error writing to characteristic: $e');
    }
  }

  Future<String> subscribeToNotificationsTable() async {
    if (selectedCharacteristic != null && selectedCharacteristic!.properties.notify) {
      try {
        await selectedCharacteristic!.setNotifyValue(true);
        await selectedCharacteristic!.read();
        selectedCharacteristic!.value.listen((value) {
          receivedData = String.fromCharCodes(value);
        });
      } catch (e) {
        print('Error setting notification value: $e');
      }
    } else {
      print('Characteristic does not support notifications');
    }

    return receivedData;
  }

  void sendMessageTable(String data){
    try {
      if (characteristic != null && characteristic!.properties.write) {
        characteristic!.write(utf8.encode(data), withoutResponse: true);
      } else {
        print('Characteristic does not support write operations');
      }
    } catch (e) {
      print('Error writing to characteristic: $e');
    }
  }

  Future<void> saveSelectedDeviceToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (selectedDevice != null) {
      String deviceJson = jsonEncode(DeviceInfo(selectedDevice!.name, selectedDevice!.id.id).toJson());
      prefs.setString('selectedDevice', deviceJson);
    }
  }

  Future<BluetoothDevice?> loadSelectedDeviceFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? deviceJson = prefs.getString('selectedDevice');

    if (deviceJson != null) {
      DeviceInfo deviceInfo = DeviceInfo.fromJson(jsonDecode(deviceJson));

      // Fetch the connected devices and find the matching device
      List<BluetoothDevice> connectedDevices = await ble.connectedDevices;
      selectedDevice = connectedDevices.firstWhere(
            (device) => device.name == deviceInfo.name && device.id.id == deviceInfo.id,
      );

      update(); // Notify listeners
      return selectedDevice;
    }

    return null; // Return null if no device is found in preferences
  }

  Future<void> scanDevices() async {
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted) {
      ble.startScan(timeout: Duration(seconds: 1000));
    }
  }

  void stopScan() {
    ble.stopScan();
  }

  Stream<List<ScanResult>> get scanResults => ble.scanResults;
}

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'ble_controller.dart';

class dashboard extends StatefulWidget {
  const dashboard({super.key});

  @override
  State<dashboard> createState() => _dashboardState();
}

class _dashboardState extends State<dashboard> {
  late BleController controller;
  Future<DeviceInfo>? deviceInfoFuture;

  @override
  void initState() {
    super.initState();

    controller = BleController();
    deviceInfoFuture = loadDeviceInfo();
  }

  Future<DeviceInfo> loadDeviceInfo() async {
    BluetoothDevice? selectedDevice = await controller.loadSelectedDeviceFromPrefs();
    if (selectedDevice != null) {
      return DeviceInfo(selectedDevice.name, selectedDevice.id.id);
    } else {
      // Return some default DeviceInfo or handle the case accordingly
      return DeviceInfo("Unknown", "Unknown");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BMS Configurator",
            style: TextStyle(color: Colors.white)
        ),
        backgroundColor: Color(0xFF0058DB),
        leading: Container(
          padding: EdgeInsets.all(10),
          child: Image.asset('assets/images/logo.jpg'),
        ),
      ),
      body: FutureBuilder<DeviceInfo>(
        future: deviceInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: Try again later'));
          } else {
            DeviceInfo deviceInfo = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Center(
                    child: Text(
                      '${deviceInfo.name}',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: const [
                      // CustomListItem(
                      //   image: 'assets/images/setting.png',
                      //   title: 'Basic Details',
                      // ),
                      CustomListItem(
                        image: 'assets/images/calibrator.png',
                        title: 'Calibration Settings',
                      ),
                      CustomListItem(
                        image: 'assets/images/temperature.png',
                        title: 'RTD Calibration',
                      ),
                      CustomListItem(
                        image: 'assets/images/sensor.png',
                        title: 'Sensor Details',
                      ),
                      CustomListItem(
                        image: 'assets/images/table.png',
                        title: 'Table',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

}

class CustomListItem extends StatelessWidget {
  final String image;
  final String title;

  const CustomListItem({
    Key? key,
    required this.image,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        switch (title) {
          // case 'Basic Details':
          //   Navigator.pushNamed(context, './basic');
          //   break;
          case 'Calibration Settings':
            Navigator.pushNamed(context, './calibration');
            break;
          case 'RTD Calibration':
            Navigator.pushNamed(context, './voltage');
            break;
          case 'Sensor Details':
            Navigator.pushNamed(context, './sensor');
            break;
          case 'Table':
            Navigator.pushNamed(context, './table');
            break;
          default:
            break;
        }
      },
      child: Card(
        margin: const EdgeInsets.all(10),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Image.asset(image, height: 50, width: 50, fit: BoxFit.cover),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SemiOvalClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromPoints(
      Offset(-size.width * 0.2, size.height),
      Offset(size.width * 1.2, -size.height * 0.2),
    );
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return false;
  }
}
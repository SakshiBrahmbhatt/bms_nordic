import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:fluttertoast/fluttertoast.dart';
import "package:path_provider/path_provider.dart";
import 'package:open_file/open_file.dart';
import 'ble_controller.dart';
import 'package:file_selector/file_selector.dart' as file_selector;

class table extends StatefulWidget {
  const table({super.key});

  @override
  State<table> createState() => _tableState();
}

class _tableState extends State<table> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BMS Configurator", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF0058DB),
        leading: Container(
          padding: EdgeInsets.all(10),
          child: Image.asset('assets/images/logo.jpg'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ExcelTable(),
      ),
    );
  }
}

class ExcelTable extends StatefulWidget {
  @override
  _ExcelTableState createState() => _ExcelTableState();
}

class _ExcelTableState extends State<ExcelTable> {
  late BleController bleController;
  late Future<DeviceInfo> deviceInfoFuture;
  final TextEditingController controller = TextEditingController();
  int a = 0,
      b = 0,
      c = 0;

  @override
  void initState() {
    super.initState();
    bleController = BleController();
    deviceInfoFuture = loadDeviceInfo();
  }


  Future<DeviceInfo> loadDeviceInfo() async {
    BluetoothDevice? selectedDevice = await bleController
        .loadSelectedDeviceFromPrefs();
    return DeviceInfo(selectedDevice!);
  }

  Future<void> setParts(BluetoothDevice device) async {
    try {
      String dataToSend = '@NOPART?\n\r';
      bleController.discoverServices(device);
      bleController.sendMessageTable(dataToSend);
      String value = await bleController.subscribeToNotificationsTable();
      const Duration timeoutDuration = Duration(seconds: 15);
      const Duration delayBetweenRetries = Duration(seconds: 1);
      DateTime startTime = DateTime.now();

      while (DateTime.now().difference(startTime) < timeoutDuration) {
        value = await bleController.subscribeToNotificationsTable();

        if (!value.isEmpty) {
          setState(() {
            controller.text = value;
            value = ' ';
          });
          a = int.parse(controller.text);
          a = a - 1;
          b = (a / 10).toInt();
          c = a % 10;
        }

        await Future.delayed(delayBetweenRetries);
      }

      if (value.isEmpty) {
        bleController.sendMessageTable(dataToSend);
        String value = await bleController.subscribeToNotificationsTable();
        const Duration timeoutDuration = Duration(seconds: 15);
        const Duration delayBetweenRetries = Duration(seconds: 1);
        DateTime startTime = DateTime.now();

        while (DateTime.now().difference(startTime) < timeoutDuration) {
          value = await bleController.subscribeToNotificationsTable();

          if (!value.isEmpty) {
            setState(() {
              controller.text = value;
              value = ' ';
            });
            a = int.parse(controller.text);
            a = a - 1;
            b = (a / 10).toInt();
            c = a % 10;
          }

          await Future.delayed(delayBetweenRetries);
        }

        if (value.isEmpty) {
          // Handle the case where no response is received within the timeout
          setState(() {
            Fluttertoast.showToast(
              msg: 'Timeout: No response received within 30 second.',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.white,
              textColor: Colors.black,
              fontSize: 16.0,
            );
          });
        }
      }
    } catch (e) {
      print('Error during setup: $e');
    }
  }


  List<List<String>> tableData = List.generate(
    20,
        (rowIndex) =>
        List.generate(
          10,
              (colIndex) => '0.00000',
        ),
  );
  TextEditingController editingController = TextEditingController();
  String filePath = "";

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DeviceInfo>(
        future: deviceInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            DeviceInfo deviceInfo = snapshot.data!;
            return Column(
              children: [
                // Heading
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Table',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Buttons in Two Rows
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        // Your export button action
                        print('Export');
                        _exportToExcel();
                      },
                      child: Text('Export'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Your import button action
                        setParts(deviceInfo.device);
                        print('Import');
                        _pickFile();
                      },
                      child: Text('Import'),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await setParts(deviceInfo.device);
                        print('$controller.text,$a,$b,$c');
                        if (controller.text.isNotEmpty) {
                          for (int i = 0; i <= b; i++) {
                            for (int j = 0; j <= c; j++) {
                              print('$i,$j');
                              if (tableData[i][j].isNotEmpty) {
                                int k = i * 10 + j + 1;
                                String formattedK = k.toString().padLeft(
                                    3, '0');
                                String dataToSend = '@TBL' + formattedK + ' ' +
                                    tableData[i][j] + '\n\r';
                                bleController.sendMessageTable(dataToSend);
                                String value = await bleController
                                    .subscribeToNotificationsTable();
                                const Duration timeoutDuration = Duration(
                                    seconds: 15);
                                const Duration delayBetweenRetries = Duration(
                                    seconds: 1);
                                DateTime startTime = DateTime.now();

                                while (DateTime.now().difference(startTime) <
                                    timeoutDuration && value.isEmpty) {
                                  value = await bleController
                                      .subscribeToNotificationsTable();

                                  if (!value.isEmpty) {
                                    setState(() {
                                      Fluttertoast.showToast(
                                        msg: '$k : $value',
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.BOTTOM,
                                        timeInSecForIosWeb: 1,
                                        backgroundColor: Colors.white,
                                        textColor: Colors.black,
                                        fontSize: 16.0,
                                      );
                                      tableData[i][j] = '';
                                      value = ' ';
                                    });
                                  }

                                  await Future.delayed(delayBetweenRetries);
                                }

                                if (value.isEmpty) {
                                  bleController.sendMessageTable(dataToSend);
                                  value = await bleController
                                      .subscribeToNotificationsTable();
                                  const Duration timeoutDuration = Duration(
                                      seconds: 15);
                                  const Duration delayBetweenRetries = Duration(
                                      seconds: 1);
                                  DateTime startTime = DateTime.now();

                                  while (DateTime.now().difference(startTime) <
                                      timeoutDuration && value.isEmpty) {
                                    value =
                                    await bleController
                                        .subscribeToNotificationsTable();

                                    if (!value.isEmpty) {
                                      setState(() {
                                        Fluttertoast.showToast(
                                          msg: '$k : $value',
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.BOTTOM,
                                          timeInSecForIosWeb: 1,
                                          backgroundColor: Colors.white,
                                          textColor: Colors.black,
                                          fontSize: 16.0,
                                        );
                                        tableData[i][j] = '';
                                        value = ' ';
                                      });
                                    }

                                    await Future.delayed(delayBetweenRetries);
                                  }

                                  if (value.isEmpty) {
                                    setState(() {
                                      Fluttertoast.showToast(
                                        msg: 'Timeout: No response received within 30 seconds.',
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.BOTTOM,
                                        timeInSecForIosWeb: 1,
                                        backgroundColor: Colors.white,
                                        textColor: Colors.black,
                                        fontSize: 16.0,
                                      );
                                    });
                                  }
                                }
                              }
                              else {
                                Fluttertoast.showToast(
                                  msg: 'Enter the value to send msg',
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.white,
                                  textColor: Colors.black,
                                  fontSize: 16.0,
                                );
                              }
                            }
                          }
                        }
                        else {
                          Fluttertoast.showToast(
                            msg: 'Not able to fetch no. of parts',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.white,
                            textColor: Colors.black,
                            fontSize: 16.0,
                          );
                        }
                        print('Send');
                      },
                      child: Text('Send'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await setParts(deviceInfo.device);
                        if (controller.text.isNotEmpty) {
                          for (int i = 0; i <= b; i++) {
                            for (int j = 0; j <= c; j++) {
                              print('$i,$j');
                              int k = i * 10 + j + 1;
                              String formattedK = k.toString().padLeft(3, '0');
                              String dataToSend = '@TBL' + formattedK + '?' +
                                  '\n\r';
                              bleController.sendMessageTable(dataToSend);
                              String value = await bleController
                                  .subscribeToNotificationsTable();
                              const Duration timeoutDuration = Duration(
                                  seconds: 15);
                              const Duration delayBetweenRetries = Duration(
                                  seconds: 1);
                              DateTime startTime = DateTime.now();

                              while (DateTime.now().difference(startTime) <
                                  timeoutDuration && value.isEmpty) {
                                value = await bleController
                                    .subscribeToNotificationsTable();

                                if (!value.isEmpty) {
                                  List<String> parts = value.split(',');

                                  if (parts.length >= 2) {
                                    value = parts[1];
                                    tableData[i][j] = value;
                                    setState(() {
                                      Fluttertoast.showToast(
                                        msg: '$k : $value',
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.BOTTOM,
                                        timeInSecForIosWeb: 1,
                                        backgroundColor: Colors.white,
                                        textColor: Colors.black,
                                        fontSize: 16.0,
                                      );
                                      value = ' ';
                                    });
                                  }
                                }

                                await Future.delayed(delayBetweenRetries);
                              }

                              if (value.isEmpty) {
                                bleController.sendMessageTable(dataToSend);
                                value = await bleController
                                    .subscribeToNotificationsTable();
                                const Duration timeoutDuration = Duration(
                                    seconds: 15);
                                const Duration delayBetweenRetries = Duration(
                                    seconds: 1);
                                DateTime startTime = DateTime.now();

                                while (DateTime.now().difference(startTime) <
                                    timeoutDuration && value.isEmpty) {
                                  value = await bleController
                                      .subscribeToNotificationsTable();
                                  if (!value.isEmpty) {
                                    List<String> parts = value.split(',');
                                    if (parts.length >= 2) {
                                      value = parts[1];
                                      tableData[i][j] = value;
                                      setState(() {
                                        Fluttertoast.showToast(
                                          msg: '$k : $value',
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.BOTTOM,
                                          timeInSecForIosWeb: 1,
                                          backgroundColor: Colors.white,
                                          textColor: Colors.black,
                                          fontSize: 16.0,
                                        );
                                        value = ' ';
                                      });
                                    }
                                  }

                                  await Future.delayed(delayBetweenRetries);
                                }

                                if (value.isEmpty) {
                                  setState(() {
                                    Fluttertoast.showToast(
                                      msg: 'Timeout: No response received within 30 seconds.',
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                      timeInSecForIosWeb: 1,
                                      backgroundColor: Colors.white,
                                      textColor: Colors.black,
                                      fontSize: 16.0,
                                    );
                                  });
                                  tableData[i][j] = '';
                                }
                              }
                            }
                          }
                        }
                        else {
                          Fluttertoast.showToast(
                            msg: 'Not able to fetch no. of parts',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.white,
                            textColor: Colors.black,
                            fontSize: 16.0,
                          );
                        }
                        print('Receive');
                      },
                      child: Text('Receive'),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: controller,
                  decoration: InputDecoration(labelText: 'No. of parts'),
                ),
                SizedBox(height: 16.0),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        border: TableBorder.all(width: 2.0),
                        columns: List.generate(
                          10,
                              (index) =>
                              DataColumn(
                                label: Container(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Column $index'),
                                ),
                              ),
                        ),
                        rows: List.generate(
                          20,
                              (rowIndex) =>
                              DataRow(
                                cells: List.generate(
                                  10,
                                      (colIndex) =>
                                      DataCell(
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              editingController.text =
                                              tableData[rowIndex][colIndex];
                                            });
                                            _showEditDialog(rowIndex, colIndex);
                                          },
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: tableData[rowIndex][colIndex]
                                                  .isEmpty
                                                  ? Colors
                                                  .red[800] // Color for null value
                                                  : null, // Default color
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text(
                                                tableData[rowIndex][colIndex],
                                                // Remove any explicit color settings here
                                                // (e.g., color: Colors.black) to allow default color
                                              ),
                                            ),
                                          ),

                                        ),
                                      ),
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        });
  }

  Future<void> _exportToExcel() async {
    try {
      final Excel excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      // Add headers to Excel file
      for (int colIndex = 0; colIndex < 10; colIndex++) {
        sheetObject
            .cell(
            CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: 0))
            .value = 'Column $colIndex' as CellValue?;
      }

      // Add data to Excel file
      for (int rowIndex = 0; rowIndex < 20; rowIndex++) {
        for (int colIndex = 0; colIndex < 10; colIndex++) {
          sheetObject
              .cell(CellIndex.indexByColumnRow(
              columnIndex: colIndex, rowIndex: rowIndex + 1))
              .value = tableData[rowIndex][colIndex] as CellValue?;
        }
      }
      final String documentsDirectory =
          (await getApplicationDocumentsDirectory()).path;
      final String filePath = '$documentsDirectory/table_data.xlsx';

      // Save the Excel file
      List<int>? excelBytes = excel.encode();

      //print('Excel file exported to: $filePath');
      if (excelBytes != null) {
        File(filePath).writeAsBytesSync(excelBytes);
        await OpenFile.open(filePath);
        print('Excel file exported to: $filePath');
      } else {
        print('Error: Unable to encode Excel data');
      }
    } catch (e) {
      print('Error exporting to Excel: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      var typeGroup = file_selector.XTypeGroup(
        label: 'Excel files',
        extensions: ['xls', 'xlsx'],
      );

      var files = await file_selector.openFiles(
          acceptedTypeGroups: [typeGroup]);
      if (files != null && files.isNotEmpty) {
        await _readExcelFile(files[0]);
      } else {
        print('File picking canceled.');
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  Future<void> _readExcelFile(file_selector.XFile file) async {
    try {
      var bytes = await file.readAsBytes();
      var excel = Excel.decodeBytes(bytes);

      // Access the desired sheet and its rows
      var sheet = excel.tables['Sheet1']!;
      var rows = sheet.rows;

      // Filter out metadata rows (assuming they're at the beginning)
      var dataRows = rows.skip(1);

      // Extract only the table data from the filtered rows
      var importedData = dataRows
          .map(
            (row) =>
        List<String>.from(row.map(
          // Handle null values safely:
              (cell) => cell?.value?.toString() ?? '',
        )),
      )
          .toList();

      // Pad the imported data with default values ('0.00000') to match the expected grid size
      while (importedData.length < 20) {
        importedData.add(List.filled(10, '0.00000'));
      }

      setState(() {
        tableData = importedData;
      });
    } catch (e) {
      print('Error reading Excel file: $e');
    }
  }

  Future<void> _showEditDialog(int rowIndex, int colIndex) async {
    int k = rowIndex * 10 + colIndex + 1;
    String formattedK = k.toString().padLeft(3, '0');
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Cell'),
          content: TextField(
            controller: editingController,
            decoration: InputDecoration(
              hintText: 'Enter new value',
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      tableData[rowIndex][colIndex] = editingController.text;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text('Save'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () async{
                    var dataToSend = '@TBL'+ formattedK + '?' + '\n\r';
                    bleController.sendMessageTable( dataToSend);
                    String value = await bleController.subscribeToNotificationsTable();
                    const Duration timeoutDuration = Duration(seconds: 15);
                    const Duration delayBetweenRetries = Duration(seconds: 1);
                    DateTime startTime = DateTime.now();

                    while (DateTime.now().difference(startTime) < timeoutDuration) {
                      value = await bleController.subscribeToNotificationsTable();

                      if (!value.isEmpty) {
                        List<String> parts = value.split(',');
                        if (parts.length >= 2) {
                          value = parts[1];
                          editingController.text = value;
                          setState(() {
                            Fluttertoast.showToast(
                              msg: '$k : $value',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.white,
                              textColor: Colors.black,
                              fontSize: 16.0,
                            );
                            value = ' ';
                          });
                        }
                        setState(() {
                          tableData[rowIndex][colIndex] = editingController.text;
                        });
                        Navigator.of(context).pop();
                        break;
                      }

                      await Future.delayed(delayBetweenRetries);
                    }

                    if (value.isEmpty) {
                      // Handle the case where no response is received within the timeout
                      setState(() {
                        Fluttertoast.showToast(
                          msg: 'Timeout: No response received within 15 seconds.',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.white,
                          textColor: Colors.black,
                          fontSize: 16.0,
                        );
                      });
                    }

                    print('Receive ${editingController.text}');
                  },
                  child: Text('Receive'),
                ),
                TextButton(
                  onPressed: () async{
                    if(editingController.text.isNotEmpty){
                      var dataToSend = '@TBL'+ formattedK + ' '+ editingController.text + '\n\r';
                      bleController.sendMessageTable( dataToSend);
                      String value = await bleController.subscribeToNotificationsTable();
                      const Duration timeoutDuration = Duration(seconds: 15);
                      const Duration delayBetweenRetries = Duration(seconds: 1);
                      DateTime startTime = DateTime.now();

                      while (DateTime.now().difference(startTime) < timeoutDuration) {
                        value = await bleController.subscribeToNotificationsTable();

                        if (!value.isEmpty) {
                          setState(() {
                            Fluttertoast.showToast(
                              msg: '$k : $value',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.white,
                              textColor: Colors.black,
                              fontSize: 16.0,
                            );
                            value = ' ';
                          });
                          setState(() {
                            tableData[rowIndex][colIndex] = editingController.text;
                          });
                          Navigator.of(context).pop();
                          break;
                        }

                        await Future.delayed(delayBetweenRetries);
                      }

                      if (value.isEmpty) {
                        // Handle the case where no response is received within the timeout
                        setState(() {
                          Fluttertoast.showToast(
                            msg: 'Timeout: No response received within 15 seconds.',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.white,
                            textColor: Colors.black,
                            fontSize: 16.0,
                          );
                        });
                      }

                      print('Send ${editingController.text}');
                    }
                    else{
                      setState(() {
                        Fluttertoast.showToast(
                          msg: 'First enter value',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.white,
                          textColor: Colors.black,
                          fontSize: 16.0,
                        );
                      });
                    }
                  },
                  child: Text('Send'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}


class DeviceInfo {
  final BluetoothDevice device;

  DeviceInfo(this.device);
}

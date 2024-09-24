import 'dart:ffi';
import 'registerMap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/flat.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainWindow(),
    );
  }
}

class MainWindow extends StatefulWidget {
  @override
  _MainWindowState createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  List<String> functions = [
    'Function A',
    'Function B',
    'Function C',
    'Function D'
  ];
  String? selectedFunction;
  List<String> selectedFunctionLists = [];
  Map<String, List<Register>> settingValueMap = {};
  String? currentActivatedButton;
  int copyCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MainWindow')),
      body: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey)),
              ),
              child: FunctionTab(),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey)),
              ),
              child: RegisterTab(),
            ),
          ),
          Expanded(child: ResultTab()),
        ],
      ),
    );
  }

  Widget FunctionTab() {
    return Column(
      children: [
        DropdownButton<String>(
          value: selectedFunction,
          hint: Text('Select Function'),
          items: functions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null && !selectedFunctionLists.contains(newValue)) {
              setState(() {
                selectedFunction = newValue;
                selectedFunctionLists.add(newValue);
              });
            }
          },
        ),
        Expanded(
          child: ListView.builder(
            itemCount: selectedFunctionLists.length,
            itemBuilder: (context, index) {
              return ElevatedButton(
                onPressed: () =>
                    onClickFunctionButton(selectedFunctionLists[index]),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    currentActivatedButton == selectedFunctionLists[index]
                        ? Colors.lightBlue
                        : null,
                  ),
                ),
                child: Text(selectedFunctionLists[index]),
              );
            },
          ),
        ),
        ElevatedButton(
          child: Text('Send test Config'),
          onPressed: onGenerateFlatBuffer,
        ),
      ],
    );
  }

  Widget RegisterTab() {
    List<Register> currentRegisters =
        settingValueMap[currentActivatedButton] ?? [];
    return Column(
      children: [
        Row(
          children: [
            Text('Copy Count: '),
            Expanded(
              child: SpinBox(
                min: 0,
                max: 100,
                value: copyCount.toDouble(),
                onChanged: (value) => setState(() => copyCount = value.toInt()),
              ),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Table(
              border: TableBorder.all(),
              columnWidths: {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
              },
              children: [
                TableRow(
                  children: [
                    TableCell(child: Center(child: Text('Register Name'))),
                    TableCell(child: Center(child: Text('Value'))),
                  ],
                ),
                ...currentRegisters.asMap().entries.map((entry) {
                  int index = entry.key;
                  Register register = entry.value;
                  TextEditingController controller =
                      TextEditingController(text: register.value.toString());
                  controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length));

                  return TableRow(
                    children: [
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(register.name),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: TextField(
                            controller: controller,
                            onChanged: (value) {
                              setState(() {
                                register.value = double.tryParse(value) ?? 0.0;
                                controller.text = reverseValue(value);
                                controller.selection =
                                    TextSelection.fromPosition(TextPosition(
                                        offset: controller.text.length));
                                if (copyCount > 0) {
                                  for (int i = 1;
                                      i <= copyCount &&
                                          index + i < currentRegisters.length;
                                      i++) {
                                    currentRegisters[index + i].value =
                                        value as double;
                                  }
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        ElevatedButton(
          child: Text('Save'),
          onPressed: () {
            if (currentActivatedButton != null) {
              settingValueMap[currentActivatedButton!] = currentRegisters;
            }
          },
        ),
      ],
    );
  }

  Widget ResultTab() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              // Add your result display widgets here
            ],
          ),
        ),
        ElevatedButton(
          child: Text('Deserialize FlatBuffer'),
          onPressed: () => print('Deserialize FlatBuffer'),
        ),
      ],
    );
  }

  void onClickFunctionButton(String functionName) {
    setState(() {
      currentActivatedButton = functionName;
      if (!settingValueMap.containsKey(functionName)) {
        settingValueMap[functionName] = List.generate(
          10,
          (index) => Register(
              name: 'Register ${index + 1}', address: index, value: 0.0),
        );
      }
    });
  }

  String reverseValue(String value) {
    return value.split('').reversed.join();
  }

  void onGenerateFlatBuffer() {
    if (currentActivatedButton != null &&
        settingValueMap.containsKey(currentActivatedButton)) {
      final registers = settingValueMap[currentActivatedButton]!;

      final registerNames =
          registers.map((Register register) => register.name).toList();
      final addresses =
          registerNames.map((name) => registerMap[name] ?? 0).toList();
      final values = registers.map((register) => register.value).toList();
      final fixedPoints =
          registers.map((register) => register.fixedPoint).toList();

      generateFlatBuffer(registerNames, addresses, values, fixedPoints);
      print('Generating FlatBuffer');
    } else {
      print('No active button or invalid setting');
    }
  }
}

class Register {
  String name;
  int address;
  double value;
  bool fixedPoint = true;

  Register(
      {required this.name,
      required this.address,
      required this.value,
      this.fixedPoint = true});
}

class SpinBox extends StatefulWidget {
  final double min;
  final double max;
  final double value;
  final ValueChanged<double> onChanged;

  SpinBox(
      {required this.min,
      required this.max,
      required this.value,
      required this.onChanged});

  @override
  _SpinBoxState createState() => _SpinBoxState();
}

class _SpinBoxState extends State<SpinBox> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.remove),
          onPressed: () {
            setState(() {
              if (_value > widget.min) {
                _value--;
                widget.onChanged(_value);
              }
            });
          },
        ),
        Text(_value.toStringAsFixed(0)),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () {
            setState(() {
              if (_value < widget.max) {
                _value++;
                widget.onChanged(_value);
              }
            });
          },
        ),
      ],
    );
  }
}

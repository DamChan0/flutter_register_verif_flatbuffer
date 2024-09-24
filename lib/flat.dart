import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:flat_buffers/flat_buffers.dart' as fb;
import 'config_chip_verif_generated.dart'; // 생성된 FlatBuffer Dart 파일

void generateFlatBuffer(List<String> registerNames, List<int> addresses,
    List<double> values, List<bool> fixedPoints) {
  final builder = fb.Builder(initialSize: 1024);

  // RegisterInfo 객체들 생성
  final List<RegisterInfoObjectBuilder> registerBuilders = List.generate(
    registerNames.length,
    (index) => RegisterInfoObjectBuilder(
      fieldname: registerNames[index],
      address: addresses[index],
      value: values[index],
      fixedpoint: fixedPoints[index],
    ),
  );

  // ChipTestConfig 객체 생성
  final chipTestConfigBuilder = ChipTestConfigObjectBuilder(
    chipfunctionname: "TestFunction",
    registers: registerBuilders,
    inputtype: 0,
    outputtype: 0,
  );

  // FlatBuffer로 직렬화
  final Uint8List buffer = chipTestConfigBuilder.toBytes();

  // 파일로 저장
  File('chip_config.bin').writeAsBytesSync(buffer);
  print("FlatBuffer saved to chip_config.bin");

  // 파일에서 읽기
  final Uint8List readBuffer = File('chip_config.bin').readAsBytesSync();

  // FlatBuffer 역직렬화
  final ChipTestConfig chipTestConfig = ChipTestConfig(readBuffer);

  // 데이터 출력
  print("Chip Function Name: ${chipTestConfig.chipfunctionname}");
  print("Input Type: ${chipTestConfig.inputtype}");
  print("Output Type: ${chipTestConfig.outputtype}");
  print("Number of Registers: ${chipTestConfig.registers?.length}");

  chipTestConfig.registers?.asMap().forEach((index, register) {
    print("Register $index:");
    print("  Field Name: ${register.fieldname}");
    print("  Address: 0x${register.address.toRadixString(16)}");
    print("  Value: ${register.value}");
    print("  Fixed Point: ${register.fixedpoint}");
  });
}

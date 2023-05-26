// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:math';

import 'package:bdk_flutter/bdk_flutter.dart' as bitcoin;
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  print("test");
  getAWallet();

  // testWidgets('Counter increments smoke test', (WidgetTester tester) async {
  //   // Build our app and trigger a frame.
  //   await tester.pumpWidget(MyApp());

  //   // Verify that our counter starts at 0.
  //   expect(find.text('0'), findsOneWidget);
  //   expect(find.text('1'), findsNothing);

  //   // Tap the '+' icon and trigger a frame.
  //   await tester.tap(find.byIcon(Icons.add));
  //   await tester.pump();

  //   // Verify that our counter has incremented.
  //   expect(find.text('0'), findsNothing);
  //   expect(find.text('1'), findsOneWidget);
  // });
}

void getAWallet() async {
  // Or generate a new key randomly
  Random rng = Random.secure();
  EthPrivateKey random = EthPrivateKey.createRandom(rng);
  String privateKey = bytesToHex(random.privateKey);
// In either way, the library can derive the public key and the address
// from a private key:
  EthereumAddress address = await random.address;

  print("ETH---->私钥：${privateKey} ,地址：${address.hexEip55}");
}

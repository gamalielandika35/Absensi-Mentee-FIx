import 'package:flutter/material.dart';
import 'qr_scanner.dart'; // kita akan bikin file ini pakai mobile_scanner

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Absensi Mentee NSOP',
      theme: ThemeData(primarySwatch: Colors.yellow),
      home: QrCodeScan(),
    );
  }
}

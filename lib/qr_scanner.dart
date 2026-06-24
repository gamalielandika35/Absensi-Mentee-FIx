import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'lihat_data.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

class QrCodeScan extends StatefulWidget {
  const QrCodeScan({super.key});

  @override
  _QrCodeScanState createState() => _QrCodeScanState();
}

class _QrCodeScanState extends State<QrCodeScan> {
  // Ganti warna sesuai tema
  final Color warnaUnguTua = const Color(0xFF541D03);
  final Color warnaPutih = const Color(0xFFFFFFFF);
  final Color warnaHijau = const Color.fromARGB(255, 39, 222, 7);
  final Color warnaMerah = const Color(0xFFD52529);
  final Color warnaHitam = const Color(0xFF000000);

  String result = "Menunggu QR Di Pindai";
  bool isScanning = false;
  bool isLoading = false;
  bool sudahKirim = false;
  bool isQrValid = false;
  bool isOnline = true;

  String? nim, nama, kelompok, timestamp;

  final String scriptURL =
      'https://script.google.com/macros/s/AKfycbz_aIZ6GwHl7ClElvHDuEd6Bfy1LuU2RxjCSesKuPVQXvTOkVyN9qFWyaLFFm2YQcFVXw/exec';

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    checkInternetConnection();
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => checkInternetConnection(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      setState(() {
        isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      });
    } on SocketException catch (_) {
      setState(() {
        isOnline = false;
      });
    }
  }

  void startScanner() {
    setState(() {
      isScanning = true;
      result = "Waiting QR Scan Text";
      sudahKirim = false;
      isQrValid = false;
    });
  }

  void stopScanner() {
    setState(() {
      isScanning = false;
    });
  }

  String getCurrentTimestamp() {
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}/"
        "${now.month.toString().padLeft(2, '0')}/"
        "${now.year}, ${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}";
  }

  Future<void> kirimDataKeSheet() async {
    if (nim != null &&
        nama != null &&
        kelompok != null &&
        timestamp != null &&
        !sudahKirim &&
        isQrValid) {
      setState(() => isLoading = true);

      try {
        await http
            .post(
              Uri.parse(scriptURL),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'nim': nim,
                'nama': nama,
                'kelompok': kelompok,
                'timestamp': timestamp,
              }),
            )
            .timeout(const Duration(seconds: 15));

        setState(() {
          isLoading = false;
          sudahKirim = true;
          result = "Waiting QR Scan Text";
          nim = nama = kelompok = timestamp = null;
          isQrValid = false;
        });

        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(
            0.2,
          ), // semi transparan di luar dialog
          builder: (context) => Stack(
            children: [
              // Blur seluruh layar di belakang dialog
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.transparent),
              ),
              // Dialog utama
              Center(
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: warnaMerah,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "✅ Berhasil Tercatat",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Data kehadiran kamu sudah tercatat di Google Sheet.",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: warnaUnguTua,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "OK",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } catch (e) {
        setState(() => isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("❌ Terjadi Kesalahan"),
            content: Text("Gagal mengirim data: $e"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: warnaUnguTua,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      appBar: AppBar(
        backgroundColor: warnaUnguTua,
        title: Row(
          children: [
            Image.asset('assets/logo.jpg', width: 35, height: 35),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Absensi NSOP",
                style: TextStyle(color: warnaPutih),
                overflow: TextOverflow
                    .ellipsis, // Mencegah teks meluap jika terlalu panjang
              ),
            ),
          ],
        ),
        centerTitle: false,
        iconTheme: IconThemeData(color: warnaPutih),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  color: isOnline ? warnaHijau : warnaMerah,
                  size: 12,
                ),
                const SizedBox(width: 5),
                Text(
                  isOnline ? "Online" : "Offline",
                  style: TextStyle(color: isOnline ? warnaHijau : warnaMerah),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gambar hutan dengan zoom
          SizedBox.expand(
            child: Transform.scale(
              scale: 1.3, // Zoom gambar background
              child: Image.asset('assets/hutan.jpg', fit: BoxFit.cover),
            ),
          ),
          // Konten utama tanpa blur
          SafeArea(
            child: Column(
              children: [
                // Tombol "Lihat Absensi"
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LihatDataPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: warnaMerah,
                        foregroundColor: warnaPutih,
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Lihat Absensi"),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Area utama
                Expanded(
                  child: Center(
                    child: isScanning
                        ? Stack(
                            children: [
                              // Kamera untuk scan QR
                              MobileScanner(
                                onDetect: (barcodeCapture) {
                                  final List<Barcode> barcodes =
                                      barcodeCapture.barcodes;
                                  if (barcodes.isNotEmpty) {
                                    final String? code =
                                        barcodes.first.rawValue;
                                    if (code != null) {
                                      List<String> parts = code.split(',');
                                      if (parts.length == 3) {
                                        setState(() {
                                          nim = parts[0].trim();
                                          nama = parts[1].trim();
                                          kelompok = parts[2].trim();
                                          timestamp = getCurrentTimestamp();
                                          result =
                                              '''
NIM        : $nim
Nama       : $nama
Kelompok   : $kelompok

Scanned at : $timestamp
''';
                                          isScanning = false;
                                          sudahKirim = false;
                                          isQrValid = true;
                                        });
                                      } else {
                                        setState(() {
                                          result =
                                              'Format QR tidak valid.\nPastikan format: NIM,Nama,Kelompok';
                                          isScanning = false;
                                          isQrValid = false;
                                        });
                                      }
                                    }
                                  }
                                },
                              ),
                              // Tombol stop scan
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: ElevatedButton(
                                    onPressed: stopScanner,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: warnaMerah,
                                      foregroundColor: warnaPutih,
                                    ),
                                    child: const Text("Stop Scanning"),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: nim == null
                                  ? MainAxisAlignment.center
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                const SizedBox(height: 40),
                                ClipOval(
                                  child: Image.asset(
                                    'assets/logo.jpg',
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      result,
                                      style: TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.w500,
                                        color: warnaHitam,
                                        height: 1.5,
                                        fontFamily: 'Courier',
                                      ),
                                      textAlign: nim == null
                                          ? TextAlign.center
                                          : TextAlign.left,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20.0),
                                ElevatedButton(
                                  onPressed: startScanner,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: warnaMerah,
                                    foregroundColor: warnaPutih,
                                  ),
                                  child: const Text(
                                    'Scan QR CODE',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Tombol Kirim Data
                                isLoading
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6.0,
                                        ),
                                        child: Column(
                                          children: [
                                            SizedBox(
                                              width: 120,
                                              height: 100,
                                              child: Lottie.asset(
                                                'assets/Loading.json',
                                                repeat: true,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              "Memproses...",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: warnaPutih,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed:
                                            (!isQrValid ||
                                                sudahKirim ||
                                                nim == null ||
                                                !isOnline)
                                            ? null
                                            : kirimDataKeSheet,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: warnaMerah,
                                          foregroundColor: warnaPutih,
                                        ),
                                        child: const Text(
                                          'Hadir',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

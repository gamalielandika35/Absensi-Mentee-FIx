import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class LihatDataPage extends StatefulWidget {
  const LihatDataPage({super.key});

  @override
  _LihatDataPageState createState() => _LihatDataPageState();
}

class _LihatDataPageState extends State<LihatDataPage> {
  // Tema warna sama seperti qr_scanner.dart
  final Color warnaUnguTua = const Color(0xFF541D03);
  final Color warnaPutih = const Color(0xFFFFFFFF);
  final Color warnaMerah = const Color(0xFFD52529);
  final Color warnaHitam = const Color(0xFF000000);

  List<List<dynamic>> data = [];
  List<List<dynamic>> filteredData = [];
  bool isLoading = true;
  Timer? autoRefreshTimer;

  final String spreadsheetUrl =
      'https://opensheet.elk.sh/1NvgQbvRv2sM4JhTcC73cBmuH43g9k_z6gJPeEnAm8DM/Data_Final';

  String kelompokFilter = 'Semua';
  String searchQuery = '';

  List<String> kelompokList = ['Semua'];

  Future<void> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse(spreadsheetUrl),
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        if (jsonData.isNotEmpty && jsonData.first is Map) {
          List<String> headers = (jsonData.first as Map<String, dynamic>).keys
              .toList();

          // Cari dan hapus kolom timestamp jika ada
          final timestampIndex = headers.indexWhere(
            (h) => h.toLowerCase() == 'timestamp',
          );

          final List<List<dynamic>> rows = [
            headers,
            ...jsonData.map((row) {
              final rowData = headers.map((key) => row[key] ?? '').toList();
              return rowData;
            }),
          ];

          // Ambil daftar kelompok unik
          final kelompokIndex = headers.indexWhere(
            (h) => h.toLowerCase().contains('kelompok'),
          );
          final kelompokSet = <String>{};
          for (var r in rows.skip(1)) {
            if (kelompokIndex != -1 && r.length > kelompokIndex) {
              kelompokSet.add(r[kelompokIndex].toString());
            }
          }
          kelompokList = [
            'Semua',
            ...kelompokSet.where((k) => k.trim().isNotEmpty),
          ];

          setState(() {
            data = rows;
            isLoading = false;
          });
          applyFilter();
        } else {
          setState(() {
            data = [];
            isLoading = false;
          });
        }
      } else {
        throw Exception('Gagal memuat data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        data = [];
      });
    }
  }

  void applyFilter() {
    if (data.isEmpty || data[0].isEmpty) {
      filteredData = [];
      return;
    }
    final headers = data[0];
    final kelompokIndex = headers.indexWhere(
      (h) => h.toLowerCase().contains('kelompok'),
    );
    final namaIndex = headers.indexWhere(
      (h) => h.toLowerCase().contains('nama'),
    );
    final nimIndex = headers.indexWhere((h) => h.toLowerCase().contains('nim'));

    filteredData = [
      headers,
      ...data.sublist(1).where((row) {
        final matchKelompok =
            kelompokFilter == 'Semua' ||
            (kelompokIndex != -1 &&
                row[kelompokIndex].toString() == kelompokFilter);
        final matchSearch =
            searchQuery.isEmpty ||
            (namaIndex != -1 &&
                row[namaIndex].toString().toLowerCase().contains(
                  searchQuery.toLowerCase(),
                )) ||
            (nimIndex != -1 &&
                row[nimIndex].toString().toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ));
        return matchKelompok && matchSearch;
      }).toList(),
    ];
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchData();
    });
  }

  @override
  void dispose() {
    autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedKelompokList = [
      'Semua',
      ...kelompokList.where((k) => k != 'Semua').toList()
        ..sort((a, b) => a.compareTo(b)),
    ];

    final jumlahHadir = filteredData.length > 1 ? filteredData.length - 1 : 0;

    return Scaffold(
      backgroundColor: warnaUnguTua,
      appBar: AppBar(
        title: const Text(
          "Data Absensi",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: warnaUnguTua,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              fetchData();
            },
            color: warnaPutih,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background hutan dengan zoom
          SizedBox.expand(
            child: Transform.scale(
              scale: 1.3,
              child: Image.asset('assets/hutan.jpg', fit: BoxFit.cover),
            ),
          ),
          // Overlay hitam tipis agar konten lebih kontras
          Container(color: warnaHitam.withOpacity(0.45)),
          // Konten utama
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      // Filter kelompok
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: kelompokFilter,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: warnaPutih.withOpacity(0.85),
                            labelText: "Kelompok",
                            labelStyle: TextStyle(color: warnaUnguTua),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          dropdownColor: warnaPutih,
                          iconEnabledColor: warnaUnguTua,
                          items: sortedKelompokList
                              .map(
                                (k) => DropdownMenuItem(
                                  value: k,
                                  child: Text(
                                    k,
                                    style: TextStyle(color: warnaUnguTua),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            kelompokFilter = val ?? 'Semua';
                            applyFilter();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Search nama/NIM
                      Expanded(
                        flex: 3,
                        child: TextField(
                          style: TextStyle(color: warnaUnguTua),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: warnaPutih.withOpacity(0.85),
                            labelText: "Cari Nama/NIM",
                            labelStyle: TextStyle(color: warnaUnguTua),
                            prefixIcon: Icon(Icons.search, color: warnaUnguTua),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (val) {
                            searchQuery = val;
                            applyFilter();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Tampilkan jumlah hadir
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Card(
                    color: warnaPutih.withOpacity(0.85),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.people, color: warnaUnguTua, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            "Jumlah Hadir: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: warnaUnguTua,
                              fontSize: 16,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "$jumlahHadir",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: warnaMerah,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : filteredData.isEmpty || filteredData[0].isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada data',
                            style: TextStyle(color: warnaPutih, fontSize: 18),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    warnaUnguTua.withOpacity(0.9),
                                  ),
                                  dataRowColor: WidgetStateProperty.all(
                                    warnaPutih.withOpacity(0.85),
                                  ),
                                  columnSpacing: 24,
                                  columns: _buildColumns(),
                                  rows: _buildRows(),
                                ),
                              ),
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

  List<DataColumn> _buildColumns() {
    if (filteredData.isEmpty) return [];
    final headers = filteredData[0];
    return headers
        .where((h) => h.toString().toLowerCase() != 'timestamp')
        .map<DataColumn>((header) {
          return DataColumn(
            label: Text(
              header.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: warnaPutih,
              ),
            ),
          );
        })
        .toList();
  }

  List<DataRow> _buildRows() {
    if (filteredData.length < 2) return [];
    final headers = filteredData[0];
    final timestampIndex = headers.indexWhere(
      (h) => h.toString().toLowerCase() == 'timestamp',
    );
    final statusIndex = headers.indexWhere(
      (h) => h.toString().toLowerCase() == 'status',
    );

    return filteredData.sublist(1).map<DataRow>((row) {
      return DataRow(
        color: WidgetStateProperty.resolveWith<Color?>((states) {
          // Jika kolom status ada dan nilainya "Telat", warnai baris
          if (statusIndex != -1 &&
              row.length > statusIndex &&
              row[statusIndex].toString().toLowerCase() == 'telat') {
            return Colors.red.withOpacity(
              0.5,
            ); // Warna merah untuk status "Telat"
          }
          // Untuk baris lainnya, gunakan warna putih semi-transparan yang sudah didefinisikan di DataTable
          return warnaPutih.withOpacity(0.85);
        }),
        cells:
            row //
                .asMap()
                .entries
                .where((entry) => entry.key != timestampIndex)
                .map<DataCell>((entry) {
                  return DataCell(
                    Text(
                      entry.value.toString(),
                      style: TextStyle(fontSize: 14, color: warnaHitam),
                    ),
                  );
                })
                .toList(),
      );
    }).toList();
  }
}

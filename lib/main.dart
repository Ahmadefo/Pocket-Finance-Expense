import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PocketExpenseApp());
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    double value = double.parse(digitsOnly);
    String formatted = _formatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PocketExpenseApp extends StatelessWidget {
  const PocketExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Expense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF3498DB),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3498DB)),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class IconOption {
  final IconData icon;
  final String name;
  IconOption(this.icon, this.name);
}

final List<IconOption> availableIcons = [
  IconOption(Icons.fastfood, 'Makanan'),
  IconOption(Icons.home, 'Kos/Rumah'),
  IconOption(Icons.shopping_bag, 'Belanja'),
  IconOption(Icons.local_gas_station, 'Bensin'),
  IconOption(Icons.movie, 'Hiburan'),
  IconOption(Icons.receipt_long, 'Tagihan'),
  IconOption(Icons.medical_services, 'Kesehatan'),
  IconOption(Icons.directions_car, 'Kendaraan'),
  IconOption(Icons.school, 'Edukasi'),
  IconOption(Icons.account_balance_wallet, 'Lainnya'),
];

class Pocket {
  String id;
  String name;
  double budget;
  IconData icon;
  Color color;

  Pocket({
    required this.id,
    required this.name,
    required this.budget,
    this.icon = Icons.account_balance_wallet,
    this.color = Colors.blue,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'budget': budget,
        'iconCodePoint': icon.codePoint,
      };

  factory Pocket.fromJson(Map<String, dynamic> json) => Pocket(
        id: json['id'],
        name: json['name'],
        budget: (json['budget'] as num).toDouble(),
        icon: IconData(json['iconCodePoint'] ?? Icons.account_balance_wallet.codePoint, fontFamily: 'MaterialIcons'),
      );
}

class TransactionItem {
  String id;
  String type;
  String pocketId;
  String pocketName;
  double amount;
  String note;
  DateTime date;

  TransactionItem({
    required this.id,
    required this.type,
    required this.pocketId,
    required this.pocketName,
    required this.amount,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'pocketId': pocketId,
        'pocketName': pocketName,
        'amount': amount,
        'note': note,
        'date': date.toIso8601String(),
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) => TransactionItem(
        id: json['id'],
        type: json['type'],
        pocketId: json['pocketId'],
        pocketName: json['pocketName'],
        amount: (json['amount'] as num).toDouble(),
        note: json['note'],
        date: DateTime.parse(json['date']),
      );
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  bool _isLoading = true;

  List<Pocket> pockets = [
    Pocket(id: '1', name: 'Makan', budget: 1000000, icon: Icons.fastfood, color: Colors.orange),
    Pocket(id: '2', name: 'Kos', budget: 1400000, icon: Icons.home, color: Colors.purple),
    Pocket(id: '3', name: 'Belanja', budget: 500000, icon: Icons.shopping_bag, color: Colors.teal),
  ];

  List<TransactionItem> transactions = [];

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final String? pocketsString = prefs.getString('saved_pockets');
    if (pocketsString != null) {
      final List dynamicList = jsonDecode(pocketsString);
      pockets = dynamicList.map((item) => Pocket.fromJson(item)).toList();
    }

    final String? transactionsString = prefs.getString('saved_transactions');
    if (transactionsString != null) {
      final List dynamicList = jsonDecode(transactionsString);
      transactions = dynamicList.map((item) => TransactionItem.fromJson(item)).toList();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final String pocketsString = jsonEncode(pockets.map((p) => p.toJson()).toList());
    await prefs.setString('saved_pockets', pocketsString);

    final String transactionsString = jsonEncode(transactions.map((t) => t.toJson()).toList());
    await prefs.setString('saved_transactions', transactionsString);
  }

  void _addTransaction(TransactionItem tx) {
    setState(() {
      transactions.insert(0, tx);
    });
    _saveLocalData();
  }

  void _editTransaction(TransactionItem updatedTx) {
    setState(() {
      final index = transactions.indexWhere((t) => t.id == updatedTx.id);
      if (index != -1) {
        transactions[index] = updatedTx;
      }
    });
    _saveLocalData();
  }

  void _deleteTransaction(String id) {
    setState(() {
      transactions.removeWhere((t) => t.id == id);
    });
    _saveLocalData();
  }

  void _addPocket(Pocket pocket) {
    setState(() => pockets.add(pocket));
    _saveLocalData();
  }

  void _editPocket(String id, String newName, double newBudget, IconData newIcon) {
    setState(() {
      final p = pockets.firstWhere((element) => element.id == id);
      p.name = newName;
      p.budget = newBudget;
      p.icon = newIcon;
    });
    _saveLocalData();
  }

  void _deletePocket(String id) {
    setState(() {
      pockets.removeWhere((p) => p.id == id);
      transactions.removeWhere((t) => t.pocketId == id);
    });
    _saveLocalData();
  }

  double _getPocketSpentForMonth(String pocketId, int month, int year) {
    return transactions
        .where((t) => t.type == 'Pengeluaran' && t.pocketId == pocketId && t.date.month == month && t.date.year == year)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  String _listToCsv(List<List<dynamic>> rows) {
    return rows.map((row) {
      return row.map((field) {
        String str = field.toString().replaceAll('"', '""');
        if (str.contains(',') || str.contains('\n') || str.contains('"')) {
          return '"$str"';
        }
        return str;
      }).join(',');
    }).join('\n');
  }

  List<List<String>> _csvToList(String csvText) {
    List<List<String>> rows = [];
    List<String> lines = const LineSplitter().convert(csvText);
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      rows.add(line.split(',').map((e) => e.replaceAll('"', '').trim()).toList());
    }
    return rows;
  }

  Future<void> _exportDataToCsv(BuildContext context) async {
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belum ada transaksi untuk diekspor.')));
      return;
    }

    final Map<int, String> monthNames = {
      1: 'Januari', 2: 'Februari', 3: 'Maret', 4: 'April', 5: 'Mei', 6: 'Juni',
      7: 'Juli', 8: 'Agustus', 9: 'September', 10: 'Oktober', 11: 'November', 12: 'Desember',
    };

    List<List<dynamic>> rows = [];
    rows.add(['No', 'Tanggal Transaksi', 'Bulan', 'Kantong', 'Keterangan Transaksi', 'Tipe', 'Jumlah']);

    for (int i = 0; i < transactions.length; i++) {
      final tx = transactions[i];
      rows.add([
        i + 1,
        DateFormat('yyyy-MM-dd').format(tx.date),
        monthNames[tx.date.month],
        tx.pocketName,
        tx.note,
        tx.type,
        tx.amount,
      ]);
    }

    String csvData = _listToCsv(rows);
    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'pocket_expense_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final path = '${directory.path}/$fileName';
      final file = File(path);
      await file.writeAsString(csvData);

      await Share.shareXFiles([XFile(path)], text: 'Backup Data Pocket Expense (CSV)');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengekspor file: $e')));
    }
  }

  void _importDataFromCsv(BuildContext context) {
    final textCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Impor Data CSV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tempelkan teks isi file CSV kamu di bawah ini:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: textCtrl,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'No,Tanggal Transaksi,Bulan,Kantong...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (textCtrl.text.isNotEmpty) {
                try {
                  final List<List<String>> fields = _csvToList(textCtrl.text);
                  if (fields.length <= 1) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Format CSV tidak valid.')));
                    return;
                  }

                  int importedCount = 0;
                  for (int i = 1; i < fields.length; i++) {
                    final row = fields[i];
                    if (row.length >= 7) {
                      final dateStr = row[1];
                      final pocketNameStr = row[3];
                      final noteStr = row[4];
                      final typeStr = row[5];
                      final amountNum = double.tryParse(row[6]) ?? 0.0;

                      final parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();

                      String pId = 'income';
                      if (typeStr == 'Pengeluaran') {
                        final existingPocket = pockets.firstWhere(
                          (p) => p.name.toLowerCase() == pocketNameStr.toLowerCase(),
                          orElse: () {
                            final newP = Pocket(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              name: pocketNameStr,
                              budget: 1000000,
                            );
                            pockets.add(newP);
                            return newP;
                          },
                        );
                        pId = existingPocket.id;
                      }

                      transactions.insert(0, TransactionItem(
                        id: '${DateTime.now().millisecondsSinceEpoch}_$i',
                        type: typeStr,
                        pocketId: pId,
                        pocketName: pocketNameStr,
                        amount: amountNum,
                        note: noteStr,
                        date: parsedDate,
                      ));
                      importedCount++;
                    }
                  }

                  await _saveLocalData();
                  setState(() {});
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Berhasil mengimpor $importedCount transaksi!')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal impor: $e')));
                }
              }
            },
            child: const Text('Impor'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      BudgetStatusTab(
        pockets: pockets,
        transactions: transactions,
        getSpent: _getPocketSpentForMonth,
        onEditTx: _editTransaction,
        onDeleteTx: _deleteTransaction,
      ),
      PocketTab(
        pockets: pockets,
        onAddPocket: _addPocket,
        onEditPocket: _editPocket,
        onDeletePocket: _deletePocket,
      ),
      IncomeTab(
        transactions: transactions.where((t) => t.type == 'Pemasukan').toList(),
        onEditIncome: _editTransaction,
        onDeleteIncome: _deleteTransaction,
      ),
      ChartTab(
        transactions: transactions,
        pockets: pockets,
      ),
    ];

    Widget? currentFab;
    if (_currentIndex == 1) {
      currentFab = FloatingActionButton.extended(
        key: const ValueKey('btn_add_pocket_tab'),
        onPressed: () => _showAddPocketDialog(context),
        backgroundColor: const Color(0xFF3498DB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('+ Kantong', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    } else if (_currentIndex == 3) {
      currentFab = Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'btn_import',
            onPressed: () => _importDataFromCsv(context),
            backgroundColor: Colors.teal,
            icon: const Icon(Icons.file_upload, color: Colors.white),
            label: const Text('Impor CSV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.extended(
            heroTag: 'btn_export',
            onPressed: () => _exportDataToCsv(context),
            backgroundColor: Colors.orange,
            icon: const Icon(Icons.file_download, color: Colors.white),
            label: const Text('Ekspor CSV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    } else {
      currentFab = FloatingActionButton.extended(
        key: const ValueKey('btn_add_tx_tab'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionFormPage(
                pockets: pockets,
                onSave: _addTransaction,
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF3498DB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3498DB),
        foregroundColor: Colors.white,
        title: const Text('Pocket Expense', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: pages[_currentIndex],
      floatingActionButton: currentFab,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3498DB),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), label: 'Sisa Budget'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Kantong'),
          BottomNavigationBarItem(icon: Icon(Icons.arrow_downward), label: 'Pendapatan'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Grafik'),
        ],
      ),
    );
  }

  void _showAddPocketDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    IconData selectedIcon = availableIcons.first.icon;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Tambah Kantong Baru'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Kantong')),
                  TextField(
                    controller: budgetCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(labelText: 'Target Budget (Rp)'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Pilih Ikon:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: availableIcons.map((opt) {
                      final isSelected = selectedIcon == opt.icon;
                      return InkWell(
                        onTap: () => setDialogState(() => selectedIcon = opt.icon),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF3498DB).withValues(alpha: 0.2) : Colors.grey[100],
                            border: Border.all(color: isSelected ? const Color(0xFF3498DB) : Colors.transparent, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(opt.icon, color: isSelected ? const Color(0xFF3498DB) : Colors.grey[700]),
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty && budgetCtrl.text.isNotEmpty) {
                    final cleanBudgetStr = budgetCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
                    _addPocket(Pocket(
                      id: DateTime.now().toString(),
                      name: nameCtrl.text,
                      budget: double.parse(cleanBudgetStr),
                      icon: selectedIcon,
                      color: Colors.blueAccent,
                    ));
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Simpan'),
              )
            ],
          );
        },
      ),
    );
  }
}

class BudgetStatusTab extends StatefulWidget {
  final List<Pocket> pockets;
  final List<TransactionItem> transactions;
  final double Function(String pocketId, int month, int year) getSpent;
  final Function(TransactionItem) onEditTx;
  final Function(String) onDeleteTx;

  const BudgetStatusTab({
    super.key,
    required this.pockets,
    required this.transactions,
    required this.getSpent,
    required this.onEditTx,
    required this.onDeleteTx,
  });

  @override
  State<BudgetStatusTab> createState() => _BudgetStatusTabState();
}

class _BudgetStatusTabState extends State<BudgetStatusTab> {
  late int selectedMonth;
  late int selectedYear;

  final Map<int, String> monthNames = {
    1: 'Januari', 2: 'Februari', 3: 'Maret', 4: 'April', 5: 'Mei', 6: 'Juni',
    7: 'Juli', 8: 'Agustus', 9: 'September', 10: 'Oktober', 11: 'November', 12: 'Desember',
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = now.month;
    selectedYear = now.year;
  }

  void _showPocketDetail(BuildContext context, Pocket pocket) {
    final currencyFormatter = NumberFormat('#,##0', 'en_US');

    final pocketTxList = widget.transactions
        .where((t) => t.type == 'Pengeluaran' && t.pocketId == pocket.id && t.date.month == selectedMonth && t.date.year == selectedYear)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentSpent = widget.getSpent(pocket.id, selectedMonth, selectedYear);
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              builder: (_, controller) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(pocket.icon, color: const Color(0xFF3498DB)),
                          const SizedBox(width: 8),
                          Text('Transaksi: ${pocket.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text('Pengeluaran ${monthNames[selectedMonth]} $selectedYear: Rp ${currencyFormatter.format(currentSpent)}',
                          style: const TextStyle(color: Colors.grey)),
                      const Divider(height: 24),
                      Expanded(
                        child: pocketTxList.isEmpty
                            ? Center(child: Text('Belum ada pengeluaran di ${monthNames[selectedMonth]} $selectedYear.'))
                            : ListView.builder(
                                controller: controller,
                                itemCount: pocketTxList.length,
                                itemBuilder: (context, index) {
                                  final tx = pocketTxList[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: Colors.redAccent,
                                        child: Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                                      ),
                                      title: Text(tx.note.isEmpty ? pocket.name : tx.note, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(DateFormat('dd MMM yyyy').format(tx.date)),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '- Rp ${currencyFormatter.format(tx.amount)}',
                                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                          ),
                                          PopupMenuButton<String>(
                                            onSelected: (val) {
                                              if (val == 'edit') {
                                                _showEditTransactionDialog(context, tx);
                                              } else if (val == 'delete') {
                                                widget.onDeleteTx(tx.id);
                                                setModalState(() {
                                                  pocketTxList.removeWhere((t) => t.id == tx.id);
                                                });
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                              const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: Colors.red))),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showEditTransactionDialog(BuildContext context, TransactionItem tx) {
    final formatter = NumberFormat('#,##0', 'en_US');
    final amountCtrl = TextEditingController(text: formatter.format(tx.amount));
    final noteCtrl = TextEditingController(text: tx.note);
    DateTime selectedDate = tx.date;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Transaksi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
                ),
                TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Keterangan')),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                )
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () {
                  if (amountCtrl.text.isNotEmpty) {
                    final cleanAmount = amountCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
                    tx.amount = double.parse(cleanAmount);
                    tx.note = noteCtrl.text;
                    tx.date = selectedDate;
                    widget.onEditTx(tx);
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Simpan'),
              )
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0', 'en_US');

    final currentYearNow = DateTime.now().year;
    final List<int> availableYears = List.generate(
      (currentYearNow + 2) - 2024 + 1,
      (index) => 2024 + index,
    );

    if (!availableYears.contains(selectedYear)) {
      availableYears.add(selectedYear);
      availableYears.sort();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filter Periode:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Row(
                children: [
                  DropdownButton<int>(
                    value: selectedMonth,
                    items: monthNames.entries.map((e) {
                      return DropdownMenuItem(value: e.key, child: Text(e.value));
                    }).toList(),
                    onChanged: (v) => setState(() => selectedMonth = v!),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: selectedYear,
                    items: availableYears.map((y) {
                      return DropdownMenuItem(value: y, child: Text('$y'));
                    }).toList(),
                    onChanged: (v) => setState(() => selectedYear = v!),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.pockets.length,
            itemBuilder: (ctx, i) {
              final p = widget.pockets[i];
              final spent = widget.getSpent(p.id, selectedMonth, selectedYear);
              final remaining = p.budget - spent;
              final percent = (spent / p.budget).clamp(0.0, 1.0);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => _showPocketDetail(context, p),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(p.icon, color: const Color(0xFF3498DB)),
                                const SizedBox(width: 8),
                                Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            Text(
                              'Sisa: Rp ${currencyFormatter.format(remaining)}',
                              style: TextStyle(
                                color: remaining < 0 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: percent,
                          backgroundColor: Colors.grey[200],
                          color: percent > 0.9 ? Colors.red : const Color(0xFF3498DB),
                          minHeight: 10,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Terpakai: Rp ${currencyFormatter.format(spent)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('Budget: Rp ${currencyFormatter.format(p.budget)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class PocketTab extends StatelessWidget {
  final List<Pocket> pockets;
  final Function(Pocket) onAddPocket;
  final Function(String, String, double, IconData) onEditPocket;
  final Function(String) onDeletePocket;

  const PocketTab({
    super.key,
    required this.pockets,
    required this.onAddPocket,
    required this.onEditPocket,
    required this.onDeletePocket,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0', 'en_US');

    return Scaffold(
      body: pockets.isEmpty
          ? const Center(child: Text('Belum ada kantong pengeluaran.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: pockets.length,
              itemBuilder: (ctx, i) {
                final p = pockets[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF3498DB).withValues(alpha: 0.2),
                      child: Icon(p.icon, color: const Color(0xFF3498DB)),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Budget Bulanan: Rp ${currencyFormatter.format(p.budget)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditDialog(context, p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => onDeletePocket(p.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showEditDialog(BuildContext context, Pocket pocket) {
    final formatter = NumberFormat('#,##0', 'en_US');
    final nameCtrl = TextEditingController(text: pocket.name);
    final budgetCtrl = TextEditingController(text: formatter.format(pocket.budget));
    IconData selectedIcon = pocket.icon;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Kantong'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Kantong')),
                  TextField(
                    controller: budgetCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(labelText: 'Budget (Rp)'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Pilih Ikon:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: availableIcons.map((opt) {
                      final isSelected = selectedIcon == opt.icon;
                      return InkWell(
                        onTap: () => setDialogState(() => selectedIcon = opt.icon),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF3498DB).withValues(alpha: 0.2) : Colors.grey[100],
                            border: Border.all(color: isSelected ? const Color(0xFF3498DB) : Colors.transparent, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(opt.icon, color: isSelected ? const Color(0xFF3498DB) : Colors.grey[700]),
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty && budgetCtrl.text.isNotEmpty) {
                    final cleanBudgetStr = budgetCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
                    onEditPocket(pocket.id, nameCtrl.text, double.parse(cleanBudgetStr), selectedIcon);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Update'),
              )
            ],
          );
        },
      ),
    );
  }
}

class IncomeTab extends StatefulWidget {
  final List<TransactionItem> transactions;
  final Function(TransactionItem) onEditIncome;
  final Function(String) onDeleteIncome;

  const IncomeTab({
    super.key,
    required this.transactions,
    required this.onEditIncome,
    required this.onDeleteIncome,
  });

  @override
  State<IncomeTab> createState() => _IncomeTabState();
}

class _IncomeTabState extends State<IncomeTab> {
  late int selectedMonth;
  late int selectedYear;

  final Map<int, String> monthNames = {
    1: 'Januari', 2: 'Februari', 3: 'Maret', 4: 'April', 5: 'Mei', 6: 'Juni',
    7: 'Juli', 8: 'Agustus', 9: 'September', 10: 'Oktober', 11: 'November', 12: 'Desember',
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = now.month;
    selectedYear = now.year;
  }

  void _showEditIncomeDialog(BuildContext context, TransactionItem tx) {
    final formatter = NumberFormat('#,##0', 'en_US');
    final amountCtrl = TextEditingController(text: formatter.format(tx.amount));
    final noteCtrl = TextEditingController(text: tx.note);
    DateTime selectedDate = tx.date;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Pendapatan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
                ),
                TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Keterangan')),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  widget.onDeleteIncome(tx.id);
                  Navigator.pop(ctx);
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (amountCtrl.text.isNotEmpty) {
                    final cleanAmount = amountCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
                    tx.amount = double.parse(cleanAmount);
                    tx.note = noteCtrl.text;
                    tx.date = selectedDate;
                    widget.onEditIncome(tx);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Simpan'),
              )
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0', 'en_US');

    final currentYearNow = DateTime.now().year;
    final List<int> availableYears = List.generate(
      (currentYearNow + 2) - 2024 + 1,
      (index) => 2024 + index,
    );

    if (!availableYears.contains(selectedYear)) {
      availableYears.add(selectedYear);
      availableYears.sort();
    }

    final filteredTransactions = widget.transactions
        .where((t) => t.date.month == selectedMonth && t.date.year == selectedYear)
        .toList();

    final totalIncome = filteredTransactions.fold(0.0, (sum, item) => sum + item.amount);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filter Periode:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Row(
                children: [
                  DropdownButton<int>(
                    value: selectedMonth,
                    items: monthNames.entries.map((e) {
                      return DropdownMenuItem(value: e.key, child: Text(e.value));
                    }).toList(),
                    onChanged: (v) => setState(() => selectedMonth = v!),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: selectedYear,
                    items: availableYears.map((y) {
                      return DropdownMenuItem(value: y, child: Text('$y'));
                    }).toList(),
                    onChanged: (v) => setState(() => selectedYear = v!),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: Colors.green[100],
          child: Column(
            children: [
              Text(
                'Total Pendapatan (${monthNames[selectedMonth]} $selectedYear)',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Rp ${currencyFormatter.format(totalIncome)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredTransactions.isEmpty
              ? Center(child: Text('Belum ada data pendapatan di bulan ${monthNames[selectedMonth]} $selectedYear.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (ctx, i) {
                    final tx = filteredTransactions[i];
                    return Card(
                      child: ListTile(
                        onTap: () => _showEditIncomeDialog(context, tx),
                        leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.arrow_downward, color: Colors.white)),
                        title: Text(tx.pocketName),
                        subtitle: Text('${DateFormat('dd MMM yyyy').format(tx.date)}${tx.note.isNotEmpty ? ' - ${tx.note}' : ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('+ Rp ${currencyFormatter.format(tx.amount)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }
}

class ChartTab extends StatefulWidget {
  final List<TransactionItem> transactions;
  final List<Pocket> pockets;

  const ChartTab({super.key, required this.transactions, required this.pockets});

  @override
  State<ChartTab> createState() => _ChartTabState();
}

class _ChartTabState extends State<ChartTab> {
  late int selectedMonth;
  late int selectedYear;

  final Map<int, String> monthNames = {
    0: 'Semua Bulan (1 Tahun)',
    1: 'Januari', 2: 'Februari', 3: 'Maret', 4: 'April', 5: 'Mei', 6: 'Juni',
    7: 'Juli', 8: 'Agustus', 9: 'September', 10: 'Oktober', 11: 'November', 12: 'Desember',
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = now.month;
    selectedYear = now.year;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0', 'en_US');

    final currentYearNow = DateTime.now().year;
    final List<int> availableYears = List.generate(
      (currentYearNow + 2) - 2024 + 1,
      (index) => 2024 + index,
    );

    if (!availableYears.contains(selectedYear)) {
      availableYears.add(selectedYear);
      availableYears.sort();
    }

    final filteredExpense = widget.transactions.where((t) {
      final isMonthMatch = selectedMonth == 0 || t.date.month == selectedMonth;
      return t.type == 'Pengeluaran' && isMonthMatch && t.date.year == selectedYear;
    }).toList();

    final filteredIncome = widget.transactions.where((t) {
      final isMonthMatch = selectedMonth == 0 || t.date.month == selectedMonth;
      return t.type == 'Pemasukan' && isMonthMatch && t.date.year == selectedYear;
    }).toList();

    double totalExpense = filteredExpense.fold(0, (sum, item) => sum + item.amount);
    double totalIncome = filteredIncome.fold(0, (sum, item) => sum + item.amount);
    double remainingBalance = totalIncome - totalExpense;

    Map<String, double> pocketTotals = {};
    for (var p in widget.pockets) {
      pocketTotals[p.name] = 0;
    }
    for (var tx in filteredExpense) {
      pocketTotals[tx.pocketName] = (pocketTotals[tx.pocketName] ?? 0) + tx.amount;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<int>(
                value: selectedMonth,
                items: monthNames.entries.map((e) {
                  return DropdownMenuItem(value: e.key, child: Text(e.value));
                }).toList(),
                onChanged: (v) => setState(() => selectedMonth = v!),
              ),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: selectedYear,
                items: availableYears.map((y) {
                  return DropdownMenuItem(value: y, child: Text('$y'));
                }).toList(),
                onChanged: (v) => setState(() => selectedYear = v!),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: remainingBalance >= 0 ? Colors.blue[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: remainingBalance >= 0 ? Colors.blue : Colors.red),
            ),
            child: Column(
              children: [
                Text(
                  selectedMonth == 0 ? 'Sisa Saldo Tahun $selectedYear' : 'Sisa Saldo ${monthNames[selectedMonth]} $selectedYear',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp ${currencyFormatter.format(remainingBalance)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: remainingBalance >= 0 ? Colors.blue[800] : Colors.red[800],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Pendapatan: Rp ${currencyFormatter.format(totalIncome)}', style: const TextStyle(fontSize: 11, color: Colors.green)),
                    Text('Pengeluaran: Rp ${currencyFormatter.format(totalExpense)}', style: const TextStyle(fontSize: 11, color: Colors.red)),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 16),
          Expanded(
            child: filteredExpense.isEmpty
                ? const Center(child: Text('Tidak ada pengeluaran pada periode ini.'))
                : Column(
                    children: [
                      SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sections: widget.pockets.map((p) {
                              final total = pocketTotals[p.name] ?? 0;
                              return PieChartSectionData(
                                color: p.color,
                                value: total == 0 ? 1 : total,
                                title: total > 0 ? '${p.name}\nRp ${currencyFormatter.format(total)}' : '',
                                radius: 55,
                                titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          children: pocketTotals.entries.map((e) {
                            return ListTile(
                              title: Text(e.key),
                              trailing: Text('Rp ${currencyFormatter.format(e.value)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                        ),
                      )
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class TransactionFormPage extends StatefulWidget {
  final List<Pocket> pockets;
  final Function(TransactionItem) onSave;

  const TransactionFormPage({super.key, required this.pockets, required this.onSave});

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  String selectedType = 'Pengeluaran';
  DateTime selectedDate = DateTime.now();
  String? selectedPocketId;
  String? selectedIncomeCategory = 'Gaji';

  final incomeCategories = ['Gaji', 'Pemasukan lainnya', 'Hibah'];
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.pockets.isNotEmpty) {
      selectedPocketId = widget.pockets.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0', 'en_US');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3498DB),
        foregroundColor: Colors.white,
        title: const Text('Buat Transaksi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedType == 'Pengeluaran' ? Colors.redAccent : Colors.grey[200],
                            foregroundColor: selectedType == 'Pengeluaran' ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () => setState(() => selectedType = 'Pengeluaran'),
                          child: const Text('Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedType == 'Pemasukan' ? Colors.green : Colors.grey[200],
                            foregroundColor: selectedType == 'Pemasukan' ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () => setState(() => selectedType = 'Pemasukan'),
                          child: const Text('Pemasukan', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const SizedBox(width: 95, child: Text('Tanggal', style: TextStyle(fontSize: 15))),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => selectedDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(6)),
                            child: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(width: 95, child: Text(selectedType == 'Pengeluaran' ? 'Kantong' : 'Kategori', style: const TextStyle(fontSize: 15))),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(6)),
                          child: DropdownButtonHideUnderline(
                            child: selectedType == 'Pengeluaran'
                                ? DropdownButton<String>(
                                    value: selectedPocketId,
                                    isExpanded: true,
                                    items: widget.pockets.map((p) {
                                      return DropdownMenuItem(
                                        value: p.id,
                                        child: Text('${p.name} (Budget: Rp ${currencyFormatter.format(p.budget)})'),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setState(() => selectedPocketId = val),
                                  )
                                : DropdownButton<String>(
                                    value: selectedIncomeCategory,
                                    isExpanded: true,
                                    items: incomeCategories.map((cat) {
                                      return DropdownMenuItem(value: cat, child: Text(cat));
                                    }).toList(),
                                    onChanged: (val) => setState(() => selectedIncomeCategory = val),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SizedBox(width: 95, child: Text('Jumlah', style: TextStyle(fontSize: 15))),
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandsSeparatorInputFormatter()],
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 95, child: Text('Keterangan', style: TextStyle(fontSize: 15))),
                      Expanded(
                        child: TextField(
                          controller: noteController,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3498DB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () {
                  if (amountController.text.isEmpty) return;

                  String pId = '';
                  String pName = '';

                  if (selectedType == 'Pengeluaran') {
                    if (selectedPocketId == null) return;
                    final pocket = widget.pockets.firstWhere((p) => p.id == selectedPocketId);
                    pId = pocket.id;
                    pName = pocket.name;
                  } else {
                    pId = 'income';
                    pName = selectedIncomeCategory ?? 'Gaji';
                  }

                  final cleanAmountStr = amountController.text.replaceAll(RegExp(r'[^\d]'), '');

                  final item = TransactionItem(
                    id: DateTime.now().toString(),
                    type: selectedType,
                    pocketId: pId,
                    pocketName: pName,
                    amount: double.parse(cleanAmountStr),
                    note: noteController.text,
                    date: selectedDate,
                  );
                  widget.onSave(item);
                  Navigator.pop(context);
                },
                child: const Text('SIMPAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

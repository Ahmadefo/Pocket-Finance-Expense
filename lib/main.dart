import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const PocketExpenseApp());
}

class PocketExpenseApp extends StatelessWidget {
  const PocketExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Pocket',
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

// --- MODEL DATA ---
class Pocket {
  String id;
  String name;
  double budget;
  double spent;
  IconData icon;
  Color color;

  Pocket({
    required this.id,
    required this.name,
    required this.budget,
    this.spent = 0,
    this.icon = Icons.account_balance_wallet,
    this.color = Colors.blue,
  });

  double get remaining => budget - spent;
}

class TransactionItem {
  String id;
  String type; // 'Pengeluaran' atau 'Pemasukan'
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
}

// --- MAIN PAGE WITH NAVIGATION ---
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  List<Pocket> pockets = [
    Pocket(id: '1', name: 'Makan', budget: 1000000, spent: 0, icon: Icons.fastfood, color: Colors.orange),
    Pocket(id: '2', name: 'Kos', budget: 1400000, spent: 0, icon: Icons.home, color: Colors.purple),
    Pocket(id: '3', name: 'Belanja', budget: 500000, spent: 0, icon: Icons.shopping_bag, color: Colors.teal),
  ];

  List<TransactionItem> transactions = [];
  double totalIncome = 0;

  void _addTransaction(TransactionItem tx) {
    setState(() {
      transactions.insert(0, tx);
      if (tx.type == 'Pengeluaran') {
        final pocket = pockets.firstWhere((p) => p.id == tx.pocketId);
        pocket.spent += tx.amount;
      } else {
        totalIncome += tx.amount;
      }
    });
  }

  void _addPocket(Pocket pocket) {
    setState(() => pockets.add(pocket));
  }

  void _editPocket(String id, String newName, double newBudget) {
    setState(() {
      final p = pockets.firstWhere((element) => element.id == id);
      p.name = newName;
      p.budget = newBudget;
    });
  }

  void _deletePocket(String id) {
    setState(() {
      pockets.removeWhere((p) => p.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      PocketTab(
        pockets: pockets,
        onAddPocket: _addPocket,
        onEditPocket: _editPocket,
        onDeletePocket: _deletePocket,
      ),
      BudgetStatusTab(pockets: pockets),
      IncomeTab(
        transactions: transactions.where((t) => t.type == 'Pemasukan').toList(),
        totalIncome: totalIncome,
        onAddIncome: (tx) => _addTransaction(tx),
      ),
      ChartTab(transactions: transactions, pockets: pockets),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3498DB),
        foregroundColor: Colors.white,
        title: const Text('Kantong Pencatatan Uang', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: pages[_currentIndex],
      floatingActionButton: FloatingActionButton.extended(
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3498DB),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Kantong'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), label: 'Sisa Budget'),
          BottomNavigationBarItem(icon: Icon(Icons.arrow_downward), label: 'Pendapatan'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Grafik'),
        ],
      ),
    );
  }
}

// ==========================================
// FORM TRANSAKSI (Sesuai dengan Tampilan Gambar)
// ==========================================
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
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3498DB),
        foregroundColor: Colors.white,
        title: const Text('Buat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {},
          )
        ],
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
                  // Toggle Pengeluaran / Pemasukan
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

                  // Tanggal
                  Row(
                    children: [
                      const SizedBox(width: 80, child: Text('Tanggal', style: TextStyle(fontSize: 15))),
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
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Kategori / Kantong
                  Row(
                    children: [
                      SizedBox(width: 80, child: Text(selectedType == 'Pengeluaran' ? 'Kantong' : 'Kategori', style: const TextStyle(fontSize: 15))),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedPocketId,
                              isExpanded: true,
                              items: widget.pockets.map((p) {
                                return DropdownMenuItem(
                                  value: p.id,
                                  child: Text('${p.name} (Sisa: ${currencyFormatter.format(p.remaining)})'),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => selectedPocketId = val),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Jumlah
                  Row(
                    children: [
                      const SizedBox(width: 80, child: Text('Jumlah', style: TextStyle(fontSize: 15))),
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            suffixIcon: const Icon(Icons.calculate, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Keterangan
                  Row(
                    children: [
                      const SizedBox(width: 80, child: Text('Keterangan', style: TextStyle(fontSize: 15))),
                      Expanded(
                        child: TextField(
                          controller: noteController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Simpan
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
                  if (amountController.text.isEmpty || selectedPocketId == null) return;
                  final pocket = widget.pockets.firstWhere((p) => p.id == selectedPocketId);
                  final item = TransactionItem(
                    id: DateTime.now().toString(),
                    type: selectedType,
                    pocketId: pocket.id,
                    pocketName: pocket.name,
                    amount: double.parse(amountController.text),
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

// ==========================================
// TAB 1: KANTONG (TAMBAH, EDIT, HAPUS)
// ==========================================
class PocketTab extends StatelessWidget {
  final List<Pocket> pockets;
  final Function(Pocket) onAddPocket;
  final Function(String, String, double) onEditPocket;
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
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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
                      backgroundColor: p.color.withOpacity(0.2),
                      child: Icon(p.icon, color: p.color),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Budget: ${currencyFormatter.format(p.budget)}'),
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'btn_add_pocket',
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kantong Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Kantong (misal: Makan)')),
            TextField(controller: budgetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Budget (Rp)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && budgetCtrl.text.isNotEmpty) {
                onAddPocket(Pocket(
                  id: DateTime.now().toString(),
                  name: nameCtrl.text,
                  budget: double.parse(budgetCtrl.text),
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          )
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Pocket pocket) {
    final nameCtrl = TextEditingController(text: pocket.name);
    final budgetCtrl = TextEditingController(text: pocket.budget.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Kantong'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Kantong')),
            TextField(controller: budgetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Budget (Rp)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && budgetCtrl.text.isNotEmpty) {
                onEditPocket(pocket.id, nameCtrl.text, double.parse(budgetCtrl.text));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Update'),
          )
        ],
      ),
    );
  }
}

// ==========================================
// TAB 2: SISA BUDGET KANTONG
// ==========================================
class BudgetStatusTab extends StatelessWidget {
  final List<Pocket> pockets;

  const BudgetStatusTab({super.key, required this.pockets});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pockets.length,
      itemBuilder: (ctx, i) {
        final p = pockets[i];
        final percent = (p.spent / p.budget).clamp(0.0, 1.0);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Sisa: ${currencyFormatter.format(p.remaining)}',
                        style: TextStyle(
                          color: p.remaining < 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        )),
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
                    Text('Terpakai: ${currencyFormatter.format(p.spent)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('Total Budget: ${currencyFormatter.format(p.budget)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// TAB 3: PENDAPATAN / PEMASUKAN
// ==========================================
class IncomeTab extends StatelessWidget {
  final List<TransactionItem> transactions;
  final double totalIncome;
  final Function(TransactionItem) onAddIncome;

  const IncomeTab({
    super.key,
    required this.transactions,
    required this.totalIncome,
    required this.onAddIncome,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: Colors.green[100],
          child: Column(
            children: [
              const Text('Total Pendapatan Terinput', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(currencyFormatter.format(totalIncome), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ),
        Expanded(
          child: transactions.isEmpty
              ? const Center(child: Text('Belum ada data pendapatan.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: transactions.length,
                  itemBuilder: (ctx, i) {
                    final tx = transactions[i];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.arrow_downward, color: Colors.white)),
                        title: Text(tx.note.isEmpty ? 'Pendapatan' : tx.note),
                        subtitle: Text(DateFormat('dd MMM yyyy').format(tx.date)),
                        trailing: Text('+ ${currencyFormatter.format(tx.amount)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }
}

// ==========================================
// TAB 4: GRAFIK / CHART DENGAN FILTER
// ==========================================
class ChartTab extends StatefulWidget {
  final List<TransactionItem> transactions;
  final List<Pocket> pockets;

  const ChartTab({super.key, required this.transactions, required this.pockets});

  @override
  State<ChartTab> createState() => _ChartTabState();
}

class _ChartTabState extends State<ChartTab> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Filter transaksi berdasarkan bulan & tahun
    final filteredTx = widget.transactions.where((t) {
      return t.type == 'Pengeluaran' && t.date.month == selectedMonth && t.date.year == selectedYear;
    }).toList();

    // Hitung total per kantong
    Map<String, double> pocketTotals = {};
    for (var p in widget.pockets) {
      pocketTotals[p.name] = 0;
    }
    for (var tx in filteredTx) {
      pocketTotals[tx.pocketName] = (pocketTotals[tx.pocketName] ?? 0) + tx.amount;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Filter Bulan & Tahun
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<int>(
                value: selectedMonth,
                items: List.generate(12, (i) => i + 1).map((m) {
                  return DropdownMenuItem(value: m, child: Text('Bulan $m'));
                }).toList(),
                onChanged: (v) => setState(() => selectedMonth = v!),
              ),
              const SizedBox(width: 20),
              DropdownButton<int>(
                value: selectedYear,
                items: [2024, 2025, 2026, 2027].map((y) {
                  return DropdownMenuItem(value: y, child: Text('$y'));
                }).toList(),
                onChanged: (v) => setState(() => selectedYear = v!),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Area Chart
          Expanded(
            child: filteredTx.isEmpty
                ? const Center(child: Text('Tidak ada pengeluaran pada periode ini.'))
                : Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: widget.pockets.map((p) {
                              final total = pocketTotals[p.name] ?? 0;
                              return PieChartSectionData(
                                color: p.color,
                                value: total == 0 ? 1 : total,
                                title: total > 0 ? '${p.name}\n${currencyFormatter.format(total)}' : '',
                                radius: 60,
                                titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView(
                          children: pocketTotals.entries.map((e) {
                            return ListTile(
                              title: Text(e.key),
                              trailing: Text(currencyFormatter.format(e.value), style: const TextStyle(fontWeight: FontWeight.bold)),
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

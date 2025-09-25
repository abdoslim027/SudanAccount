import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(fontFamily: 'SudanKufi'),
    home: InvoiceScreen(),
  ));
}

// نموذج الفاتورة
class Invoice {
  final int? id;
  final String clientName;
  final double amount;
  final String date;

  Invoice({this.id, required this.clientName, required this.amount, required this.date});

  Map<String, dynamic> toMap() => {
        'id': id,
        'clientName': clientName,
        'amount': amount,
        'date': date,
      };
}

// خدمة قاعدة البيانات
class DBService {
  static Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'sudan_account.db');
    return openDatabase(path, version: 1, onCreate: (db, version) {
      return db.execute('''
        CREATE TABLE invoices(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          clientName TEXT,
          amount REAL,
          date TEXT
        )
      ''');
    });
  }

  static Future<void> insertInvoice(Invoice invoice) async {
    final db = await initDB();
    await db.insert('invoices', invoice.toMap());
  }

  static Future<List<Invoice>> getInvoices() async {
    final db = await initDB();
    final List<Map<String, dynamic>> maps = await db.query('invoices');
    return List.generate(maps.length, (i) => Invoice(
          id: maps[i]['id'],
          clientName: maps[i]['clientName'],
          amount: maps[i]['amount'],
          date: maps[i]['date'],
        ));
  }
}

// شاشة الفواتير
class InvoiceScreen extends StatefulWidget {
  @override
  _InvoiceScreenState createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final _clientController = TextEditingController();
  final _amountController = TextEditingController();
  List<Invoice> _invoices = [];

  void _loadInvoices() async {
    final invoices = await DBService.getInvoices();
    setState(() => _invoices = invoices);
  }

  void _addInvoice() async {
    final invoice = Invoice(
      clientName: _clientController.text,
      amount: double.parse(_amountController.text),
      date: DateTime.now().toString(),
    );
    await DBService.insertInvoice(invoice);
    _clientController.clear();
    _amountController.clear();
    _loadInvoices();
  }

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حسابك – تطبيق محاسبي سوداني')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'عبد الرحيم البرعي سليمان محمد الأمين',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _clientController,
              decoration: const InputDecoration(labelText: 'اسم العميل'),
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'المبلغ'),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(onPressed: _addInvoice, child: const Text('إضافة')),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _invoices.length,
                itemBuilder: (context, index) {
                  final invoice = _invoices[index];
                  return Card(
                    child: ListTile(
                      title: Text(invoice.clientName),
                      subtitle: Text('${invoice.amount} – ${invoice.date}'),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

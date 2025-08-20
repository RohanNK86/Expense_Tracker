import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart'; // Added: Required for PieChart

// Main app imports
void main() {
  runApp(const MainApp());
}

/// MODEL
class Expense {
  final String id;
  String title;
  double amount;
  String category;
  DateTime date;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });
  // helper to clone
  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
    );
  }
}

/// MAIN APP

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _isDarkTheme = false;
  String _userName = "User Name"; // Added for profile section
  String _userEmail = "";
  String _userInstitute = "";

  void _toggleTheme() => setState(() => _isDarkTheme = !_isDarkTheme);

  void _editProfile(String name, String email, String institute) {
    setState(() {
      _userName = name;
      _userEmail = email;
      _userInstitute = institute;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expenses Snap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: ExpenseHomePage(
        isDarkTheme: _isDarkTheme,
        onToggleTheme: _toggleTheme,
        userName: _userName, // Pass user name
        userEmail: _userEmail,
        userInstitute: _userInstitute,
        onEditProfile: _editProfile,
      ),
    );
  }
}

/// HOME + NAV & MAIN STATE

class ExpenseHomePage extends StatefulWidget {
  final bool isDarkTheme;
  final VoidCallback onToggleTheme;
  final String userName; // Added for profile
  final String userEmail;
  final String userInstitute;
  final void Function(String, String, String)
  onEditProfile; // Updated signature

  const ExpenseHomePage({
    super.key,
    required this.isDarkTheme,
    required this.onToggleTheme,
    required this.userName, // Added
    required this.userEmail,
    required this.userInstitute,
    required this.onEditProfile,
  });

  @override
  State<ExpenseHomePage> createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  final List<Expense> _expenses = <Expense>[];
  final List<String> _categories = <String>[
    'Food',
    'Travel',
    'Bills',
    'Shopping',
    'Entertainment',
    'Health',
    'Other',
  ];

  String _searchQuery = "";
  DateTime? _selectedDate;
  final Map<String, double> _limits = {
    'Daily': 0.0,
    'Weekly': 0.0,
    'Monthly': 0.0,
    'Yearly': 0.0,
  };
  String _selectedLimitFrequency = 'Monthly';
  double _walletAmount = 0.0; // Wallet amount to store available money

  List<Expense> get _filteredExpenses {
    return _expenses.where((Expense e) {
      final bool matchesSearch =
          _searchQuery.trim().isEmpty ||
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final bool matchesDate = _selectedDate == null
          ? true
          : (e.date.year == _selectedDate!.year &&
                e.date.month == _selectedDate!.month &&
                e.date.day == _selectedDate!.day);
      return matchesSearch && matchesDate;
    }).toList()..sort((Expense a, Expense b) => b.date.compareTo(a.date));
  }

  double get totalAmount {
    return _filteredExpenses.fold(
      0.0,
      (double sum, Expense item) => sum + item.amount,
    );
  }

  Map<String, double> get categoryTotals {
    final Map<String, double> map = <String, double>{};
    for (String c in _categories) {
      map[c] = 0.0;
    }
    for (Expense e in _expenses) {
      map[e.category] = (map[e.category] ?? 0.0) + e.amount;
    }
    return map;
  }

  void _addExpense(Expense expense) {
    setState(() {
      _expenses.add(expense);
    });
  }

  void _updateExpense(String id, Expense newExpense) {
    final int index = _expenses.indexWhere((Expense e) => e.id == id);
    if (index >= 0) {
      setState(() {
        _expenses[index] = newExpense;
      });
    }
  }

  void _deleteExpenseById(String id) {
    setState(() {
      _expenses.removeWhere((Expense e) => e.id == id);
    });
  }

  void _openAddExpenseScreen() async {
    final Expense? result = await Navigator.push<Expense>(
      context,
      MaterialPageRoute<Expense>(
        builder: (BuildContext ctx) =>
            AddEditExpenseScreen(categories: _categories),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      _addExpense(result);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Expense added ✅")));
    }
  }

  void _openEditExpenseScreen(Expense expense) async {
    final Expense? result = await Navigator.push<Expense>(
      context,
      MaterialPageRoute<Expense>(
        builder: (BuildContext ctx) => AddEditExpenseScreen(
          categories: _categories,
          expenseToEdit: expense,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      _updateExpense(expense.id, result);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Expense updated ✏")));
    }
  }

  void _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
  }

  void _showSearchDialog() {
    final TextEditingController searchController = TextEditingController(
      text: _searchQuery,
    );
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Row(
          children: <Widget>[
            Icon(Icons.search),
            SizedBox(width: 8),
            Text("Search Expenses"),
          ],
        ),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(hintText: "Title or category"),
          autofocus: true,
          textInputAction: TextInputAction.search,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = searchController.text;
              });
              Navigator.of(ctx).pop();
            },
            child: const Text("Search"),
          ),
        ],
      ),
    );
  }

  void _openCategoriesScreen() async {
    final List<String>? result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute<List<String>>(
        builder: (BuildContext ctx) =>
            CategoriesPage(categories: List<String>.from(_categories)),
      ),
    );
    if (result != null) {
      setState(() {
        _categories
          ..clear()
          ..addAll(result);
        if (!_categories.contains('Other')) _categories.add('Other');
      });
    }
  }

  // Fixed: Wrapped CSV export logic into a proper method.
  void _exportExpensesToCsv() {
    // Renamed from '_'
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('id,title,amount,category,date');
    for (Expense e in _expenses) {
      buffer.writeln(
        '${e.id},"${_escapeCsv(e.title)}",${e.amount},"${_escapeCsv(e.category)}",${e.date.toIso8601String()}',
      );
    }

    final String csv = buffer.toString();
    Clipboard.setData(ClipboardData(text: csv));
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text("CSV Export"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text("CSV copied to clipboard. Preview:"),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                child: Text(
                  csv.length > 1000 ? '${csv.substring(0, 1000)}...' : csv,
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  String _escapeCsv(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      final String escaped = s.replaceAll('"', '""');
      return '"$escaped"';
    }
    return s;
  }

  void _confirmDelete(Expense expense) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text("Delete Expense"),
        content: Text("Are you sure you want to delete \"${expense.title}\"?"),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteExpenseById(expense.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Deleted")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showExpenseDetails(Expense e) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text(
                e.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(e.category),
              trailing: Text(
                "₹${e.amount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Date"),
              subtitle: Text(e.date.toLocal().toString().split(' ')[0]),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _openEditExpenseScreen(e);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _confirmDelete(e);
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text("Delete"),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "ID: ${e.id}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to calculate spent for a given frequency
  double _getSpentForFrequency(String frequency) {
    final DateTime now = DateTime.now();
    return _expenses
        .where((Expense e) {
          final DateTime expenseDateNormalized = DateTime(
            e.date.year,
            e.date.month,
            e.date.day,
          );
          final DateTime nowNormalized = DateTime(now.year, now.month, now.day);

          switch (frequency) {
            case 'Daily':
              return expenseDateNormalized.isAtSameMomentAs(nowNormalized);
            case 'Weekly':
              // Get start of the current week (Monday)
              final DateTime startOfWeek = nowNormalized.subtract(
                Duration(days: nowNormalized.weekday - 1),
              );
              return expenseDateNormalized.isAfter(
                    startOfWeek.subtract(const Duration(milliseconds: 1)),
                  ) &&
                  expenseDateNormalized.isBefore(
                    nowNormalized.add(const Duration(days: 1)),
                  );
            case 'Monthly':
              return e.date.year == now.year && e.date.month == now.month;
            case 'Yearly':
              return e.date.year == now.year;
            default:
              return false;
          }
        })
        .fold(0.0, (double sum, Expense item) => sum + item.amount);
  }

  // Getters for specific limits and totals used in UI
  // These are not actually used, the methods directly use _limits[_selectedLimitFrequency]
  // double get _monthlyTarget => _limits['Monthly'] ?? 0.0;
  // double get _currentMonthTotal => _getSpentForFrequency('Monthly');

  // Method to show set limit dialog
  // Fixed: Ensure targetController text is updated correctly when frequency changes within the dialog.
  void _showSetLimitDialog() {
    String currentFreq = _selectedLimitFrequency;
    final TextEditingController targetController = TextEditingController(
      text: _limits[currentFreq]! > 0
          ? _limits[currentFreq]!.toStringAsFixed(2)
          : "",
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateInDialog) {
          final double spent = _getSpentForFrequency(currentFreq);

          return AlertDialog(
            title: const Row(
              children: <Widget>[
                Icon(Icons.trending_up),
                SizedBox(width: 8),
                Text("Set Limit"),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    "Current ${currentFreq.toLowerCase()} spending: ₹${spent.toStringAsFixed(2)}",
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: currentFreq,
                    items: <String>['Daily', 'Weekly', 'Monthly', 'Yearly']
                        .map<DropdownMenuItem<String>>(
                          (String v) => DropdownMenuItem<String>(
                            value: v,
                            child: Text(v),
                          ),
                        )
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: "Frequency",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (String? v) {
                      if (v != null) {
                        setStateInDialog(() {
                          currentFreq = v;
                          // Update controller text when frequency changes
                          targetController.text = _limits[currentFreq]! > 0
                              ? _limits[currentFreq]!.toStringAsFixed(2)
                              : "";
                          // Keep cursor at the end
                          targetController
                              .selection = TextSelection.fromPosition(
                            TextPosition(offset: targetController.text.length),
                          );
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: targetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: "Set Limit",
                      hintText: "e.g. 5000.00",
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Please enter a limit";
                      }
                      final double? parsed = double.tryParse(v.trim());
                      if (parsed == null || parsed <= 0) {
                        return "Please enter a positive number";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final double newLimit =
                        double.tryParse(targetController.text.trim()) ?? 0.0;
                    setState(() {
                      // Update state of the ExpenseHomePage
                      _limits[currentFreq] = newLimit;
                      _selectedLimitFrequency =
                          currentFreq; // Keep track of the last frequency for which limit was set
                    });
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "$currentFreq limit set to ₹${newLimit.toStringAsFixed(2)}",
                        ),
                      ),
                    );
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  // Method to show wallet amount dialog
  void _showWalletDialog() {
    final TextEditingController walletController = TextEditingController(
      text: _walletAmount > 0 ? _walletAmount.toStringAsFixed(2) : "",
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Row(
          children: <Widget>[
            Icon(Icons.account_balance_wallet),
            SizedBox(width: 8),
            Text("Wallet Amount"),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: walletController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixText: '₹ ',
              labelText: "Enter Wallet Amount (₹)",
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
            ),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return "Please enter amount";
              }
              final double? parsed = double.tryParse(value.trim());
              if (parsed == null || parsed < 0) {
                return "Please enter a valid non-negative amount";
              }
              return null;
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  _walletAmount = double.parse(walletController.text.trim());
                });
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Wallet amount set to ₹${_walletAmount.toStringAsFixed(2)}",
                    ),
                  ),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.receipt_long, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              "No expenses yet.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              "Tap the + button to add your first expense.\nYou can also manage categories or view statistics.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _openAddExpenseScreen,
              icon: const Icon(Icons.add),
              label: const Text("Add Expense"),
            ),
          ],
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppBackground.getGradientColors(
                  Theme.of(context).brightness,
                ),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: Icon(
                    Icons.pie_chart,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.userName.isNotEmpty
                      ? widget.userName
                      : "Expenses Snap User",
                  style: TextStyle(
                    fontSize: 20,
                    // Fixed: Ensure text visibility on the gradient background
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Track your daily expenses easily",
                  style: TextStyle(
                    fontSize: 12,
                    // Fixed: Ensure text visibility on the gradient background
                    color:
                        (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87)
                            .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text("Statistics"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext ctx) => StatisticsPage(
                    expenses:
                        _expenses, // Corrected: refer to _expenses from state
                    categoryTotals:
                        categoryTotals, // Corrected: refer to categoryTotals from state
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text("Categories"),
            onTap: () {
              Navigator.pop(context);
              _openCategoriesScreen();
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext ctx) => ProfilePage(
                    name: widget.userName,
                    email: widget.userEmail,
                    institute: widget.userInstitute,
                    onEdit: widget.onEditProfile,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.trending_up),
            title: const Text("Set Limit"),
            onTap: () {
              Navigator.pop(context);
              _showSetLimitDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text("Wallet Amount"),
            onTap: () {
              Navigator.pop(context);
              _showWalletDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext ctx) => SettingsPage(
                    isDark: widget.isDarkTheme,
                    toggleTheme: widget.onToggleTheme,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text("Help"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext ctx) => const HelpPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("About"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext ctx) => const AboutPage(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text("Assistant"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext ctx) =>
                      AssistantPage(expenses: _expenses),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.lightbulb_outline,
            ), // Added icon for insights
            title: const Text(
              "Spending Insights",
            ), // Added menu item for insights
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext ctx) =>
                      InsightsPage(expenses: _expenses),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double balance = _walletAmount - totalAmount;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Expenses Snap"),
          actions: <Widget>[
            IconButton(
              tooltip: "Set Limit",
              icon: const Icon(Icons.trending_up), // New icon for set limit
              onPressed: _showSetLimitDialog,
            ),
            IconButton(
              tooltip: "Pick date filter",
              icon: const Icon(Icons.calendar_today),
              onPressed: _pickDate,
            ),
            if (_selectedDate != null)
              IconButton(
                tooltip: "Clear date filter",
                icon: const Icon(Icons.clear),
                onPressed: _clearDateFilter,
              ),
            IconButton(
              tooltip: widget.isDarkTheme ? "Light mode" : "Dark mode",
              icon: Icon(widget.isDarkTheme ? Icons.wb_sunny : Icons.dark_mode),
              onPressed: widget.onToggleTheme,
            ),
            IconButton(
              tooltip: "Search",
              icon: const Icon(Icons.search),
              onPressed: _showSearchDialog,
            ),
            IconButton(
              tooltip: "Wallet Amount",
              icon: const Icon(Icons.account_balance_wallet),
              onPressed: _showWalletDialog,
            ),

            PopupMenuButton<String>(
              onSelected: (String v) {
                if (v == 'assistant') {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext ctx) =>
                          AssistantPage(expenses: _expenses),
                    ),
                  );
                } else if (v == 'export_csv') {
                  // Added handler for CSV export
                  _exportExpensesToCsv();
                }
              },
              itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'assistant',
                  child: ListTile(
                    leading: Icon(Icons.chat_bubble_outline),
                    title: Text('Assistant'),
                  ),
                ),
                const PopupMenuItem<String>(
                  // Added CSV export to popup menu
                  value: 'export_csv',
                  child: ListTile(
                    leading: Icon(Icons.download),
                    title: Text('Export CSV'),
                  ),
                ),
              ],
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.account_balance_wallet, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "Wallet Amount: ₹${_walletAmount.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              "Total Spent: ₹${totalAmount.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              "Balance: ₹${balance.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: balance >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Showing ${_filteredExpenses.length} items",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      // Optional: Edit icon to quickly open wallet dialog
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: "Set Wallet Amount",
                        onPressed: _showWalletDialog,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Set Limit Progress Card
            if (_limits[_selectedLimitFrequency]! >
                0) // Changed to use selected limit frequency
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.pie_chart_outline,
                          size: 30,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                // Display frequency for set limit
                                "$_selectedLimitFrequency Limit Progress",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Spent: ₹${_getSpentForFrequency(_selectedLimitFrequency).toStringAsFixed(2)} / Target: ₹${_limits[_selectedLimitFrequency]!.toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value:
                                    _getSpentForFrequency(
                                      _selectedLimitFrequency,
                                    ) /
                                    (_limits[_selectedLimitFrequency]!).clamp(
                                      1.0,
                                      double.infinity,
                                    ),
                                color:
                                    _getSpentForFrequency(
                                          _selectedLimitFrequency,
                                        ) >
                                        _limits[_selectedLimitFrequency]!
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.primary,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Filters row (Wrap + Buttons)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.bar_chart),
                    label: const Text("Statistics"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext ctx) => StatisticsPage(
                            expenses: _expenses,
                            categoryTotals: categoryTotals,
                          ),
                        ),
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.category),
                    label: const Text("Categories"),
                    onPressed: _openCategoriesScreen,
                  ),
                  TextButton.icon(
                    icon: const Icon(
                      Icons.insights,
                    ), // Changed icon to insights
                    label: const Text("Spending Insights"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext ctx) =>
                              InsightsPage(expenses: _expenses),
                        ),
                      );
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person),
                    label: const Text("Profile"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext ctx) => ProfilePage(
                            name: widget.userName,
                            email: widget.userEmail,
                            institute: widget.userInstitute,
                            onEdit: widget.onEditProfile,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const Divider(),

            // List header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? "All Expenses"
                          : "Expenses on ${_selectedDate!.toLocal().toString().split(' ')[0]}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchQuery = "";
                        });
                      },
                      child: Tooltip(
                        message: "Clear search",
                        child: Chip(
                          label: Text("Search: $_searchQuery"),
                          deleteIcon: const Icon(Icons.clear),
                          onDeleted: () {
                            setState(() {
                              _searchQuery = "";
                            });
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: _filteredExpenses.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      itemCount: _filteredExpenses.length,
                      itemBuilder: (BuildContext ctx, int idx) {
                        final Expense exp = _filteredExpenses[idx];
                        return Card(
                          key: ValueKey<String>(exp.id),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                              child: Text(exp.category[0]),
                            ),
                            title: Text(exp.title),
                            subtitle: Text(
                              "${exp.category} • ${exp.date.toLocal().toString().split(' ')[0]}",
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  "₹${exp.amount.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                IconButton(
                                  tooltip: "Edit",
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _openEditExpenseScreen(exp),
                                ),
                                IconButton(
                                  tooltip: "Delete",
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _confirmDelete(exp),
                                ),
                              ],
                            ),
                            onTap: () => _showExpenseDetails(exp),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),

        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FloatingActionButton(
              tooltip: "Add Expense",
              onPressed: _openAddExpenseScreen,
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'assistant',
              tooltip: "Assistant",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext ctx) =>
                        AssistantPage(expenses: _expenses),
                  ),
                );
              },
              child: const Icon(Icons.chat_bubble_outline),
            ),
          ],
        ),
      ),
    );
  }
}

/// Background widget with dynamic lavender gradient for light/dark themes
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  static List<Color> getGradientColors(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const <Color>[
        Color(0xFF0B1020), // deeper almost-black blue
        Color(0xFF111427), // deep navy
        Color(0xFF1B1533), // dark indigo
        Color(0xFF2A1F3A), // deep plum
      ];
    } else {
      return const <Color>[
        Color(0xFFE3E6FF), // light lavender
        Color(0xFFC7CEEA), // pastel purple
        Color(0xFFD8B4FE), // soft violet
        Color(0xFFFED6E3), // pinkish
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: getGradientColors(Theme.of(context).brightness),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

/// ADD / EDIT SCREEN (form-based)
class AddEditExpenseScreen extends StatefulWidget {
  final List<String> categories;
  final Expense? expenseToEdit;

  const AddEditExpenseScreen({
    super.key,
    required this.categories,
    this.expenseToEdit,
  });

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final Expense? edit = widget.expenseToEdit;
    _titleController = TextEditingController(text: edit?.title ?? "");
    _amountController = TextEditingController(
      text: edit != null ? edit.amount.toString() : "",
    );
    // Ensure _selectedCategory is a valid category from the list, or 'Other' if available.
    if (edit != null && widget.categories.contains(edit.category)) {
      _selectedCategory = edit.category;
    } else if (widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.first;
    } else {
      _selectedCategory = 'Other'; // Fallback if categories list is empty
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final String title = _titleController.text.trim();
    final double amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final String category = _selectedCategory ?? 'Other';
    final Expense? existing = widget.expenseToEdit;
    final Expense expense = Expense(
      id: existing?.id ?? _generateId(),
      title: title,
      amount: amount,
      category: category,
      date: _selectedDate,
    );

    Future<void>.delayed(const Duration(milliseconds: 350), () {
      setState(() => _isSaving = false);
      Navigator.of(context).pop(expense);
    });
  }

  String _generateId() {
    final Random rnd = Random();
    return DateTime.now().millisecondsSinceEpoch.toString() +
        rnd.nextInt(9999).toString();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.expenseToEdit != null;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(isEdit ? "Edit Expense" : "Add Expense"),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _save,
              tooltip: "Save",
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: <Widget>[
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Title",
                      prefixIcon: Icon(Icons.title),
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? v) => (v == null || v.trim().isEmpty)
                        ? "Enter a title"
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      prefixText: '₹ ',
                      labelText: "Amount (₹)",
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                      hintText: "e.g. 125.75",
                    ),
                    validator: (String? v) {
                      if (v == null || v.trim().isEmpty) return "Enter amount";
                      final double? parsed = double.tryParse(v.trim());
                      if (parsed == null || parsed <= 0) {
                        return "Amount must be positive";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    items: widget.categories
                        .map<DropdownMenuItem<String>>(
                          (String c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(c),
                          ),
                        )
                        .toList(),
                    onChanged: (String? v) =>
                        setState(() => _selectedCategory = v),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.category),
                      labelText: "Category",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            "Date: ${_selectedDate.toLocal().toString().split(' ')[0]}",
                          ),
                          onPressed: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.today),
                        label: const Text("Today"),
                        onPressed: () {
                          setState(() {
                            _selectedDate = DateTime.now();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    children: widget.categories
                        .take(6)
                        .map<Widget>(
                          (String c) => ChoiceChip(
                            label: Text(c),
                            selected: _selectedCategory == c,
                            onSelected: (bool selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = c;
                                });
                              }
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: _isSaving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(isEdit ? "Update" : "Add"),
                          onPressed: _isSaving ? null : _save,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text("Cancel"),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        "Tip: Use category chips to quickly pick a category. You can edit expenses later.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// STATISTICS PAGE (summary widgets + pie chart)

class StatisticsPage extends StatefulWidget {
  final List<Expense> expenses;
  final Map<String, double> categoryTotals;

  const StatisticsPage({
    super.key,
    required this.expenses,
    required this.categoryTotals,
  });

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String _selectedPeriod =
      'Monthly'; // Fixed: declare and initialize _selectedPeriod

  List<Expense> get _filteredExpenses {
    DateTime now = DateTime.now();
    return widget.expenses.where((Expense e) {
      // Specify type Expense
      switch (_selectedPeriod) {
        case 'Daily':
          return e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day;
        case 'Weekly':
          DateTime startOfWeek = now.subtract(
            Duration(days: now.weekday - 1),
          ); // Monday
          // Ensure it's on or after startOfWeek and before tomorrow
          return e.date.isAfter(
                startOfWeek.subtract(const Duration(milliseconds: 1)),
              ) &&
              e.date.isBefore(now.add(const Duration(days: 1)));
        case 'Monthly':
          return e.date.year == now.year && e.date.month == now.month;
        case 'Yearly':
          return e.date.year == now.year;
        case 'All Time': // Handle 'All Time' explicitly
          return true;
        default:
          return true;
      }
    }).toList();
  }

  double get total => _filteredExpenses.fold(
    0.0,
    (double sum, Expense e) => sum + e.amount,
  ); // Specify type
  int get count => _filteredExpenses.length;

  Map<String, double> get filteredCategoryTotals {
    final Map<String, double> map = <String, double>{};
    for (Expense e in _filteredExpenses) {
      // Specify type
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  List<MapEntry<String, double>> get topCategories {
    final List<MapEntry<String, double>> list = filteredCategoryTotals.entries
        .toList();
    list.sort(
      (MapEntry<String, double> a, MapEntry<String, double> b) =>
          b.value.compareTo(a.value),
    ); // Specify type
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, double>> top = topCategories.take(5).toList();

    // Define a list of colors for the pie chart sections
    final List<Color> pieColors = <Color>[
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.red.shade400,
      Colors.teal.shade400,
      Colors.amber.shade400,
      Colors.cyan.shade400,
      Colors.pink.shade400,
      Colors.indigo.shade400,
      Colors.brown.shade400,
    ];

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text("Statistics")),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text("View: "),
                    DropdownButton<String>(
                      value: _selectedPeriod,
                      items:
                          <String>[
                                'All Time',
                                'Daily',
                                'Weekly',
                                'Monthly',
                                'Yearly',
                              ]
                              .map<DropdownMenuItem<String>>(
                                (String p) => DropdownMenuItem<String>(
                                  value: p,
                                  child: Text(p),
                                ),
                              )
                              .toList(),
                      onChanged: (String? val) {
                        if (val != null) setState(() => _selectedPeriod = val);
                      },
                    ),
                  ],
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.pie_chart),
                  title: const Text("Total Spent"),
                  subtitle: Text(
                    "Across ${_selectedPeriod.toLowerCase()}",
                  ), // Changed subtitle to reflect filter
                  trailing: Text(
                    "₹${total.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.list),
                  title: const Text("Total Entries"),
                  trailing: Text("$count"),
                ),
              ),
              const SizedBox(height: 12),

              // Pie Chart Section
              if (total > 0)
                Expanded(
                  flex: 2, // Give more space to pie chart
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          "Expense Distribution by Category",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: filteredCategoryTotals.entries
                                .where(
                                  (MapEntry<String, double> e) => e.value > 0,
                                )
                                .toList()
                                .asMap()
                                .entries
                                .map<PieChartSectionData>((
                                  MapEntry<int, MapEntry<String, double>> entry,
                                ) {
                                  final int index = entry.key;
                                  final MapEntry<String, double> categoryEntry =
                                      entry.value;
                                  final double percentage =
                                      (categoryEntry.value / total) * 100;
                                  final Color color =
                                      pieColors[index % pieColors.length];
                                  return PieChartSectionData(
                                    color: color,
                                    value: categoryEntry.value,
                                    title: percentage > 0.1
                                        ? '${percentage.toStringAsFixed(1)}%'
                                        : '', // Only show percentage if greater than 0.1 for visibility
                                    radius: 60,
                                    titleStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: <Shadow>[
                                        Shadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                          swapAnimationDuration: const Duration(
                            milliseconds: 750,
                          ),
                          swapAnimationCurve: Curves.easeInOutBack,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: Center(
                    child: Text(
                      "Add some expenses to see category distribution.",
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Top Categories",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex:
                    1, // Give less space to top categories list if pie chart is present
                child: top.isEmpty
                    ? const Center(child: Text("No categories yet"))
                    : ListView.separated(
                        itemCount: top.length,
                        separatorBuilder: (BuildContext _, int __) =>
                            const Divider(),
                        itemBuilder: (BuildContext ctx, int idx) {
                          final MapEntry<String, double> e =
                              top[idx]; // Specify type
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                              child: Text(e.key[0]),
                            ),
                            title: Text(e.key),
                            subtitle: Text(
                              "${(e.value / (total == 0 ? 1 : total) * 100).toStringAsFixed(1)}% of total",
                            ),
                            trailing: Text(
                              "₹${e.value.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// PROFILE PAGE

class ProfilePage extends StatelessWidget {
  final String name; // Added
  final String email;
  final String institute;
  final void Function(String, String, String) onEdit; // Updated signature

  const ProfilePage({
    super.key,
    required this.name, // Added
    required this.email,
    required this.institute,
    required this.onEdit,
  });

  void _openEditDialog(BuildContext context) {
    final GlobalKey<FormState> formKey =
        GlobalKey<FormState>(); // Added for form validation
    final TextEditingController nameController = TextEditingController(
      text: name,
    ); // Added
    final TextEditingController emailController = TextEditingController(
      text: email,
    );
    final TextEditingController instituteController = TextEditingController(
      text: institute,
    );

    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text("Edit Profile"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Your Name",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (String? v) => (v == null || v.trim().isEmpty)
                    ? "Name cannot be empty"
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (String? v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Email cannot be empty";
                  }

                  if (!v.contains('@') || !v.contains('.')) {
                    return "Enter a valid email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: instituteController,
                decoration: const InputDecoration(
                  labelText: "Institute",
                  prefixIcon: Icon(Icons.school),
                  border: OutlineInputBorder(),
                ),
                validator: (String? v) => (v == null || v.trim().isEmpty)
                    ? "Institute cannot be empty"
                    : null,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                onEdit(
                  nameController.text.trim(),
                  emailController.text.trim(),
                  instituteController.text.trim(),
                );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text("Profile")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              CircleAvatar(
                radius: 46,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onPrimaryContainer,
                child: const Icon(Icons.person, size: 46),
              ),
              const SizedBox(height: 12),
              Text(
                name.isNotEmpty ? name : "User Name",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ), // Display actual name
              const SizedBox(height: 6),

              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.person),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Name',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name.isNotEmpty ? name : 'User Name',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.email),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email.isNotEmpty ? email : 'Not set',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy email',
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          if (email.isNotEmpty) {
                            Clipboard.setData(ClipboardData(text: email));
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Email copied')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.school),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Institute',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              institute.isNotEmpty ? institute : 'Not set',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy institute',
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          if (institute.isNotEmpty) {
                            Clipboard.setData(ClipboardData(text: institute));
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Institute copied')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => _openEditDialog(context),
                icon: const Icon(Icons.edit),
                label: const Text("Edit Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CATEGORIES MANAGEMENT PAGE

class CategoriesPage extends StatefulWidget {
  final List<String> categories;

  const CategoriesPage({super.key, required this.categories});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late List<String> _local;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _local = List<String>.from(widget.categories);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addCategory() {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_local.contains(text)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Category already exists")));
      return;
    }
    setState(() {
      _local.add(text);
      _controller.clear();
    });
  }

  void _deleteCategory(String cat) {
    if (cat == 'Other') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("'Other' cannot be removed")),
      );
      return;
    }
    setState(() {
      _local.remove(cat);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Manage Categories"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(_local),
              child: Text(
                "Done",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: "New category",
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (String _) => _addCategory(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _addCategory,
                    icon: const Icon(Icons.add),
                    label: const Text("Add"),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _local.isEmpty
                    ? const Center(child: Text("No categories"))
                    : ListView.separated(
                        itemCount: _local.length,
                        separatorBuilder: (BuildContext _, int __) =>
                            const Divider(),
                        itemBuilder: (BuildContext ctx, int idx) {
                          final String c = _local[idx];
                          return ListTile(
                            leading: const Icon(Icons.label),
                            title: Text(c),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCategory(c),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// SETTINGS PAGE

class SettingsPage extends StatefulWidget {
  final bool isDark;
  final VoidCallback toggleTheme;

  const SettingsPage({
    super.key,
    required this.isDark,
    required this.toggleTheme,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text("Settings")),
        body: ListView(
          children: <Widget>[
            SwitchListTile(
              value: widget.isDark,
              title: const Text("Dark Theme"),
              onChanged: (bool value) {
                widget.toggleTheme();
                // setState is not needed here as parent widget rebuilds due to onToggleTheme
              },
              secondary: const Icon(Icons.dark_mode),
            ),
            SwitchListTile(
              value: _notifications,
              onChanged: (bool v) => setState(() => _notifications = v),
              title: const Text("Notifications (demo)"),
              secondary: const Icon(Icons.notifications),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text("Privacy"),
              subtitle: const Text("Manage privacy settings (demo)"),
              onTap: () {},
            ),
            const ListTile(
              leading: Icon(Icons.info),
              title: Text("Version"),
              subtitle: Text("Expenses Snap v1.0"),
            ),
          ],
        ),
      ),
    );
  }
}

/// ABOUT PAGE

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text("About App")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.account_balance_wallet, size: 72),
                const SizedBox(height: 12),
                const Text(
                  "Expenses Snap",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Track your daily expenses easily!\n\nMade by Rohan & Aryan",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// INSIGHTS PAGE - AI-Powered Spending Suggestions (updates with expenses)
class InsightsPage extends StatefulWidget {
  final List<Expense> expenses;
  const InsightsPage({super.key, required this.expenses});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

enum InsightPeriod { daily, weekly, monthly, yearly, all }

class _InsightsPageState extends State<InsightsPage> {
  InsightPeriod _period = InsightPeriod.monthly;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Expense> get _filtered {
    final DateTime now = DateTime.now();
    switch (_period) {
      case InsightPeriod.daily:
        return widget.expenses
            .where((Expense e) => _sameDay(e.date, now))
            .toList();
      case InsightPeriod.weekly:
        final DateTime start = now.subtract(
          Duration(days: now.weekday - 1),
        ); // Monday
        return widget.expenses
            .where(
              (Expense e) => e.date.isAfter(
                start.subtract(const Duration(milliseconds: 1)),
              ),
            )
            .toList();
      case InsightPeriod.monthly:
        return widget.expenses
            .where(
              (Expense e) =>
                  e.date.year == now.year && e.date.month == now.month,
            )
            .toList();
      case InsightPeriod.yearly:
        return widget.expenses
            .where((Expense e) => e.date.year == now.year)
            .toList();
      case InsightPeriod.all:
        return List<Expense>.from(widget.expenses); // Return a copy
    }
  }

  Map<String, double> _categoryTotals(List<Expense> list) {
    final Map<String, double> map = <String, double>{};
    for (Expense e in list) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  double _sum(List<Expense> list) =>
      list.fold(0.0, (double s, Expense e) => s + e.amount);

  Map<String, dynamic> _analyze() {
    final DateTime now = DateTime.now();
    final List<Expense> current = _filtered;
    List<Expense> previous;
    switch (_period) {
      case InsightPeriod.daily:
        final DateTime prevDay = now.subtract(const Duration(days: 1));
        previous = widget.expenses
            .where((Expense e) => _sameDay(e.date, prevDay))
            .toList();
        break;
      case InsightPeriod.weekly:
        final DateTime startThis = now.subtract(
          Duration(days: now.weekday - 1),
        );
        final DateTime startPrev = startThis.subtract(const Duration(days: 7));
        final DateTime endPrev = startThis.subtract(
          const Duration(milliseconds: 1),
        );
        previous = widget.expenses
            .where(
              (Expense e) =>
                  e.date.isAfter(
                    startPrev.subtract(const Duration(milliseconds: 1)),
                  ) &&
                  e.date.isBefore(endPrev.add(const Duration(days: 1))),
            )
            .toList();
        break;
      case InsightPeriod.monthly:
        final DateTime prevMonth = DateTime(now.year, now.month - 1, now.day);
        previous = widget.expenses
            .where(
              (Expense e) =>
                  e.date.year == prevMonth.year &&
                  e.date.month == prevMonth.month,
            )
            .toList();
        break;
      case InsightPeriod.yearly:
        final DateTime prevYear = DateTime(now.year - 1, now.month, now.day);
        previous = widget.expenses
            .where((Expense e) => e.date.year == prevYear.year)
            .toList();
        break;
      case InsightPeriod.all:
        previous = <Expense>[]; // No 'previous' for all time
        break;
    }

    final double totalCur = _sum(current);
    final double totalPrev = _sum(previous);
    final Map<String, double> catCur = _categoryTotals(current);
    final Map<String, double> catPrev = _categoryTotals(previous);

    final List<String> suggestions = <String>[];
    if (totalCur == 0 && totalPrev == 0) {
      suggestions.add('No expenses in this period.');
    } else {
      if (totalPrev > 0) {
        final double diff = totalCur - totalPrev;
        final double pct = (diff / (totalPrev == 0 ? 1 : totalPrev)) * 100;
        if (pct.abs() >= 5) {
          if (pct > 0) {
            suggestions.add(
              'Spending increased by ${pct.toStringAsFixed(1)}% compared to previous period (₹${diff.abs().toStringAsFixed(2)} more).',
            );
          } else {
            suggestions.add(
              'Good job — spending decreased by ${pct.abs().toStringAsFixed(1)}% compared to previous period (₹${diff.abs().toStringAsFixed(2)} less).',
            );
          }
        } else {
          suggestions.add(
            'Spending roughly stable compared to previous period.',
          );
        }
      } else {
        if (totalCur > 0) {
          suggestions.add(
            'No previous period data. Current total: ₹${totalCur.toStringAsFixed(2)}.',
          );
        }
      }

      final List<MapEntry<String, double>> cats = catCur.entries.toList();
      cats.sort(
        (MapEntry<String, double> a, MapEntry<String, double> b) =>
            b.value.compareTo(a.value),
      ); // Specify types
      if (cats.isNotEmpty) {
        final MapEntry<String, double> top = cats.first; // Specify types
        final double prevTopAmount = catPrev[top.key] ?? 0.0;
        final double diff = top.value - prevTopAmount;
        if (prevTopAmount > 0) {
          final double pct = (diff / prevTopAmount) * 100;
          if (pct > 20) {
            suggestions.add(
              'Large increase in ${top.key}: up ${pct.toStringAsFixed(0)}% (₹${diff.toStringAsFixed(2)}) — consider reviewing this category.',
            );
          }
        } else if (top.value > 0) {
          suggestions.add(
            'You spent mostly on ${top.key} (₹${top.value.toStringAsFixed(2)}) in this period.',
          );
        }
      }

      final List<Expense> smalls = current
          .where((Expense e) => e.amount < 100)
          .toList(); // Specify type
      final double smallsTotal = _sum(smalls);
      if (smalls.isNotEmpty && smallsTotal > 200) {
        suggestions.add(
          'Many small purchases (₹${smallsTotal.toStringAsFixed(2)} total). These can add up — consider batching or tracking subscriptions.',
        );
      }
    }

    return <String, dynamic>{
      'totalCur': totalCur,
      'totalPrev': totalPrev,
      'catCur': catCur,
      'catPrev': catPrev,
      'suggestions': suggestions,
      'count': current.length,
    };
  }

  // Fixed: _label function was empty.
  static String _label(InsightPeriod p) {
    switch (p) {
      case InsightPeriod.daily:
        return 'Daily';
      case InsightPeriod.weekly:
        return 'Weekly';
      case InsightPeriod.monthly:
        return 'Monthly';
      case InsightPeriod.yearly:
        return 'Yearly';
      case InsightPeriod.all:
        return 'All Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> analysis = _analyze();
    final double totalCur = analysis['totalCur'] as double;
    final int count = analysis['count'] as int;
    final List<String> suggestions = analysis['suggestions'] as List<String>;
    final Map<String, double> catCur =
        analysis['catCur'] as Map<String, double>;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Spending Insights')),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Text('Period: '),
                  const SizedBox(width: 8),
                  DropdownButton<InsightPeriod>(
                    value: _period,
                    items: InsightPeriod.values
                        .map<DropdownMenuItem<InsightPeriod>>(
                          (InsightPeriod p) => DropdownMenuItem<InsightPeriod>(
                            value: p,
                            child: Text(_label(p)),
                          ),
                        )
                        .toList(),
                    onChanged: (InsightPeriod? v) {
                      if (v != null) setState(() => _period = v);
                    },
                  ),
                  const Spacer(),
                  Text('Items: $count'),
                  const SizedBox(width: 12),
                  Text(
                    'Total: ₹${totalCur.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Top Suggestions',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      if (suggestions.isEmpty)
                        const Text('No suggestions')
                      else
                        for (String s in suggestions)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text('• $s'),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Category Breakdown',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: catCur.isEmpty
                              ? const Center(child: Text('No data'))
                              : ListView(
                                  children: catCur.entries
                                      .toList()
                                      .map<ListTile>(
                                        (
                                          MapEntry<String, double> e,
                                        ) => ListTile(
                                          title: Text(e.key),
                                          trailing: Text(
                                            '₹${e.value.toStringAsFixed(2)}',
                                          ),
                                        ),
                                      )
                                      .toList(), // Specify type
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// HELP PAGE

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text("Help")),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView(
            children: <Widget>[
              const Card(
                child: ListTile(
                  leading: Icon(Icons.lightbulb),
                  title: Text("How to add an expense"),
                  subtitle: Text("Tap + and fill the form."),
                ),
              ),
              const SizedBox(height: 8),
              const ExpansionTile(
                leading: Icon(Icons.search),
                title: Text("Searching & Filtering"),
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Use the search icon to filter by title or category. Use the calendar icon to filter by date.",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.backup),
                  title: Text("Export"),
                  subtitle: Text("Spending Insights and copy to clipboard."),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Contact Support",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const ListTile(
                leading: Icon(Icons.email),
                title: Text("support@expensesnap.app (demo)"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// === GPT-like Assistant Integration ===
// This section adds a local heuristic assistant similar to ChatGPT but offline.
// It supports daily/weekly/monthly/yearly/all time filters, informal Q&A, and forecasting.
// Access via Drawer > Assistant.

/// ASSISTANT PAGE - Local GPT-like conversational assistant (heuristic)
class AssistantPage extends StatefulWidget {
  final List<Expense> expenses;
  const AssistantPage({super.key, required this.expenses});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages =
      <Map<String, String>>[]; // {'from':'user'|'assistant','text':...}
  String? _lastUser; // short-term memory for follow-ups

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --------------------
  // Utility helpers
  // --------------------
  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Helper to sum expenses in a list
  double _sum(List<Expense> list) =>
      list.fold(0.0, (double s, Expense e) => s + e.amount);

  // Helper to count set bits in an integer (Brian Kernighan's algorithm)
  int _countSetBits(int n) {
    int count = 0;
    while (n > 0) {
      n &= (n - 1);
      count++;
    }
    return count;
  }

  String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r"[^\w\s]"), " ")
        .replaceAll(RegExp(r"\s+"), " ")
        .trim();
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;
    List<int> v0 = List<int>.generate(
      t.length + 1,
      (int i) => i,
    ); // Specify type
    List<int> v1 = List<int>.filled(t.length + 1, 0); // Specify type
    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        final int cost = s[i] == t[j] ? 0 : 1;
        v1[j + 1] = <int>[
          // Specify type
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((int a, int b) => a < b ? a : b); // Specify type
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }

  bool _fuzzyContains(String text, String keyword) {
    text = _normalize(text);
    keyword = _normalize(keyword);
    if (text.contains(keyword)) return true;
    // check tokens
    final List<String> tokens = text.split(' ');
    for (final String tok in tokens) {
      // Specify type
      final int dist = _levenshtein(tok, keyword);
      final double sim =
          1.0 -
          dist /
              (keyword.isEmpty
                  ? 1
                  : keyword.length); // Fixed: handle keyword.length == 0
      if (sim >= 0.7) return true;
    }
    return false;
  }

  // Parse informal timeframe expressions in user input
  String _parseTimeframe(String text) {
    final String t = _normalize(text);
    if (t.contains('today') ||
        t.contains('this day') ||
        t.contains('today\'s')) {
      return 'Daily';
    }
    if (t.contains('yesterday')) return 'DailyPrev';
    if (t.contains('this week') || t.contains('this week\'s')) return 'Weekly';
    if (t.contains('last week')) return 'WeeklyPrev';
    if (t.contains('this month') || t.contains('this month\'s')) {
      return 'Monthly'; // Removed duplicate 'this month'
    }
    if (t.contains('last month')) return 'MonthlyPrev';
    if (t.contains('this year') || t.contains('this year\'s')) return 'Yearly';
    if (t.contains('last year')) return 'YearlyPrev';
    if (t.contains('all time') ||
        t.contains('overall') ||
        t.contains('total')) {
      return 'All';
    }
    // If user says 'recent' or 'recently' treat as monthly
    if (t.contains('recent') || t.contains('recently') || t.contains('past')) {
      return 'Monthly';
    }
    return 'All';
  }

  // Return list filtered by timeframe key (Daily, Weekly, Monthly, Yearly or All)
  List<Expense> _expensesForKey(String key) {
    final DateTime now = DateTime.now();
    switch (key) {
      case 'Daily':
        return widget.expenses
            .where((Expense e) => _sameDay(e.date, now))
            .toList(); // Specify type
      case 'DailyPrev':
        final DateTime prev = now.subtract(const Duration(days: 1));
        return widget.expenses
            .where((Expense e) => _sameDay(e.date, prev))
            .toList(); // Specify type
      case 'Weekly':
        final DateTime start = now.subtract(
          Duration(days: now.weekday - 1),
        ); // Monday
        return widget.expenses
            .where(
              (Expense e) => e.date.isAfter(
                start.subtract(const Duration(milliseconds: 1)),
              ),
            )
            .toList(); // Specify type
      case 'WeeklyPrev':
        final DateTime startThis = now.subtract(
          Duration(days: now.weekday - 1),
        );
        final DateTime startPrev = startThis.subtract(const Duration(days: 7));
        final DateTime endPrev = startThis.subtract(
          const Duration(milliseconds: 1),
        );
        return widget.expenses
            .where(
              (Expense e) =>
                  e.date.isAfter(
                    startPrev.subtract(const Duration(milliseconds: 1)),
                  ) &&
                  e.date.isBefore(endPrev.add(const Duration(days: 1))),
            )
            .toList(); // Specify type
      case 'Monthly':
        return widget.expenses
            .where(
              (Expense e) =>
                  e.date.year == now.year && e.date.month == now.month,
            )
            .toList(); // Specify type
      case 'MonthlyPrev':
        final DateTime prevMonth = DateTime(now.year, now.month - 1, now.day);
        return widget.expenses
            .where(
              (Expense e) =>
                  e.date.year == prevMonth.year &&
                  e.date.month == prevMonth.month,
            )
            .toList(); // Specify type
      case 'Yearly':
        return widget.expenses
            .where((Expense e) => e.date.year == now.year)
            .toList(); // Specify type
      case 'YearlyPrev':
        final DateTime prevYear = DateTime(now.year - 1, now.month, now.day);
        return widget.expenses
            .where((Expense e) => e.date.year == prevYear.year)
            .toList(); // Specify type
      case 'All':
      default:
        return List<Expense>.from(widget.expenses); // Return a copy for 'All'
    }
  }

  // Generate human-like varied replies
  String _variedReply(List<String> templates, Map<String, String> ctx) {
    final String templ = (templates..shuffle()).first;
    String out = templ;
    ctx.forEach((String k, String v) {
      out = out.replaceAll('{$k}', v);
    }); // Specify type
    return out;
  }

  // Core: analyze expenses and build suggestions (re-usable)
  Map<String, dynamic> _analyzeExpenses(List<Expense> list) {
    double total = 0.0;
    final Map<String, double> cat = <String, double>{};
    for (final Expense e in list) {
      // Specify type
      total += e.amount;
      cat[e.category] = (cat[e.category] ?? 0) + e.amount;
    }
    final List<MapEntry<String, double>> cats = cat.entries.toList();
    cats.sort(
      (MapEntry<String, double> a, MapEntry<String, double> b) =>
          b.value.compareTo(a.value),
    ); // Specify type
    return {
      'total': total,
      'count': list.length,
      'byCategory': cat,
      'topCategory': cats.isNotEmpty ? cats.first : null,
    };
  }

  // Produce suggestions based on analysis
  List<String> _makeSuggestions(List<Expense> list) {
    final Map<String, dynamic> a = _analyzeExpenses(list);
    final double total = a['total'] as double;
    final Map<String, double> cat = a['byCategory'] as Map<String, double>;
    final List<String> out = <String>[];
    if (list.isEmpty) {
      out.add('I do not see expenses in that timeframe.');
      return out;
    }
    // small purchases
    final List<Expense> smalls = list
        .where((Expense e) => e.amount < 100)
        .toList(); // Specify type
    final double smallsTotal = smalls.fold(
      0.0,
      (double s, Expense e) => s + e.amount,
    ); // Specify type
    if (smalls.isNotEmpty && smallsTotal > 200) {
      out.add(
        'You have many small purchases (₹${smallsTotal.toStringAsFixed(2)} total). Consider batching purchases or tracking subscriptions.',
      );
    }
    // top category advice
    if (a['topCategory'] != null) {
      final MapEntry<String, double> tc =
          a['topCategory'] as MapEntry<String, double>; // Specify type
      final String catName = tc.key;
      final double catAmount = tc.value;
      out.add(
        'Most spending is in $catName (₹${catAmount.toStringAsFixed(2)}). Try lowering frequency or finding cheaper alternatives.',
      );
    }
    // generic advice based on total
    if (total > 50000) {
      out.add(
        'High spending detected — consider reviewing recurring expenses and setting a monthly limit.',
      );
    } else if (total > 20000)
      out.add('Moderate spending — small savings can make a difference.');
    else
      out.add(
        'Spending looks under control, but keep tracking to spot trends.',
      );
    return out;
  }

  // Very simple future "prediction" - linear extrapolation over month
  String _predictNextMonth() {
    // Changed to use all expenses to get current month's data
    final DateTime now = DateTime.now();
    final List<Expense> monthList = widget.expenses
        .where(
          (Expense e) => e.date.year == now.year && e.date.month == now.month,
        )
        .toList(); // Specify type
    if (monthList.isEmpty) {
      // If no expenses this month, use average monthly from all available data
      if (widget.expenses.isEmpty) {
        return 'No data to predict from.';
      }
      final Map<int, double> yearlyTotals = {}; // Map year to total
      final Map<int, int> yearlyMonths =
          {}; // Map year to number of months with data (bitmask)

      for (final Expense e in widget.expenses) {
        // Specify type
        yearlyTotals[e.date.year] =
            (yearlyTotals[e.date.year] ?? 0.0) + e.amount;
        yearlyMonths[e.date.year] =
            (yearlyMonths[e.date.year] ?? 0) |
            (1 << (e.date.month - 1)); // Use bitmask for unique months
      }

      double totalMonthlyAvg = 0.0;
      int numMonths = 0;
      yearlyTotals.forEach((int year, double total) {
        // Specify type
        numMonths += _countSetBits(yearlyMonths[year]!); // Use helper function
        totalMonthlyAvg += total;
      });

      if (numMonths > 0) {
        return 'Based on past data ($numMonths months), expected next month spending ~ ₹${(totalMonthlyAvg / numMonths).toStringAsFixed(2)} (rough average).';
      }
      return 'No specific monthly data available. Estimated based on all recorded expenses: ₹${(_sum(widget.expenses) / (widget.expenses.isNotEmpty ? widget.expenses.length : 1)).toStringAsFixed(2)} per expense (rough estimate).';
    }
    final double monthSum = monthList.fold(
      0.0,
      (double s, Expense e) => s + e.amount,
    ); // Specify type
    // assume similar next month
    return 'Estimated next month spending: ~₹${(monthSum).toStringAsFixed(2)} (rough projection based on this month).';
  }

  // Parse intent and generate a response
  String _generateResponse(String input) {
    final String raw = input.trim();
    final String text = _normalize(raw);
    final String timeframe = _parseTimeframe(text); // can be 'All' or others
    final List<Expense> subset = _expensesForKey(timeframe); // Specify type
    // intents
    if (_fuzzyContains(text, 'total') ||
        _fuzzyContains(text, 'sum') ||
        _fuzzyContains(text, 'how much')) {
      final Map<String, dynamic> a = _analyzeExpenses(subset);
      final double total = a['total'] as double;
      final int count = a['count'] as int;
      return _variedReply(
        <String>[
          // Specify type
          'You spent ₹{total} during {period} across {count} items.',
          'Total for {period}: ₹{total} ( {count} transactions ).',
          'I calculate ₹{total} in expenses for {period}.',
        ],
        <String, String>{
          'total': total.toStringAsFixed(2),
          'period': timeframe == 'All' ? 'all time' : timeframe.toLowerCase(),
          'count': count.toString(),
        },
      ); // Specify type
    }

    if (_fuzzyContains(text, 'top') ||
        _fuzzyContains(text, 'most') ||
        _fuzzyContains(text, 'category')) {
      final Map<String, dynamic> a = _analyzeExpenses(subset);
      final MapEntry<String, double>? top =
          a['topCategory'] as MapEntry<String, double>?; // Specify type
      if (top == null) return 'No category data for that period.';
      return _variedReply(
        <String>[
          // Specify type
          'Top category is {cat} with ₹{amt}.',
          'You spent most on {cat}: ₹{amt}.',
          '{cat} is the highest spending category (₹{amt}).',
        ],
        <String, String>{'cat': top.key, 'amt': top.value.toStringAsFixed(2)},
      ); // Specify type
    }

    if (_fuzzyContains(text, 'suggest') ||
        _fuzzyContains(text, 'advice') ||
        _fuzzyContains(text, 'save')) {
      final List<String> sug = _makeSuggestions(subset); // Specify type
      if (sug.isEmpty) return 'I don\'t have suggestions for that.';
      return sug.join(' ');
    }

    if (_fuzzyContains(text, 'predict') ||
        _fuzzyContains(text, 'forecast') ||
        _fuzzyContains(text, 'next month') ||
        _fuzzyContains(text, 'estimate')) {
      return _predictNextMonth(); // No argument needed as it uses widget.expenses
    }

    if (_fuzzyContains(text, 'hello') ||
        _fuzzyContains(text, 'hi') ||
        _fuzzyContains(text, 'hey')) {
      return _variedReply(<String>[
        'Hi — how can I help with your expenses today?',
        'Hello! Ask me about totals, categories, or savings suggestions.',
      ], <String, String>{}); // Specify type
    }

    // follow-up: if user asked short question and we have last user context, try to answer based on it
    if (raw.split(' ').length <= 4 && _lastUser != null) {
      // try to resolve pronouns like "and this month?" -> map to last timeframe
      final String last = _normalize(_lastUser!);
      if (last.contains('this month') || last.contains('month')) {
        final List<Expense> cur = _expensesForKey('Monthly'); // Specify type
        final Map<String, dynamic> a = _analyzeExpenses(cur);
        return 'For this month, total is ₹${(a['total'] as double).toStringAsFixed(2)} across ${a['count']} items.';
      }
    }

    // fallback: try to answer with quick insights
    final Map<String, dynamic> quick = _analyzeExpenses(subset);
    if ((quick['total'] as double) > 0) {
      return 'I can help — try asking "total this month", "suggest ways to save", or "what did I spend most on?".';
    }

    return 'Sorry, I didn\'t understand that. You can ask things like: "How much did I spend this month?", "Suggest savings", or "What is my top category?"';
  }

  // Send flow
  void _send() {
    final String txt = _controller.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      _messages.add(<String, String>{
        'from': 'user',
        'text': txt,
      }); // Specify type
      _lastUser = txt;
      _controller.clear();
    });
    // compute response
    final String resp = _generateResponse(txt);
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      setState(() {
        _messages.add(<String, String>{
          'from': 'assistant',
          'text': resp,
        }); // Specify type
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Assistant')),
        body: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (BuildContext ctx, int idx) {
                  final Map<String, String> m = _messages[idx]; // Specify type
                  final bool isUser = m['from'] == 'user';
                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Card(
                      color: isUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          m['text'] ?? '',
                          style: TextStyle(
                            color: isUser
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Ask me anything about your expenses...',
                        ),
                        onSubmitted: (String _) => _send(),
                      ),
                    ), // Specify type
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _send,
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

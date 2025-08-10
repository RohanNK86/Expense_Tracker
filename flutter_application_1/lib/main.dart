import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

void main() {
  runApp(MainApp());
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
  _ExpenseHomePageState createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  final List<Expense> _expenses = [];
  final List<String> _categories = [
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
  double _monthlyTarget = 0.0; // New: Monthly spending target

  List<Expense> get _filteredExpenses {
    return _expenses.where((e) {
      final matchesSearch =
          _searchQuery.trim().isEmpty ||
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDate = _selectedDate == null
          ? true
          : (e.date.year == _selectedDate!.year &&
                e.date.month == _selectedDate!.month &&
                e.date.day == _selectedDate!.day);
      return matchesSearch && matchesDate;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  double get totalAmount {
    return _filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  // New: Calculate total expenses for the current month
  double get _currentMonthTotal {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Map<String, double> get categoryTotals {
    final Map<String, double> map = {};
    for (var c in _categories) {
      map[c] = 0.0;
    }
    for (var e in _expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  void _addExpense(Expense expense) {
    setState(() {
      _expenses.add(expense);
    });
  }

  void _updateExpense(String id, Expense newExpense) {
    final index = _expenses.indexWhere((e) => e.id == id);
    if (index >= 0) {
      setState(() {
        _expenses[index] = newExpense;
      });
    }
  }

  void _deleteExpenseById(String id) {
    setState(() {
      _expenses.removeWhere((e) => e.id == id);
    });
  }

  void _openAddExpenseScreen() async {
    final result = await Navigator.push<Expense>(
      context,
      MaterialPageRoute<Expense>(
        builder: (ctx) => AddEditExpenseScreen(categories: _categories),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      _addExpense(result);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Expense added ✅")));
    }
  }

  void _openEditExpenseScreen(Expense expense) async {
    final result = await Navigator.push<Expense>(
      context,
      MaterialPageRoute<Expense>(
        builder: (ctx) => AddEditExpenseScreen(
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
      ).showSnackBar(SnackBar(content: Text("Expense updated ✏️")));
    }
  }

  void _pickDate() async {
    final pickedDate = await showDatePicker(
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
    final searchController = TextEditingController(text: _searchQuery);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: <Widget>[
            Icon(Icons.search),
            SizedBox(width: 8),
            Text("Search Expenses"),
          ],
        ),
        content: TextField(
          controller: searchController,
          decoration: InputDecoration(hintText: "Title or category"),
          autofocus: true,
          textInputAction: TextInputAction.search,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = searchController.text;
              });
              Navigator.of(ctx).pop();
            },
            child: Text("Search"),
          ),
        ],
      ),
    );
  }

  void _openCategoriesScreen() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute<List<String>>(
        builder: (ctx) =>
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

  void _exportAsCSV() {
    if (_expenses.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Export"),
          content: Text("No expenses to export."),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text("OK"),
            ),
          ],
        ),
      );
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln('id,title,amount,category,date');
    for (var e in _expenses) {
      buffer.writeln(
        '${e.id},${_escapeCsv(e.title)},${e.amount},${e.category},${e.date.toIso8601String()}',
      );
    }
    final csv = buffer.toString();
    Clipboard.setData(ClipboardData(text: csv));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("CSV Export"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text("CSV copied to clipboard. Preview:"),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
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
            child: Text("Done"),
          ),
        ],
      ),
    );
  }

  String _escapeCsv(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      final escaped = s.replaceAll('"', '""');
      return '"$escaped"';
    }
    return s;
  }

  void _confirmDelete(Expense expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete Expense"),
        content: Text("Are you sure you want to delete \"${expense.title}\"?"),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteExpenseById(expense.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Deleted")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showExpenseDetails(Expense e) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.receipt_long),
              title: Text(
                e.title,
                style: TextStyle(fontWeight: FontWeight.bold),
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
            Divider(),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text("Date"),
              subtitle: Text(e.date.toLocal().toString().split(' ')[0]),
            ),
            SizedBox(height: 8),
            Row(
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _openEditExpenseScreen(e);
                  },
                  icon: Icon(Icons.edit),
                  label: Text("Edit"),
                ),
                SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _confirmDelete(e);
                  },
                  icon: Icon(Icons.delete),
                  label: Text("Delete"),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              "ID: ${e.id}",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // New: Method to show monthly target dialog
  void _showMonthlyTargetDialog() {
    final targetController = TextEditingController(
      text: _monthlyTarget > 0 ? _monthlyTarget.toString() : "",
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: <Widget>[
            Icon(Icons.trending_up),
            SizedBox(width: 8),
            Text("Monthly Target"),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                "Current Month's Spending: ₹${_currentMonthTotal.toStringAsFixed(2)}",
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: targetController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Set Monthly Target (₹)",
                  hintText: "e.g. 5000.00",
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: (String? v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Please enter a target";
                  }
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed < 0) {
                    return "Enter a valid positive amount";
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
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newTarget =
                    double.tryParse(targetController.text.trim()) ?? 0.0;
                setState(() {
                  _monthlyTarget = newTarget;
                });
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Monthly target updated to ₹${_monthlyTarget.toStringAsFixed(2)}",
                    ),
                  ),
                );
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text("Expenses Snap"),
          actions: <Widget>[
            IconButton(
              tooltip: "Monthly Target",
              icon: Icon(Icons.trending_up), // New icon for monthly target
              onPressed: _showMonthlyTargetDialog,
            ),
            IconButton(
              tooltip: "Pick date filter",
              icon: Icon(Icons.calendar_today),
              onPressed: _pickDate,
            ),
            if (_selectedDate != null)
              IconButton(
                tooltip: "Clear date filter",
                icon: Icon(Icons.clear),
                onPressed: _clearDateFilter,
              ),
            IconButton(
              tooltip: widget.isDarkTheme ? "Light mode" : "Dark mode",
              icon: Icon(widget.isDarkTheme ? Icons.wb_sunny : Icons.dark_mode),
              onPressed: widget.onToggleTheme,
            ),
            IconButton(
              tooltip: "Search",
              icon: Icon(Icons.search),
              onPressed: _showSearchDialog,
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        body: Column(
          children: <Widget>[
            // Summary card (Card widget)
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
                      Icon(Icons.account_balance_wallet, size: 40),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "Total Spent",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              "Showing ${_filteredExpenses.length} items",
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(
                          "₹${totalAmount.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // New: Monthly Target Progress Card
            if (_monthlyTarget > 0)
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
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "Monthly Target Progress",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Spent: ₹${_currentMonthTotal.toStringAsFixed(2)} / Target: ₹${_monthlyTarget.toStringAsFixed(2)}",
                                style: TextStyle(fontSize: 12),
                              ),
                              SizedBox(height: 6),
                              LinearProgressIndicator(
                                value:
                                    _currentMonthTotal /
                                    _monthlyTarget.clamp(1.0, double.infinity),
                                color: _currentMonthTotal > _monthlyTarget
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
                    icon: Icon(Icons.bar_chart),
                    label: Text("Statistics"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (ctx) => StatisticsPage(
                            expenses: _expenses,
                            categoryTotals: categoryTotals,
                          ),
                        ),
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    icon: Icon(Icons.category),
                    label: Text("Categories"),
                    onPressed: _openCategoriesScreen,
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.upload_file),
                    label: Text("Export CSV"),
                    onPressed: _exportAsCSV,
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.person),
                    label: Text("Profile"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (ctx) => ProfilePage(
                            name: widget.userName, // Pass user name
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
            Divider(),
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
                      style: TextStyle(
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
                          deleteIcon: Icon(Icons.clear),
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
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      itemCount: _filteredExpenses.length,
                      itemBuilder: (ctx, idx) {
                        final exp = _filteredExpenses[idx];
                        return Card(
                          key: ValueKey<String>(exp.id),
                          margin: EdgeInsets.symmetric(
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
                              child: Text(exp.category.substring(0, 1)),
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
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _openEditExpenseScreen(exp),
                                ),
                                IconButton(
                                  tooltip: "Delete",
                                  icon: Icon(Icons.delete, color: Colors.red),
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
        floatingActionButton: FloatingActionButton(
          tooltip: "Add Expense",
          onPressed: _openAddExpenseScreen,
          child: Icon(Icons.add),
        ),
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
            Icon(Icons.receipt_long, size: 72, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              "No expenses yet.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              "Tap the + button to add your first expense.\nYou can also manage categories or view statistics.",
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _openAddExpenseScreen,
              icon: Icon(Icons.add),
              label: Text("Add Expense"),
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
                ), // Made gradient dynamic
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
                SizedBox(height: 10),
                Text(
                  widget.userName.isNotEmpty
                      ? widget.userName
                      : "Expenses Snap User", // Display user name
                  style: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Track your daily expenses easily",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text("Home"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.bar_chart),
            title: Text("Statistics"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (ctx) => StatisticsPage(
                    expenses: _expenses,
                    categoryTotals: categoryTotals,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.category),
            title: Text("Categories"),
            onTap: () {
              Navigator.pop(context);
              _openCategoriesScreen();
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text("Profile"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (ctx) => ProfilePage(
                    name: widget.userName, // Pass user name
                    email: widget.userEmail,
                    institute: widget.userInstitute,
                    onEdit: widget.onEditProfile,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.trending_up), // New: Monthly Target in Drawer
            title: Text("Monthly Target"),
            onTap: () {
              Navigator.pop(context);
              _showMonthlyTargetDialog(); // Re-use the dialog
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text("Settings"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (ctx) => SettingsPage(
                    isDark: widget.isDarkTheme,
                    toggleTheme: widget.onToggleTheme,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text("Help"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (ctx) => HelpPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text("About"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (ctx) => AboutPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// -------------------------------------
/// LAVENDER GRADIENT BACKGROUND WIDGET
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  static List<Color> getGradientColors(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return <Color>[
        Color(0xFF2A2C4A), // dark blue-gray
        Color(0xFF34375A), // slightly more purple-blue
        Color(0xFF42386E), // dark violet
        Color(0xFF5B3D5D), // dark rose/plum
      ];
    } else {
      return <Color>[
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
          colors: getGradientColors(
            Theme.of(context).brightness,
          ), // Made gradient dynamic
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

/// -------------------------------------
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
  _AddEditExpenseScreenState createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.expenseToEdit;
    _titleController = TextEditingController(text: edit?.title ?? "");
    _amountController = TextEditingController(
      text: edit != null ? edit.amount.toString() : "",
    );
    _selectedCategory =
        edit?.category ??
        (widget.categories.isNotEmpty ? widget.categories.first : 'Other');
    _selectedDate = edit?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
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

    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final category = _selectedCategory ?? 'Other';

    final existing = widget.expenseToEdit;
    final expense = Expense(
      id: existing?.id ?? _generateId(),
      title: title,
      amount: amount,
      category: category,
      date: _selectedDate,
    );

    Future<void>.delayed(Duration(milliseconds: 350), () {
      setState(() => _isSaving = false);
      Navigator.of(context).pop(expense);
    });
  }

  String _generateId() {
    final rnd = Random();
    return DateTime.now().millisecondsSinceEpoch.toString() +
        rnd.nextInt(9999).toString();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.expenseToEdit != null;
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(isEdit ? "Edit Expense" : "Add Expense"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.save),
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
                    decoration: InputDecoration(
                      labelText: "Title",
                      prefixIcon: Icon(Icons.title),
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? v) => (v == null || v.trim().isEmpty)
                        ? "Enter a title"
                        : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: "Amount (₹)",
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                      hintText: "e.g. 125.75",
                    ),
                    validator: (String? v) {
                      if (v == null || v.trim().isEmpty) return "Enter amount";
                      final parsed = double.tryParse(v.trim());
                      if (parsed == null || parsed <= 0) {
                        return "Enter valid amount";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
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
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.category),
                      labelText: "Category",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.calendar_today),
                          label: Text(
                            "Date: ${_selectedDate.toLocal().toString().split(' ')[0]}",
                          ),
                          onPressed: _pickDate,
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: Icon(Icons.today),
                        label: Text("Today"),
                        onPressed: () {
                          setState(() {
                            _selectedDate = DateTime.now();
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    children: widget.categories
                        .take(6)
                        .map<Widget>(
                          (String c) => ChoiceChip(
                            label: Text(c),
                            selected: _selectedCategory == c,
                            onSelected: (_) => setState(() {
                              _selectedCategory = c;
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: _isSaving
                              ? SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.check),
                          label: Text(isEdit ? "Update" : "Add"),
                          onPressed: _isSaving ? null : _save,
                        ),
                      ),
                      SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: Icon(Icons.close),
                        label: Text("Cancel"),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        "Tip: Use category chips to quickly pick a category. You can edit expenses later.",
                        style: TextStyle(fontSize: 13),
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

/// -------------------------------------
/// STATISTICS PAGE (summary widgets)
class StatisticsPage extends StatelessWidget {
  final List<Expense> expenses;
  final Map<String, double> categoryTotals;

  const StatisticsPage({
    super.key,
    required this.expenses,
    required this.categoryTotals,
  });

  double get total =>
      expenses.fold(0.0, (double sum, Expense item) => sum + item.amount);

  int get count => expenses.length;

  List<MapEntry<String, double>> get topCategories {
    final List<MapEntry<String, double>> list = categoryTotals.entries.toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final top = topCategories.take(5).toList();
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text("Statistics")),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: <Widget>[
              Card(
                child: ListTile(
                  leading: Icon(Icons.pie_chart),
                  title: Text("Total Spent"),
                  subtitle: Text("Across all time"),
                  trailing: Text(
                    "₹${total.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Icon(Icons.list),
                  title: Text("Total Entries"),
                  trailing: Text("$count"),
                ),
              ),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Top Categories",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                child: top.isEmpty
                    ? Center(child: Text("No categories yet"))
                    : ListView.separated(
                        itemCount: top.length,
                        separatorBuilder: (_, __) => Divider(),
                        itemBuilder: (ctx, idx) {
                          final e = top[idx];
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

/// -------------------------------------
/// PROFILE PAGE (editable fields!)
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
    final formKey = GlobalKey<FormState>(); // Added for form validation
    final nameController = TextEditingController(text: name); // Added
    final emailController = TextEditingController(text: email);
    final instituteController = TextEditingController(text: institute);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Edit Profile"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Your Name",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (String? v) => (v == null || v.trim().isEmpty)
                    ? "Name cannot be empty"
                    : null,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
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
              SizedBox(height: 8),
              TextFormField(
                controller: instituteController,
                decoration: InputDecoration(
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
            child: Text("Cancel"),
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
            child: Text("Save"),
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
        appBar: AppBar(title: Text("Profile")),
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
                child: Icon(Icons.person, size: 46),
              ),
              SizedBox(height: 12),
              Text(
                name.isNotEmpty ? name : "User Name",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ), // Display actual name
              SizedBox(height: 6),
              Card(
                child: ListTile(
                  leading: Icon(Icons.email),
                  title: Text("Email"),
                  subtitle: Text(email.isNotEmpty ? email : "Not set"),
                ),
              ),
              SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Icon(Icons.school),
                  title: Text("Institute"),
                  subtitle: Text(institute.isNotEmpty ? institute : "Not set"),
                ),
              ),
              SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => _openEditDialog(context),
                icon: Icon(Icons.edit),
                label: Text("Edit Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// -------------------------------------
/// CATEGORIES MANAGEMENT PAGE
class CategoriesPage extends StatefulWidget {
  final List<String> categories;
  const CategoriesPage({super.key, required this.categories});
  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late List<String> _local;
  final _controller = TextEditingController();

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
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_local.contains(text)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Category already exists")));
      return;
    }
    setState(() {
      _local.add(text);
      _controller.clear();
    });
  }

  void _deleteCategory(String cat) {
    if (cat == 'Other') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("'Other' cannot be removed")));
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
          title: Text("Manage Categories"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(_local),
              // Ensure text color is visible against the transparent AppBar's background
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
                      decoration: InputDecoration(
                        labelText: "New category",
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addCategory(),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _addCategory,
                    icon: Icon(Icons.add),
                    label: Text("Add"),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Expanded(
                child: _local.isEmpty
                    ? Center(child: Text("No categories"))
                    : ListView.separated(
                        itemCount: _local.length,
                        separatorBuilder: (_, __) => Divider(),
                        itemBuilder: (ctx, idx) {
                          final c = _local[idx];
                          return ListTile(
                            leading: Icon(Icons.label),
                            title: Text(c),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
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

/// -------------------------------------
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
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;
  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text("Settings")),
        body: ListView(
          children: <Widget>[
            SwitchListTile(
              value: widget.isDark,
              title: Text("Dark Theme"),
              onChanged: (bool value) {
                widget.toggleTheme();
                setState(() {});
              },
              secondary: Icon(Icons.dark_mode),
            ),
            SwitchListTile(
              value: _notifications,
              onChanged: (bool v) => setState(() => _notifications = v),
              title: Text("Notifications (demo)"),
              secondary: Icon(Icons.notifications),
            ),
            ListTile(
              leading: Icon(Icons.privacy_tip),
              title: Text("Privacy"),
              subtitle: Text("Manage privacy settings (demo)"),
              onTap: () {},
            ),
            ListTile(
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

/// -------------------------------------
/// ABOUT PAGE
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text("About App")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.account_balance_wallet, size: 72),
                SizedBox(height: 12),
                Text(
                  "Expenses Snap",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
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

/// -------------------------------------
/// HELP PAGE
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text("Help")),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView(
            children: <Widget>[
              Card(
                child: ListTile(
                  leading: Icon(Icons.lightbulb),
                  title: Text("How to add an expense"),
                  subtitle: Text("Tap + and fill the form."),
                ),
              ),
              SizedBox(height: 8),
              ExpansionTile(
                leading: Icon(Icons.search),
                title: Text("Searching & Filtering"),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      "Use the search icon to filter by title or category. Use the calendar icon to filter by date.",
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Icon(Icons.backup),
                  title: Text("Export"),
                  subtitle: Text("Export CSV and copy to clipboard."),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Contact Support",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ListTile(
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


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:khoroch/models/expense.dart';
import 'package:khoroch/database/database_helper.dart';

// NEW
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

final formatter = DateFormat.yMd();

class NewExpense extends StatefulWidget {
  const NewExpense({super.key, required this.onAddExpense});
  final void Function(Expense expense) onAddExpense;

  @override
  State<NewExpense> createState() => _NewExpenseState();
}

class _NewExpenseState extends State<NewExpense> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;
  Category _selectedCategory = Category.leisure;
  List<Expense> _suggestions = [];

  // OCR state
  bool _isScanning = false;

  // ------------------ Date Picker ------------------
  void _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: now,
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // ------------------ Suggestions (from DB) ------------------
  void _onTitleChanged(String input) async {
    if (input.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    final matches =
        await DatabaseHelper.instance.getMatchingExpenseSuggestions(input);
    setState(() {
      _suggestions = matches;
    });
  }

  void _fillFromSuggestion(Expense suggestion) {
    _titleController.text = suggestion.title;
    _amountController.text = suggestion.amount.toStringAsFixed(0);
    setState(() {
      _selectedCategory = suggestion.category;
      _suggestions = [];
    });
  }

  // ------------------ OCR: Scan / Parse ------------------
  Future<void> _scanReceipt({required ImageSource source}) async {
    try {
      setState(() => _isScanning = true);

      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) {
        setState(() => _isScanning = false);
        return;
      }

      final input = InputImage.fromFile(File(picked.path));
      final recognizer =
          TextRecognizer(script: TextRecognitionScript.latin);

      final result = await recognizer.processImage(input);
      await recognizer.close();

      final text = result.text;
      if (text.trim().isEmpty) {
        _showSnack('Couldn’t read text from this image.');
        setState(() => _isScanning = false);
        return;
      }

      _applyParsedReceipt(text);
    } catch (e) {
      _showSnack('Scan failed: $e');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _applyParsedReceipt(String text) {
    // Amount (৳, Tk, BDT, $, USD)
    final amountRegex = RegExp(
      r'(?:৳|Tk\.?|BDT|USD|\$)\s*([0-9]+(?:[\.,][0-9]{2})?)|([0-9]+(?:[\.,][0-9]{2})?)\s*(?:৳|Tk\.?|BDT|USD|\$)',
      caseSensitive: false,
    );
    String? amountStr;
    final amtMatch = amountRegex.firstMatch(text);
    if (amtMatch != null) {
      amountStr =
          (amtMatch.group(1) ?? amtMatch.group(2))?.replaceAll(',', '');
    }

    // Date (2025-08-09, 09/08/2025, 09-08-25, etc.)
    final dateRegex =
        RegExp(r'(\d{4}[/-]\d{1,2}[/-]\d{1,2})|(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})');
    DateTime? parsedDate;
    final dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) {
      parsedDate = _parseDateFlexible(dateMatch.group(0)!);
    }

    // Merchant guess: first meaningful line
    String? merchant;
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    for (final line in lines.take(6)) {
      if (RegExp(r'[A-Za-z]').hasMatch(line) && line.length >= 3) {
        merchant = line;
        break;
      }
    }

    // Category guess
    final cat = _guessCategory(text.toLowerCase());

    // Apply to UI if fields empty/unset
    if (merchant != null && _titleController.text.isEmpty) {
      _titleController.text = merchant!;
    }
    if (amountStr != null && _amountController.text.isEmpty) {
      _amountController.text = amountStr!;
    }
    if (parsedDate != null) _selectedDate = parsedDate;
    if (cat != null) _selectedCategory = cat;

    setState(() {});
    _showSnack('Receipt scanned — fields auto‑filled. Please review.');
  }

  Category? _guessCategory(String lower) {
    if (lower.contains('grocery') ||
        lower.contains('market') ||
        lower.contains('super shop') ||
        lower.contains('shwapno')) {
      return Category.grocery;
    }
    if (lower.contains('restaurant') ||
        lower.contains('food') ||
        lower.contains('cafe')) {
      return Category.food;
    }
    if (lower.contains('bus') ||
        lower.contains('uber') ||
        lower.contains('train') ||
        lower.contains('travel') ||
        lower.contains('airlines')) {
      return Category.travel;
    }
    if (lower.contains('software') ||
        lower.contains('office') ||
        lower.contains('subscription') ||
        lower.contains('saas')) {
      return Category.work;
    }
    if (lower.contains('movie') ||
        lower.contains('game') ||
        lower.contains('leisure')) {
      return Category.leisure;
    }
    return null;
  }

  DateTime? _parseDateFlexible(String ds) {
    final formats = <DateFormat>[
      DateFormat('yyyy-MM-dd'),
      DateFormat('yyyy/MM/dd'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('dd-MM-yyyy'),
      DateFormat('MM/dd/yyyy'),
      DateFormat('dd/MM/yy'),
      DateFormat('dd-MM-yy'),
    ];
    for (final f in formats) {
      try {
        return f.parseStrict(ds);
      } catch (_) {}
    }
    return null;
  }

  // ------------------ Submit ------------------
  void _submitExpenseData() {
    final enteredAmount =
        double.tryParse(_amountController.text.replaceAll(',', ''));
    final amountIsInvalid = enteredAmount == null || enteredAmount <= 0;

    if (_titleController.text.trim().isEmpty ||
        amountIsInvalid ||
        _selectedDate == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Invalid Input'),
          content: const Text('Please enter a valid title, amount, and date.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Okay'),
            ),
          ],
        ),
      );
      return;
    }

    final newExpense = Expense(
      title: _titleController.text.trim(),
      amount: enteredAmount,
      date: _selectedDate!,
      category: _selectedCategory,
    );

    widget.onAddExpense(newExpense);
    Navigator.pop(context);
  }

  // ------------------ Utils ------------------
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ------------------ UI (FULL-SCREEN PAGE) ------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Receipt actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: _isScanning
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.document_scanner_outlined),
                    label: Text(_isScanning ? 'Scanning…' : 'Scan receipt'),
                    onPressed: _isScanning
                        ? null
                        : () => _scanReceipt(source: ImageSource.camera),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('From gallery'),
                    onPressed: _isScanning
                        ? null
                        : () => _scanReceipt(source: ImageSource.gallery),
                  ),
                ],
              ),

              TextField(
                controller: _titleController,
                maxLength: 50,
                onChanged: _onTitleChanged,
                decoration: const InputDecoration(labelText: 'Title'),
              ),

              if (_suggestions.isNotEmpty)
                Container(
                  alignment: Alignment.centerLeft,
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final exp = _suggestions[index];
                      return ListTile(
                        dense: true,
                        title: Text(exp.title),
                        subtitle:
                            Text("৳${exp.amount} — ${exp.category.name}"),
                        onTap: () => _fillFromSuggestion(exp),
                      );
                    },
                  ),
                ),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixText: '৳',
                        labelText: 'Amount',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _selectedDate == null
                              ? 'No date selected'
                              : formatter.format(_selectedDate!),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_month),
                          onPressed: _presentDatePicker,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  DropdownButton<Category>(
                    value: _selectedCategory,
                    items: Category.values
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _submitExpenseData,
                    child: const Text('Save Expense'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

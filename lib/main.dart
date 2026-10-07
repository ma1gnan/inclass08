import 'package:flutter/material.dart';
import 'database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final helper = DatabaseHelper();

  try {
    await helper.init();
  } catch (error, stackTrace) {
    debugPrint(
      'Database initialization failed: $error\n$stackTrace',
    );

    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Could not open local storage. '
                'Restart the app and check the logs.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  runApp(
    DirectoryApp(helper: helper),
  );
}

class DirectoryApp extends StatelessWidget {
  final DatabaseHelper helper;

  const DirectoryApp({
    super.key,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fall Festival Roster',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
        ),
        useMaterial3: true,
      ),
      home: DirectoryScreen(helper: helper),
    );
  }
}

class DirectoryScreen extends StatefulWidget {
  final DatabaseHelper helper;

  const DirectoryScreen({
    super.key,
    required this.helper,
  });

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _ageController =
      TextEditingController();

  List<Map<String, dynamic>> _rows = [];

  int _rowCount = 0;

  bool _loading = true;
  bool _busy = false;

  String? _errorMessage;
  String? _feedbackMessage;

  int? _selectedId;

  bool get _isEditing => _selectedId != null;

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadRows() async {
    if (_busy) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final rows = await widget.helper.queryAllRows();
      final count = await widget.helper.queryRowCount();

      if (!mounted) {
        return;
      }

      setState(() {
        _rows = rows;
        _rowCount = count;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'Database read failed: $error\n$stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage =
            'Could not load guests. Tap Refresh to retry.';
      });
    }
  }

  Future<bool> _refreshAfterWrite({
    required String successMessage,
    required String failureMessage,
  }) async {
    try {
      final rows = await widget.helper.queryAllRows();
      final count = await widget.helper.queryRowCount();

      if (!mounted) {
        return false;
      }

      setState(() {
        _rows = rows;
        _rowCount = count;
        _feedbackMessage = successMessage;
        _errorMessage = null;
      });

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'Refresh after write failed: $error\n$stackTrace',
      );

      if (!mounted) {
        return false;
      }

      setState(() {
        _feedbackMessage = failureMessage;
      });

      return false;
    }
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Enter a guest name.';
    }

    return null;
  }

  String? _validateAge(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Enter an age.';
    }

    final age = int.tryParse(text);

    if (age == null) {
      return 'Age must be a whole number.';
    }

    if (age < 0 || age > 130) {
      return 'Age must be from 0 through 130.';
    }

    return null;
  }

  int? _validatedAge() {
    final text = _ageController.text.trim();
    return int.tryParse(text);
  }

  Future<void> _saveGuest() async {
    if (_busy) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _feedbackMessage = 'Please correct the highlighted fields.';
      });
      return;
    }

    final name = _nameController.text.trim();
    final age = _validatedAge();

    if (age == null || age < 0 || age > 130) {
      return;
    }

    final editingId = _selectedId;

    setState(() {
      _busy = true;
      _feedbackMessage = null;
      _errorMessage = null;
    });

    try {
      if (editingId == null) {
        final id = await widget.helper.insert({
          DatabaseHelper.columnName: name,
          DatabaseHelper.columnAge: age,
        });

        if (!mounted) {
          return;
        }

        _clearForm();

        final refreshed = await _refreshAfterWrite(
          successMessage: 'Saved guest ID $id.',
          failureMessage: 'Saved, but refresh failed. Tap Refresh.',
        );

        if (!refreshed && mounted) {
          setState(() {
            _errorMessage =
                'Saved, but the list could not be refreshed.';
          });
        }
      } else {
        final updated = await widget.helper.update({
          DatabaseHelper.columnId: editingId,
          DatabaseHelper.columnName: name,
          DatabaseHelper.columnAge: age,
        });

        if (!mounted) {
          return;
        }

        if (updated == 1) {
          _clearForm();

          final refreshed = await _refreshAfterWrite(
            successMessage:
                'Updated guest ID $editingId.',
            failureMessage:
                'Updated, but refresh failed. Tap Refresh.',
          );

          if (!refreshed && mounted) {
            setState(() {
              _errorMessage =
                  'Updated, but the list could not be refreshed.';
            });
          }
        } else {
          setState(() {
            _feedbackMessage =
                'Guest ID $editingId no longer exists. Reloading.';
          });

          await _loadRows();
        }
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Database write failed: $error\n$stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Could not save the guest. Your input was kept so you can retry.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _deleteGuest(Map<String, dynamic> row) async {
    if (_busy) {
      return;
    }

    final id = row[DatabaseHelper.columnId] as int;
    final name = row[DatabaseHelper.columnName] as String;
    final age = row[DatabaseHelper.columnAge] as int;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete guest?'),
          content: Text(
            'Delete guest ID $id: $name, age $age?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _busy = true;
      _feedbackMessage = null;
      _errorMessage = null;
    });

    try {
      final deleted = await widget.helper.delete(id);

      if (!mounted) {
        return;
      }

      if (deleted == 1) {
        if (_selectedId == id) {
          _clearForm();
        }

        final refreshed = await _refreshAfterWrite(
          successMessage: 'Deleted guest ID $id.',
          failureMessage:
              'Deleted, but refresh failed. Tap Refresh.',
        );

        if (!refreshed && mounted) {
          setState(() {
            _errorMessage =
                'Deleted, but the list could not be refreshed.';
          });
        }
      } else {
        setState(() {
          _feedbackMessage =
              'Guest ID $id no longer exists. Reloading.';
        });

        await _loadRows();
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Database delete failed: $error\n$stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Could not delete guest ID $id. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  void _beginEdit(Map<String, dynamic> row) {
    if (_busy) {
      return;
    }

    final id = row[DatabaseHelper.columnId] as int;
    final name = row[DatabaseHelper.columnName] as String;
    final age = row[DatabaseHelper.columnAge] as int;

    setState(() {
      _selectedId = id;
      _nameController.text = name;
      _ageController.text = age.toString();
      _feedbackMessage = 'Editing guest ID $id.';
      _errorMessage = null;
    });
  }

  void _clearForm() {
    _selectedId = null;
    _nameController.clear();
    _ageController.clear();
  }

  void _cancelEdit() {
    if (_busy) {
      return;
    }

    setState(() {
      _clearForm();
      _feedbackMessage = 'Edit canceled. No database changes made.';
      _errorMessage = null;
    });
  }

  Future<void> _refresh() async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
      _feedbackMessage = null;
    });

    try {
      final rows = await widget.helper.queryAllRows();
      final count = await widget.helper.queryRowCount();

      if (!mounted) {
        return;
      }

      setState(() {
        _rows = rows;
        _rowCount = count;
        _loading = false;
        _errorMessage = null;
        _feedbackMessage = 'List refreshed from local storage.';
      });
    } catch (error, stackTrace) {
      debugPrint(
        'Refresh failed: $error\n$stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage =
            'Refresh failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Widget _buildForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Edit Guest' : 'Add Guest',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                enabled: !_busy,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Guest name',
                  border: OutlineInputBorder(),
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  helperText: 'Enter a whole number from 0 through 130.',
                  border: OutlineInputBorder(),
                ),
                validator: _validateAge,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _saveGuest,
                      icon: Icon(
                        _isEditing ? Icons.save : Icons.person_add,
                      ),
                      label: Text(
                        _isEditing ? 'Save' : 'Add',
                      ),
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : _cancelEdit,
                        child: const Text('Cancel Edit'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestList() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null && _rows.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh / Retry'),
          ),
        ],
      );
    }

    if (_rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No festival guests yet',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final row in _rows)
          Card(
            child: ListTile(
              title: Text(
                row[DatabaseHelper.columnName] as String,
              ),
              subtitle: Text(
                'ID: ${row[DatabaseHelper.columnId]}  '
                'Age: ${row[DatabaseHelper.columnAge]}',
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Edit',
                    onPressed:
                        _busy ? null : () => _beginEdit(row),
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed:
                        _busy ? null : () => _deleteGuest(row),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fall Festival Roster'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Festival Guests',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Records stored locally in SQLite: $_rowCount',
            ),
            if (_feedbackMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _feedbackMessage!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (_errorMessage != null &&
                _rows.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            _buildForm(),
            const SizedBox(height: 16),
            _buildGuestList(),
          ],
        ),
      ),
    );
  }
}
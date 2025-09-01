import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'services/task_service.dart';
import 'services/currency_service.dart' as currency_service;
import 'models/task_model.dart';
import 'main.dart';
import 'calculator_page.dart';
import 'news_page.dart';
import 'multi_currency_page.dart';
import 'trend_chart.dart';
import 'rate_list_page.dart';
import 'world_clock.dart';
import 'setting_page.dart';
import 'login.dart';
import 'support_help_screen.dart';
import 'services/app_version_service.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<currency_service.Currency> currencies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrencies();

    // Clean up old task history periodically to improve performance
    TaskService.cleanupOldTaskHistory();

    // Start periodic task checking
    _startTaskChecking();
  }

  @override
  void dispose() {
    _stopTaskChecking();
    super.dispose();
  }

  Timer? _taskCheckTimer;

  void _startTaskChecking() {
    // Check for due tasks every 5 minutes when app is active
    _taskCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      TaskService.checkAndExecuteDueTasks();
    });
  }

  void _stopTaskChecking() {
    _taskCheckTimer?.cancel();
  }

  Future<void> _loadCurrencies() async {
    try {
      final loadedCurrencies =
          await currency_service.CurrencyService.loadCurrencies();

      // Get favorite currencies from app settings
      final appSettings = Provider.of<AppSettings>(context, listen: false);
      final favoriteCurrencies = appSettings.favoriteCurrencies;

      // Sort currencies: favorites first, then others (both active and inactive)
      final sortedCurrencies = <currency_service.Currency>[];

      // Add favorite currencies first (both active and inactive)
      for (final favoriteCode in favoriteCurrencies) {
        try {
          final favoriteCurrency = loadedCurrencies.firstWhere(
            (c) => c.code == favoriteCode,
          );
          sortedCurrencies.add(favoriteCurrency);
        } catch (e) {
          // Currency not found, skip it
          print('Favorite currency $favoriteCode not found');
        }
      }

      // Add remaining currencies (both active and inactive)
      for (final currency in loadedCurrencies) {
        if (!favoriteCurrencies.contains(currency.code)) {
          sortedCurrencies.add(currency);
        }
      }

      setState(() {
        currencies = sortedCurrencies;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateAndClose(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Currency Tasks'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.iconTheme?.color,
        leading: IconButton(
          icon: Lottie.asset('assets/Menu.json', width: 32, height: 32),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          // User Profile Picture
          GestureDetector(
            onTap:
                () => _navigateAndClose(
                  context,
                  SettingsPage(
                    onThemeChanged: (isDark) {
                      Provider.of<AppSettings>(
                        context,
                        listen: false,
                      ).setDarkMode(isDark);
                    },
                    onDecimalChanged: (decimalPlaces) {
                      Provider.of<AppSettings>(
                        context,
                        listen: false,
                      ).setDecimalPlaces(decimalPlaces);
                    },
                    onBaseCurrencyChanged: (currency) {
                      Provider.of<AppSettings>(
                        context,
                        listen: false,
                      ).setBaseCurrency(currency);
                    },
                    onAutoUpdateChanged: (autoUpdate) {
                      Provider.of<AppSettings>(
                        context,
                        listen: false,
                      ).setAutoUpdateRates(autoUpdate);
                    },
                    onBiometricChanged: (biometric) {
                      Provider.of<AppSettings>(
                        context,
                        listen: false,
                      ).setBiometricAuth(biometric);
                    },
                    onVibrationChanged: (vibration) {
                      Provider.of<AppSettings>(
                        context,
                        listen: false,
                      ).setHapticFeedback(vibration);
                    },
                    onCalculatorChanged: (calculator) {
                      Provider.of<AppSettings>(
                        context,
                        listen: false,
                      ).setShowCalculator(calculator);
                    },
                  ),
                ),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateTaskDialog(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF1E3A8A),
                Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF334155)
                    : const Color(0xFF3B82F6),
              ],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Professional Drawer Header
              Container(
                height: 180,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF1E3A8A),
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF475569)
                          : const Color(0xFF2563EB),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Icon with subtle animation
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Lottie.asset(
                          'assets/Menu Icon.json',
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // App Name
                    Text(
                      'CurrenSee Pro',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    // Version text with fade-in animation
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: FutureBuilder<String>(
                            future: AppVersionService.getAppVersion(),
                            builder: (context, snapshot) {
                              return Text(
                                'Version ${snapshot.data ?? '1.0.6'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white70
                                          : Colors.white70,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Menu Items
              _buildDrawerItem(
                context,
                icon: Icons.currency_exchange,
                title: 'Currency Converter',
                onTap: () => _navigateAndClose(context, const MainScreen()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.newspaper,
                title: 'Market News',
                onTap: () => _navigateAndClose(context, const NewsScreen()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.calculate,
                title: 'Multi-Currency',
                onTap:
                    () => _navigateAndClose(
                      context,
                      const MultiCurrencyConverter(),
                    ),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.trending_up,
                title: 'Trend Analysis',
                onTap:
                    () => _navigateAndClose(context, const CurrencyChartPage()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.timer,
                title: 'World Clock',
                onTap: () => _navigateAndClose(context, const WorldClockPage()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.list_alt,
                title: 'Rate List',
                onTap: () => _navigateAndClose(context, const RateListPage()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.calculate_outlined,
                title: 'Calculator',
                onTap:
                    () => _navigateAndClose(context, const CalculatorsScreen()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.task_alt,
                title: 'Currency Tasks',
                onTap: () => _navigateAndClose(context, const TaskPage()),
                isSelected: true,
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),
              // Settings Section
              _buildDrawerItem(
                context,
                icon: Icons.settings,
                title: 'Settings',
                onTap:
                    () => _navigateAndClose(
                      context,
                      SettingsPage(
                        onThemeChanged: (isDark) {
                          Provider.of<AppSettings>(
                            context,
                            listen: false,
                          ).setDarkMode(isDark);
                        },
                        onDecimalChanged: (decimalPlaces) {
                          Provider.of<AppSettings>(
                            context,
                            listen: false,
                          ).setDecimalPlaces(decimalPlaces);
                        },
                        onBaseCurrencyChanged: (currency) {
                          Provider.of<AppSettings>(
                            context,
                            listen: false,
                          ).setBaseCurrency(currency);
                        },
                        onAutoUpdateChanged: (autoUpdate) {
                          Provider.of<AppSettings>(
                            context,
                            listen: false,
                          ).setAutoUpdateRates(autoUpdate);
                        },
                        onBiometricChanged: (biometric) {
                          Provider.of<AppSettings>(
                            context,
                            listen: false,
                          ).setBiometricAuth(biometric);
                        },
                        onVibrationChanged: (vibration) {
                          Provider.of<AppSettings>(
                            context,
                            listen: false,
                          ).setHapticFeedback(vibration);
                        },
                        onCalculatorChanged: (calculator) {
                          Provider.of<AppSettings>(
                            context,
                            listen: false,
                          ).setShowCalculator(calculator);
                        },
                      ),
                    ),
              ),
              // Help & Support Section
              _buildDrawerItem(
                context,
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap:
                    () => _navigateAndClose(context, const SupportHelpScreen()),
              ),
              // Logout Section
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),
              _buildDrawerItem(
                context,
                icon: Icons.logout,
                title: 'Logout',
                onTap: () => _navigateAndClose(context, const SignInScreen()),
              ),
            ],
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<List<Task>>(
                stream: TaskService.getUserTasks(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tasks = snapshot.data!;

                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 64,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Tasks Yet',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first currency monitoring task',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _showCreateTaskDialog(context),
                            child: const Text('Create Task'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildTaskCard(task);
                    },
                  );
                },
              ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  task.taskName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleTaskAction(value, task),
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${task.amount} ${task.fromCurrency} → ${task.toCurrency}'),
            Text('${task.frequency} at ${task.time.format(context)}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _executeTask(task),
                    child: const Text('Execute Now'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _toggleTaskStatus(task),
                    child: Text(task.isActive ? 'Pause' : 'Resume'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleTaskAction(String action, Task task) {
    switch (action) {
      case 'edit':
        _showEditTaskDialog(context, task);
        break;
      case 'delete':
        _showDeleteTaskDialog(context, task);
        break;
    }
  }

  void _showCreateTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => TaskDialog(
            currencies: currencies,
            onTaskCreated: (task) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task created successfully!')),
              );
            },
          ),
    );
  }

  void _showEditTaskDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder:
          (context) => TaskDialog(
            currencies: currencies,
            task: task,
            onTaskCreated: (updatedTask) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task updated successfully!')),
              );
            },
          ),
    );
  }

  void _showDeleteTaskDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text(
              'Are you sure you want to delete "${task.taskName}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await TaskService.deleteTask(task.id, 'User deleted');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Task deleted successfully!'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete task: $e')),
                      );
                    }
                  }
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _executeTask(Task task) async {
    try {
      final rate = 1.0 + (DateTime.now().millisecondsSinceEpoch % 100) / 1000;
      final convertedAmount = task.amount * rate;

      await TaskService.completeTask(task.id, convertedAmount, rate);
      await TaskService.showTaskNotification(task, convertedAmount, rate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Task executed! ${task.amount} ${task.fromCurrency} = ${convertedAmount.toStringAsFixed(2)} ${task.toCurrency}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to execute task: $e')));
      }
    }
  }

  Future<void> _toggleTaskStatus(Task task) async {
    try {
      final updatedTask = task.copyWith(isActive: !task.isActive);
      await TaskService.updateTask(updatedTask);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Task ${task.isActive ? 'paused' : 'resumed'} successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update task: $e')));
      }
    }
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class TaskDialog extends StatefulWidget {
  final List<currency_service.Currency> currencies;
  final Task? task;
  final Function(Task) onTaskCreated;

  const TaskDialog({
    super.key,
    required this.currencies,
    this.task,
    required this.onTaskCreated,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedFromCurrency;
  String? _selectedToCurrency;
  String _selectedFrequency = 'daily';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _taskNameController.text = widget.task!.taskName;
      _amountController.text = widget.task!.amount.toString();
      _selectedFromCurrency = widget.task!.fromCurrency;
      _selectedToCurrency = widget.task!.toCurrency;
      _selectedFrequency = widget.task!.frequency;
      _selectedTime = widget.task!.time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task == null ? 'Create Task' : 'Edit Task'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _taskNameController,
              decoration: const InputDecoration(labelText: 'Task Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a task name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFromCurrency,
                    decoration: const InputDecoration(
                      labelText: 'From Currency',
                    ),
                    items:
                        widget.currencies.map((currency) {
                          final appSettings = Provider.of<AppSettings>(
                            context,
                            listen: false,
                          );
                          final isFavorite = appSettings.isFavoriteCurrency(
                            currency.code,
                          );
                          return DropdownMenuItem(
                            value: currency.code,
                            child: Row(
                              children: [
                                Text(
                                  '${currency.flag} ${currency.code}',
                                  style: TextStyle(
                                    color: currency.status == 'inactive' 
                                        ? Colors.grey 
                                        : null,
                                  ),
                                ),
                                if (isFavorite) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                ],
                                if (currency.status == 'inactive') ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'BLOCKED',
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFromCurrency = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a currency';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedToCurrency,
                    decoration: const InputDecoration(labelText: 'To Currency'),
                    items:
                        widget.currencies.map((currency) {
                          final appSettings = Provider.of<AppSettings>(
                            context,
                            listen: false,
                          );
                          final isFavorite = appSettings.isFavoriteCurrency(
                            currency.code,
                          );
                          return DropdownMenuItem(
                            value: currency.code,
                            child: Row(
                              children: [
                                Text(
                                  '${currency.flag} ${currency.code}',
                                  style: TextStyle(
                                    color: currency.status == 'inactive' 
                                        ? Colors.grey 
                                        : null,
                                  ),
                                ),
                                if (isFavorite) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                ],
                                if (currency.status == 'inactive') ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'BLOCKED',
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedToCurrency = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a currency';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFrequency,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text('Monthly'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFrequency = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (time != null) {
                        setState(() {
                          _selectedTime = time;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Time'),
                      child: Text(_selectedTime.format(context)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveTask,
          child: Text(widget.task == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final task = Task(
        id: widget.task?.id ?? '',
        userId: userId,
        userName: '', // Will be filled by TaskService
        userEmail: '', // Will be filled by TaskService
        userPhotoUrl: null, // Will be filled by TaskService
        taskName: _taskNameController.text.trim(),
        fromCurrency: _selectedFromCurrency!,
        toCurrency: _selectedToCurrency!,
        amount: double.parse(_amountController.text),
        frequency: _selectedFrequency,
        time: _selectedTime,
        isActive: true,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        lastExecuted: widget.task?.lastExecuted,
        nextExecution: widget.task?.nextExecution,
      );

      if (widget.task == null) {
        final taskId = await TaskService.createTask(task);
        final createdTask = task.copyWith(id: taskId);
        await TaskService.scheduleTaskNotification(createdTask);
        widget.onTaskCreated(createdTask);
      } else {
        await TaskService.updateTask(task);
        await TaskService.scheduleTaskNotification(task);
        widget.onTaskCreated(task);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save task: $e')));
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/task_model.dart';
import 'services/task_service.dart';
import 'services/notification_manager.dart';
import 'main.dart';

import 'calculator_page.dart';
import 'setting_page.dart';
import 'news_page.dart';
import 'trend_chart.dart';
import 'world_clock.dart';
import 'multi_currency_page.dart' as multi_currency;
import 'rate_list_page.dart';
import 'support_help_screen.dart';
import 'services/app_version_service.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;

  bool _isLoading = false;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkNotificationPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkNotificationPermissions() async {
    final enabled = await NotificationManager.requestPermissions();
    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: 'Currency Tasks',
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors:
                  Theme.of(context).brightness == Brightness.dark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                      : [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
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
                    colors:
                        Theme.of(context).brightness == Brightness.dark
                            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                            : [
                              const Color(0xFF1E3A8A),
                              const Color(0xFF2563EB),
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
                          'assets/Menu Icon.json', // Your app icon animation
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // App Name
                    const Text(
                      'CurrenSee Pro',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
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
                      const multi_currency.MultiCurrencyConverter(),
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
                onTap: () => _navigateAndClose(context, const TaskScreen()),
              ),

              const SizedBox(height: 16),
              Divider(color: Theme.of(context).dividerColor, height: 1),
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
                        onBiometricChanged: (useBiometric) {
                          Provider.of<AppSettings>(
                            context,
                            listen: false,
                          ).setBiometricAuth(useBiometric);
                        },
                        onVibrationChanged: (vibration) {
                          Provider.of<AppSettings>(
                            context,
                            listen: false,
                          ).setHapticFeedback(vibration);
                        },
                        onCalculatorChanged: (showCalculator) {
                          Provider.of<AppSettings>(
                            context,
                            listen: false,
                          ).setShowCalculator(showCalculator);
                        },
                      ),
                    ),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.help_center,
                title: 'Help & Support',
                onTap:
                    () => _navigateAndClose(context, const SupportHelpScreen()),
              ),
              const SizedBox(height: 16),
              Divider(color: Theme.of(context).dividerColor, height: 1),
              const SizedBox(height: 16),
              _buildDrawerItem(
                context,
                icon: Icons.logout,
                title: 'Logout',
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/signin', (route) => false);
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: theme.colorScheme.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: theme.colorScheme.onPrimary,
              labelColor: theme.colorScheme.onPrimary,
              unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(
                0.7,
              ),
              tabs: const [
                Tab(text: 'Active Tasks', icon: Icon(Icons.task_alt)),
                Tab(text: 'History', icon: Icon(Icons.history)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildActiveTasksTab(), _buildHistoryTab()],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTaskDialog,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 8,
        icon: const Icon(Icons.schedule, size: 24),
        label: const Text(
          'New Task',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _navigateAndClose(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTasksTab() {
    return StreamBuilder<List<Task>>(
      stream: TaskService.getUserTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Task loading error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading tasks',
                  style: TextStyle(fontSize: 18, color: Colors.red[300]),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(fontSize: 12, color: Colors.red[300]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final tasks = snapshot.data ?? [];
        print('Tasks loaded: ${tasks.length}');

        if (tasks.isEmpty) {
          return _buildEmptyState(
            'No Active Tasks',
            'Create your first currency conversion task to get started',
            Icons.task_alt,
            'Create Task',
            _showCreateTaskDialog,
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
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<TaskHistory>>(
      stream: TaskService().getTaskHistoryStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('History loading error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading history',
                  style: TextStyle(fontSize: 18, color: Colors.red[300]),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(fontSize: 12, color: Colors.red[300]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final history = snapshot.data ?? [];
        print('History loaded: ${history.length}');

        if (history.isEmpty) {
          return _buildEmptyState(
            'No Task History',
            'Task execution history will appear here',
            Icons.history,
            null,
            null,
          );
        }

        return Column(
          children: [
            _buildHistoryHeader(history),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final entry = history[index];
                  return _buildHistoryCard(entry);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    String? actionText,
    VoidCallback? onAction,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.schedule, size: 20),
                label: Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreateTaskDialog() {
    showDialog(
      context: context,
      builder:
          (context) => TaskCreationDialog(
            onTaskCreated: (task) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Task "${task.taskName}" created successfully!',
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isActive ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.taskName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${task.amount} ${task.fromCurrency} → ${task.toCurrency}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${task.frequency.toUpperCase()} at ${task.time.format(context)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        task.isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: task.isActive ? Colors.green : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    task.isActive ? 'ACTIVE' : 'PAUSED',
                    style: TextStyle(
                      color: task.isActive ? Colors.green : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 3-dot menu
                PopupMenuButton<String>(
                  onSelected: (value) => _handleTaskAction(value, task),
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _executeTask(task),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Execute Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleTaskStatus(task, !task.isActive),
                    icon: Icon(
                      task.isActive ? Icons.pause : Icons.play_arrow,
                      size: 18,
                    ),
                    label: Text(task.isActive ? 'Pause' : 'Resume'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          task.isActive ? Colors.orange : Colors.green,
                      side: BorderSide(
                        color: task.isActive ? Colors.orange : Colors.green,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryHeader(List<TaskHistory> history) {
    final unreadCount = history.where((entry) => !entry.isRead).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unreadCount > 0)
                  Text(
                    '$unreadCount unread',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.mark_email_read),
              label: const Text('Mark All Read'),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear_all':
                  _showClearHistoryDialog();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all),
                        SizedBox(width: 8),
                        Text('Clear All History'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(TaskHistory entry) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      color:
          entry.isRead
              ? theme.cardColor
              : theme.colorScheme.primaryContainer.withOpacity(0.1),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: Icon(
            Icons.currency_exchange,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        title: Text(
          'Task Execution',
          style: TextStyle(
            fontWeight: entry.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rate: ${entry.rate.toStringAsFixed(4)} | Amount: ${entry.convertedAmount.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(entry.triggeredAt),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing:
            entry.isRead
                ? null
                : Icon(
                  Icons.circle,
                  size: 12,
                  color: theme.colorScheme.primary,
                ),
        onTap: () => _markHistoryAsRead(entry),
      ),
    );
  }

  void _handleTaskAction(String action, Task task) {
    switch (action) {
      case 'edit':
        _editTask(task);
        break;
      case 'delete':
        _deleteTask(task);
        break;
    }
  }

  void _editTask(Task task) {
    showDialog(
      context: context,
      builder:
          (context) => TaskEditDialog(
            task: task,
            onTaskUpdated: (updatedTask) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task updated successfully!')),
              );
            },
          ),
    );
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text(
              'Are you sure you want to delete "${task.displayName}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await TaskService.deleteTask(task.id, 'User deleted');
        await NotificationManager.cancelTaskNotification(task);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting task: $e')));
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _executeTask(Task task) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Simulate API call for real exchange rate
      await Future.delayed(const Duration(seconds: 1));

      // Generate realistic rate (you can replace with actual API call)
      final rate = 1.0 + (DateTime.now().millisecondsSinceEpoch % 100) / 1000;
      final convertedAmount = task.amount * rate;

      // Complete task and create history
      await TaskService.completeTask(task.id, convertedAmount, rate);

      // Show notification
      await TaskService.showTaskNotification(task, convertedAmount, rate);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Task Executed Successfully!'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Task: ${task.taskName}'),
                    const SizedBox(height: 8),
                    Text(
                      '${task.amount} ${task.fromCurrency} = ${convertedAmount.toStringAsFixed(2)} ${task.toCurrency}',
                    ),
                    const SizedBox(height: 8),
                    Text('Exchange Rate: ${rate.toStringAsFixed(4)}'),
                    const SizedBox(height: 8),
                    Text(
                      'Executed at: ${DateTime.now().toString().substring(0, 19)}',
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to execute task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleTaskStatus(Task task, bool isActive) async {
    try {
      final updatedTask = task.copyWith(isActive: isActive);

      await TaskService.updateTask(updatedTask);

      // Update notification scheduling based on status
      if (isActive) {
        // Task resumed - schedule notification
        await TaskService.scheduleTaskNotification(updatedTask);
      } else {
        // Task paused - cancel notification
        await NotificationManager.cancelTaskNotification(updatedTask);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isActive ? Icons.play_arrow : Icons.pause,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Task ${isActive ? 'resumed' : 'paused'} successfully!'),
              ],
            ),
            backgroundColor: isActive ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markHistoryAsRead(TaskHistory entry) async {
    if (!entry.isRead) {
      try {
        await TaskService().markTaskHistoryAsRead(entry.notificationId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error marking as read: $e')));
        }
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      setState(() => _isLoading = true);
      await TaskService().markAllTaskHistoryAsRead();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All marked as read')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking all as read: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showClearHistoryDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear All History'),
            content: const Text(
              'Are you sure you want to clear all task history? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear All'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await TaskService().clearAllTaskHistory();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('All history cleared')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error clearing history: $e')));
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}

class TaskCreationDialog extends StatefulWidget {
  final Function(Task) onTaskCreated;

  const TaskCreationDialog({super.key, required this.onTaskCreated});

  @override
  State<TaskCreationDialog> createState() => _TaskCreationDialogState();
}

class _TaskCreationDialogState extends State<TaskCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedFromCurrency;
  String? _selectedToCurrency;
  String _selectedFrequency = 'daily';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  double _sliderAmount = 1.0;

  List<Map<String, dynamic>> _currencies = [];
  bool _isLoadingCurrencies = true;

  @override
  void initState() {
    super.initState();
    _amountController.text = '1.00';
    _sliderAmount = 1.0;
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('currencies').get();
      final currencies =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'code': data['code'] ?? '',
              'name': data['name'] ?? '',
              'flag': data['flag'] ?? '',
              'status': data['status'] ?? 'active',
            };
          }).toList();

      // Sort currencies with favorites first
      final settings = Provider.of<AppSettings>(context, listen: false);
      final favoriteCurrencies = settings.favoriteCurrencies;

      currencies.sort((a, b) {
        final aIsFavorite = favoriteCurrencies.contains(a['code']);
        final bIsFavorite = favoriteCurrencies.contains(b['code']);

        if (aIsFavorite && !bIsFavorite) return -1;
        if (!aIsFavorite && bIsFavorite) return 1;
        return 0;
      });

      setState(() {
        _currencies = currencies;
        _isLoadingCurrencies = false;
      });
    } catch (e) {
      print('Error loading currencies: $e');
      setState(() {
        _isLoadingCurrencies = false;
      });
    }
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Task'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _taskNameController,
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                  hintText: 'e.g., Daily USD to PKR',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
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
                        hintText: 'Select currency',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items:
                          _isLoadingCurrencies
                              ? [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Loading...'),
                                ),
                              ]
                              : _currencies.map((currency) {
                                final isInactive =
                                    currency['status'] == 'inactive';
                                final settings = Provider.of<AppSettings>(
                                  context,
                                  listen: false,
                                );
                                final isFavorite = settings.isFavoriteCurrency(
                                  currency['code'] as String,
                                );

                                return DropdownMenuItem(
                                  value: currency['code'] as String,
                                  child: Row(
                                    children: [
                                      Text(
                                        '${currency['flag'] ?? ''} ${currency['code']}${isInactive ? ' (BLOCKED)' : ''}',
                                        style: TextStyle(
                                          color:
                                              isInactive ? Colors.grey : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (isFavorite) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.star,
                                          size: 14,
                                          color: Colors.amber,
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
                      decoration: const InputDecoration(
                        labelText: 'To Currency',
                        hintText: 'Select currency',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items:
                          _isLoadingCurrencies
                              ? [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Loading...'),
                                ),
                              ]
                              : _currencies.map((currency) {
                                final isInactive =
                                    currency['status'] == 'inactive';
                                final settings = Provider.of<AppSettings>(
                                  context,
                                  listen: false,
                                );
                                final isFavorite = settings.isFavoriteCurrency(
                                  currency['code'] as String,
                                );

                                return DropdownMenuItem(
                                  value: currency['code'] as String,
                                  child: Row(
                                    children: [
                                      Text(
                                        '${currency['flag'] ?? ''} ${currency['code']}${isInactive ? ' (BLOCKED)' : ''}',
                                        style: TextStyle(
                                          color:
                                              isInactive ? Colors.grey : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (isFavorite) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.star,
                                          size: 14,
                                          color: Colors.amber,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      hintText: '1.00',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final amount = double.tryParse(value);
                      if (amount != null && amount >= 1 && amount <= 10000) {
                        setState(() {
                          _sliderAmount = amount;
                        });
                      }
                    },
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
                  const SizedBox(height: 12),
                  Text(
                    'Adjust Amount: ${_sliderAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Slider(
                    value: _sliderAmount,
                    min: 1.0,
                    max: 10000.0,
                    divisions: 9999,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (value) {
                      setState(() {
                        _sliderAmount = value;
                        _amountController.text = value.toStringAsFixed(2);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedFrequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'daily', child: Text('Daily')),
                        DropdownMenuItem(
                          value: 'weekly',
                          child: Text('Weekly'),
                        ),
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
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        child: Text(_selectedTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(fontSize: 16)),
        ),
        ElevatedButton.icon(
          onPressed: _createTask,
          icon: const Icon(Icons.schedule, size: 18),
          label: const Text(
            'Create Task',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final task = Task(
        id: '',
        userId: '',
        userName: '',
        userEmail: '',
        userPhotoUrl: null,
        taskName: _taskNameController.text.trim(),
        fromCurrency: _selectedFromCurrency!,
        toCurrency: _selectedToCurrency!,
        amount: double.parse(_amountController.text),
        frequency: _selectedFrequency,
        time: _selectedTime,
        isActive: true,
        createdAt: DateTime.now(),
        lastExecuted: null,
        nextExecution: null,
      );

      final taskId = await TaskService.createTask(task);
      final createdTask = task.copyWith(id: taskId);

      widget.onTaskCreated(createdTask);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create task: $e')));
      }
    }
  }
}

class TaskEditDialog extends StatefulWidget {
  final Task task;
  final Function(Task) onTaskUpdated;

  const TaskEditDialog({
    super.key,
    required this.task,
    required this.onTaskUpdated,
  });

  @override
  State<TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<TaskEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedFromCurrency;
  String? _selectedToCurrency;
  String _selectedFrequency = 'daily';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  List<Map<String, dynamic>> _currencies = [];
  bool _isLoadingCurrencies = true;

  @override
  void initState() {
    super.initState();
    // Initialize with existing task data
    _taskNameController.text = widget.task.taskName;
    _amountController.text = widget.task.amount.toString();
    _selectedFromCurrency = widget.task.fromCurrency;
    _selectedToCurrency = widget.task.toCurrency;
    _selectedFrequency = widget.task.frequency;
    _selectedTime = widget.task.time;
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('currencies').get();
      final currencies =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'code': data['code'] ?? '',
              'name': data['name'] ?? '',
              'flag': data['flag'] ?? '',
              'status': data['status'] ?? 'active',
            };
          }).toList();

      // Sort currencies with favorites first
      final settings = Provider.of<AppSettings>(context, listen: false);
      final favoriteCurrencies = settings.favoriteCurrencies;

      currencies.sort((a, b) {
        final aIsFavorite = favoriteCurrencies.contains(a['code']);
        final bIsFavorite = favoriteCurrencies.contains(b['code']);

        if (aIsFavorite && !bIsFavorite) return -1;
        if (!aIsFavorite && bIsFavorite) return 1;
        return 0;
      });

      setState(() {
        _currencies = currencies;
        _isLoadingCurrencies = false;
      });
    } catch (e) {
      print('Error loading currencies: $e');
      setState(() {
        _isLoadingCurrencies = false;
      });
    }
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCurrencies) {
      return const AlertDialog(
        title: Text('Edit Task'),
        content: Center(child: CircularProgressIndicator()),
      );
    }

    return AlertDialog(
      title: const Text('Edit Task'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _taskNameController,
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                  hintText: 'e.g., Daily USD to PKR',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
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
                        hintText: 'Select currency',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items:
                          _currencies.map((currency) {
                            final isInactive = currency['status'] == 'inactive';
                            final settings = Provider.of<AppSettings>(
                              context,
                              listen: false,
                            );
                            final isFavorite = settings.isFavoriteCurrency(
                              currency['code'] as String,
                            );

                            return DropdownMenuItem<String>(
                              value: currency['code'] as String,
                              child: Row(
                                children: [
                                  Text(
                                    '${currency['flag'] ?? ''} ${currency['code']}${isInactive ? ' (BLOCKED)' : ''}',
                                    style: TextStyle(
                                      color: isInactive ? Colors.grey : null,
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
                      decoration: const InputDecoration(
                        labelText: 'To Currency',
                        hintText: 'Select currency',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items:
                          _currencies.map((currency) {
                            final isInactive = currency['status'] == 'inactive';
                            final settings = Provider.of<AppSettings>(
                              context,
                              listen: false,
                            );
                            final isFavorite = settings.isFavoriteCurrency(
                              currency['code'] as String,
                            );

                            return DropdownMenuItem<String>(
                              value: currency['code'] as String,
                              child: Row(
                                children: [
                                  Text(
                                    '${currency['flag'] ?? ''} ${currency['code']}${isInactive ? ' (BLOCKED)' : ''}',
                                    style: TextStyle(
                                      color: isInactive ? Colors.grey : null,
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
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Enter amount to convert',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
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
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'daily', child: Text('Daily')),
                        DropdownMenuItem(
                          value: 'weekly',
                          child: Text('Weekly'),
                        ),
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
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        child: Text(_selectedTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(fontSize: 16)),
        ),
        ElevatedButton.icon(
          onPressed: _updateTask,
          icon: const Icon(Icons.save, size: 18),
          label: const Text(
            'Update Task',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final updatedTask = widget.task.copyWith(
        taskName: _taskNameController.text.trim(),
        fromCurrency: _selectedFromCurrency!,
        toCurrency: _selectedToCurrency!,
        amount: double.parse(_amountController.text),
        frequency: _selectedFrequency,
        time: _selectedTime,
      );

      await TaskService.updateTask(updatedTask);
      await NotificationManager.scheduleTaskNotification(updatedTask);

      widget.onTaskUpdated(updatedTask);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update task: $e')));
      }
    }
  }
}

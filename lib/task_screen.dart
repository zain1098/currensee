import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/task_model.dart';
import 'services/task_service.dart';
import 'services/notification_manager.dart';
import 'main.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with TickerProviderStateMixin {
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
      appBar: AppBar(
        title: const Text('Currency Tasks'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.onPrimary,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Active Tasks', icon: Icon(Icons.task_alt)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildActiveTasksTab(), _buildHistoryTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTaskDialog,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 8,
        icon: const Icon(Icons.schedule, size: 24),
        label: const Text(
          'New Task',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${task.frequencyDisplay} at ${task.timeDisplay}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: task.isActive,
                  onChanged: (value) => _toggleTaskStatus(task, value),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editTask(task),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteTask(task),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
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

  void _editTask(Task task) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Task'),
            content: Text(
              'Edit dialog for "${task.displayName}" will be implemented in the next update.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
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

  Future<void> _toggleTaskStatus(Task task, bool isActive) async {
    try {
      setState(() => _isLoading = true);
      final updatedTask = task.copyWith(isActive: isActive);
      await TaskService.updateTask(updatedTask);

      if (isActive) {
        await NotificationManager.scheduleTaskNotification(task);
      } else {
        await NotificationManager.cancelTaskNotification(task);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task ${isActive ? 'activated' : 'deactivated'}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating task: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
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

  List<Map<String, dynamic>> _currencies = [];
  bool _isLoadingCurrencies = true;

  @override
  void initState() {
    super.initState();
    _amountController.text = '1.00';
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
                                final settings = Provider.of<AppSettings>(context, listen: false);
                                final isFavorite = settings.isFavoriteCurrency(currency['code'] as String);
                                
                                return DropdownMenuItem(
                                  value: currency['code'] as String,
                                  child: Row(
                                    children: [
                                      Text(
                                        '${currency['flag'] ?? ''} ${currency['code']}${isInactive ? ' (BLOCKED)' : ''}',
                                        style: TextStyle(
                                          color: isInactive ? Colors.grey : null,
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
                                final settings = Provider.of<AppSettings>(context, listen: false);
                                final isFavorite = settings.isFavoriteCurrency(currency['code'] as String);
                                
                                return DropdownMenuItem(
                                  value: currency['code'] as String,
                                  child: Row(
                                    children: [
                                      Text(
                                        '${currency['flag'] ?? ''} ${currency['code']}${isInactive ? ' (BLOCKED)' : ''}',
                                        style: TextStyle(
                                          color: isInactive ? Colors.grey : null,
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
           child: const Text(
             'Cancel',
             style: TextStyle(fontSize: 16),
           ),
         ),
         ElevatedButton.icon(
           onPressed: _createTask,
           icon: const Icon(Icons.schedule, size: 18),
           label: const Text(
             'Create Task',
             style: TextStyle(
               fontSize: 16,
               fontWeight: FontWeight.w600,
             ),
           ),
           style: ElevatedButton.styleFrom(
             padding: const EdgeInsets.symmetric(
               horizontal: 20,
               vertical: 10,
             ),
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

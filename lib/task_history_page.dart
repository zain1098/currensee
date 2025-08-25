import 'package:flutter/material.dart';
import 'services/task_service.dart';

class TaskHistoryPage extends StatefulWidget {
  const TaskHistoryPage({super.key});

  @override
  State<TaskHistoryPage> createState() => _TaskHistoryPageState();
}

class _TaskHistoryPageState extends State<TaskHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task History'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _showClearHistoryDialog,
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: StreamBuilder<List<TaskHistory>>(
        stream: TaskService.getUserTaskHistory(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading task history',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = snapshot.data!;

          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No Task History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Your task history will appear here'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return _buildHistoryCard(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(TaskHistory item) {
    final isCompleted = item.action == 'completed';
    final isDeleted = item.action == 'deleted';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.delete,
                  color: isCompleted ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.taskName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCompleted ? 'Completed' : 'Deleted',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isCompleted ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${item.amount} ${item.fromCurrency} → ${item.toCurrency}',
              style: const TextStyle(fontSize: 14),
            ),
            if (isCompleted && item.convertedAmount != null && item.rate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Result: ${item.convertedAmount!.toStringAsFixed(2)} ${item.toCurrency} (Rate: ${item.rate!.toStringAsFixed(4)})',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (isDeleted && item.reason != null) ...[
              const SizedBox(height: 4),
              Text(
                'Reason: ${item.reason}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDate(item.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.clear_all, color: Colors.red),
              SizedBox(width: 8),
              Text('Clear Task History'),
            ],
          ),
          content: const Text(
            'Are you sure you want to clear all task history? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _clearTaskHistory();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear History'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearTaskHistory() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Clearing task history...'),
              ],
            ),
          );
        },
      );

      await TaskService.clearTaskHistory();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task history cleared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear task history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rent_ease/features/delivery/presentation/bloc/delivery_bloc.dart';

class DriverPerformanceCard extends StatefulWidget {
  final String driverId;

  const DriverPerformanceCard({
    super.key,
    required this.driverId,
  });

  @override
  State<DriverPerformanceCard> createState() => _DriverPerformanceCardState();
}

class _DriverPerformanceCardState extends State<DriverPerformanceCard> {
  Map<String, dynamic>? metrics;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  void _loadMetrics() {
    context.read<DeliveryBloc>().add(LoadDriverMetrics(widget.driverId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeliveryBloc, DeliveryState>(
      listener: (context, state) {
        if (state is DriverMetricsLoaded) {
          setState(() {
            metrics = state.metrics;
          });
        }
      },
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Performance Metrics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadMetrics,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (metrics == null)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else ...[
                // Rating and Performance Score Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Rating',
                        '${(metrics!['average_rating'] ?? 0.0).toStringAsFixed(1)} ⭐',
                        _getRatingColor(metrics!['average_rating'] ?? 0.0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Priority Score',
                        '${metrics!['priority_score'] ?? 100}',
                        _getScoreColor(metrics!['priority_score'] ?? 100),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Deliveries and Earnings Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Total Deliveries',
                        '${metrics!['total_deliveries'] ?? 0}',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Total Earnings',
                        '\$${(metrics!['total_earnings'] ?? 0.0).toStringAsFixed(2)}',
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Active Deliveries and Multiplier Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Active Deliveries',
                        '${metrics!['active_delivery_count'] ?? 0}',
                        (metrics!['active_delivery_count'] ?? 0) > 0
                            ? Colors.orange
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Priority Multiplier',
                        '${(metrics!['job_priority_multiplier'] ?? 1.0).toStringAsFixed(1)}x',
                        _getMultiplierColor(
                            metrics!['job_priority_multiplier'] ?? 1.0),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Performance Tips
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.blue, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Performance Tips',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getPerformanceTip(metrics!),
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.8) return Colors.green;
    if (rating >= 4.0) return Colors.blue;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  Color _getScoreColor(int score) {
    if (score >= 120) return Colors.green;
    if (score >= 100) return Colors.blue;
    return Colors.orange;
  }

  Color _getMultiplierColor(double multiplier) {
    if (multiplier > 1.0) return Colors.green;
    if (multiplier == 1.0) return Colors.blue;
    return Colors.orange;
  }

  String _getPerformanceTip(Map<String, dynamic> metrics) {
    final rating = metrics['average_rating'] ?? 0.0;
    final score = metrics['priority_score'] ?? 100;
    final activeCount = metrics['active_delivery_count'] ?? 0;

    if (score >= 120) {
      return '🌟 Excellent! You\'re a premium driver. Keep maintaining high ratings and efficient deliveries.';
    } else if (rating < 4.0) {
      return '📈 Focus on improving customer service to boost your rating above 4.0 for better job opportunities.';
    } else if (activeCount > 2) {
      return '⚡ Complete some active deliveries to improve your priority score and get more jobs.';
    } else if (rating < 4.8) {
      return '⭐ Great work! Aim for 4.8+ rating to become a premium driver with priority jobs and bonuses.';
    } else {
      return '🎯 You\'re doing well! Keep up the consistent performance to maintain your high score.';
    }
  }
}

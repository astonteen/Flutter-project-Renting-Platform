import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/utils/navigation_helper.dart';
import 'package:rent_ease/features/home/presentation/bloc/lender_bloc.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:rent_ease/shared/widgets/error_widget.dart';
import 'package:fl_chart/fl_chart.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - 11, 1); // Last 12 months
    final endDate =
        DateTime(now.year, now.month + 1, 0); // End of current month
    context.read<LenderBloc>().add(LoadEarningsData(
          startDate: startDate,
          endDate: endDate,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: NavigationHelper.createHamburgerMenuBackButton(context),
        actions: const [], // Removed refresh button
      ),
      body: BlocBuilder<LenderBloc, LenderState>(
        builder: (context, state) {
          if (state is LenderLoading) {
            return const LoadingWidget();
          }

          if (state is LenderError) {
            return CustomErrorWidget(
              message: state.message,
              onRetry: () {
                final now = DateTime.now();
                final startDate = DateTime(now.year, now.month - 11, 1);
                final endDate = DateTime(now.year, now.month + 1, 0);
                context.read<LenderBloc>().add(LoadEarningsData(
                      startDate: startDate,
                      endDate: endDate,
                    ));
              },
            );
          }

          if (state is EarningsDataLoaded) {
            // Convert earnings data list to a summary map
            final earningsMap = _convertEarningsDataToMap(state.earningsData);
            return _buildEarningsContent(earningsMap);
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildEarningsContent(Map<String, dynamic> earningsData) {
    final totalEarnings = earningsData['total_earnings'] ?? 0.0;
    final monthlyEarnings = earningsData['monthly_earnings'] ?? 0.0;
    final weeklyData =
        earningsData['weekly_data'] as List<Map<String, dynamic>>? ?? [];
    final monthlyData =
        earningsData['monthly_data'] as List<Map<String, dynamic>>? ?? [];

    return RefreshIndicator(
      onRefresh: () async {
        final now = DateTime.now();
        final startDate = DateTime(now.year, now.month - 11, 1);
        final endDate = DateTime(now.year, now.month + 1, 0);
        context.read<LenderBloc>().add(LoadEarningsData(
              startDate: startDate,
              endDate: endDate,
            ));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEarningsSummary(totalEarnings, monthlyEarnings),
            const SizedBox(height: 24),
            _buildWeeklyChart(weeklyData),
            const SizedBox(height: 24),
            _buildMonthlyChart(monthlyData),
            const SizedBox(height: 24),
            _buildEarningsBreakdown(earningsData),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsSummary(double totalEarnings, double monthlyEarnings) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Earnings',
            '\$${totalEarnings.toStringAsFixed(2)}',
            Icons.account_balance_wallet,
            ColorConstants.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'This Month',
            '\$${monthlyEarnings.toStringAsFixed(2)}',
            Icons.calendar_month,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(List<Map<String, dynamic>> weeklyData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Earnings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: weeklyData.isEmpty
                ? const Center(
                    child: Text(
                      'No earnings data available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '\$${value.toInt()}',
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final days = [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun'
                              ];
                              if (value.toInt() < days.length) {
                                return Text(
                                  days[value.toInt()],
                                  style: const TextStyle(fontSize: 12),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: weeklyData.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              (entry.value['amount'] as num).toDouble(),
                            );
                          }).toList(),
                          isCurved: true,
                          color: ColorConstants.primaryColor,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(List<Map<String, dynamic>> monthlyData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Earnings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: monthlyData.isEmpty
                ? const Center(
                    child: Text(
                      'No monthly data available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '\$${value.toInt()}',
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final months = [
                                'Jan',
                                'Feb',
                                'Mar',
                                'Apr',
                                'May',
                                'Jun'
                              ];
                              if (value.toInt() < months.length) {
                                return Text(
                                  months[value.toInt()],
                                  style: const TextStyle(fontSize: 12),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      barGroups: monthlyData.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: (entry.value['amount'] as num).toDouble(),
                              color: ColorConstants.primaryColor,
                              width: 20,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsBreakdown(Map<String, dynamic> earningsData) {
    final pendingEarnings = earningsData['pending_earnings'] ?? 0.0;
    final completedEarnings = earningsData['completed_earnings'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Earnings Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildBreakdownItem(
            'Completed Rentals',
            '\$${completedEarnings.toStringAsFixed(2)}',
            Colors.green,
            Icons.check_circle,
          ),
          const SizedBox(height: 12),
          _buildBreakdownItem(
            'Pending Payments',
            '\$${pendingEarnings.toStringAsFixed(2)}',
            Colors.orange,
            Icons.pending,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(
      String title, String amount, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: ColorConstants.primaryColor,
            ),
            SizedBox(height: 24),
            Text(
              'No Earnings Data',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Start renting out your items to see your earnings here.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _convertEarningsDataToMap(
      List<Map<String, dynamic>> earningsData) {
    // Calculate totals from the earnings data list
    double totalEarnings = 0.0;
    double monthlyEarnings = 0.0;
    double pendingEarnings = 0.0;
    double completedEarnings = 0.0;

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Generate sample weekly and monthly data for charts
    final weeklyData = List.generate(
        7,
        (index) => {
              'day': index,
              'amount': (index + 1) * 50.0 + (index * 10), // Sample data
            });

    final monthlyData = List.generate(
        6,
        (index) => {
              'month': index,
              'amount': (index + 1) * 200.0 + (index * 50), // Sample data
            });

    // Process actual earnings data if available
    for (final earning in earningsData) {
      final amount = (earning['amount'] as num?)?.toDouble() ?? 0.0;
      final status = earning['status'] as String? ?? '';
      final date = earning['date'] as String?;

      totalEarnings += amount;

      if (status == 'completed') {
        completedEarnings += amount;
      } else {
        pendingEarnings += amount;
      }

      // Check if earning is from current month
      if (date != null) {
        try {
          final earningDate = DateTime.parse(date);
          if (earningDate.month == currentMonth &&
              earningDate.year == currentYear) {
            monthlyEarnings += amount;
          }
        } catch (e) {
          // Handle date parsing error
        }
      }
    }

    return {
      'total_earnings': totalEarnings,
      'monthly_earnings': monthlyEarnings,
      'pending_earnings': pendingEarnings,
      'completed_earnings': completedEarnings,
      'weekly_data': weeklyData,
      'monthly_data': monthlyData,
    };
  }
}

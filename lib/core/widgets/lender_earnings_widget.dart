import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/color_constants.dart';

enum EarningsPeriod { today, week, month }

class LenderEarningsWidget extends StatefulWidget {
  final Map<EarningsPeriod, double> earnings;
  final List<double> weeklySparklineData;
  final VoidCallback? onWithdraw;

  const LenderEarningsWidget({
    super.key,
    required this.earnings,
    required this.weeklySparklineData,
    this.onWithdraw,
  });

  @override
  State<LenderEarningsWidget> createState() => _LenderEarningsWidgetState();
}

class _LenderEarningsWidgetState extends State<LenderEarningsWidget>
    with SingleTickerProviderStateMixin {
  EarningsPeriod _selectedPeriod = EarningsPeriod.week;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ColorConstants.primaryColor,
              ColorConstants.primaryColor.withAlpha(200),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildEarningsDisplay(),
              const SizedBox(height: 16),
              _buildSparkline(),
              const SizedBox(height: 16),
              _buildPeriodToggle(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings',
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _getPeriodLabel(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (widget.onWithdraw != null)
          OutlinedButton(
            onPressed: widget.onWithdraw,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet, size: 16),
                SizedBox(width: 6),
                Text('Withdraw', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEarningsDisplay() {
    final currentEarnings = widget.earnings[_selectedPeriod] ?? 0.0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${currentEarnings.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    currentEarnings >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    _getChangePercentage(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSparkline() {
    if (widget.weeklySparklineData.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 40,
      child: CustomPaint(
        painter: SparklinePainter(
          data: widget.weeklySparklineData,
          color: Colors.white.withAlpha(180),
        ),
        size: const Size(double.infinity, 40),
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(50),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: EarningsPeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPeriod = period;
              });
              _animationController.reset();
              _animationController.forward();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getPeriodShortLabel(period),
                style: TextStyle(
                  color: isSelected
                      ? ColorConstants.primaryColor
                      : Colors.white.withAlpha(180),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case EarningsPeriod.today:
        return 'Today';
      case EarningsPeriod.week:
        return 'This Week';
      case EarningsPeriod.month:
        return 'This Month';
    }
  }

  String _getPeriodShortLabel(EarningsPeriod period) {
    switch (period) {
      case EarningsPeriod.today:
        return 'Today';
      case EarningsPeriod.week:
        return 'Week';
      case EarningsPeriod.month:
        return 'Month';
    }
  }

  String _getChangePercentage() {
    // Mock calculation - in real app would compare with previous period
    final currentEarnings = widget.earnings[_selectedPeriod] ?? 0.0;
    final changePercent = currentEarnings > 0 ? 12.5 : 0.0;
    return '+${changePercent.toStringAsFixed(1)}%';
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    if (range == 0) return;

    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedY = (data[i] - minValue) / range;
      final y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw dots at data points
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedY = (data[i] - minValue) / range;
      final y = size.height - (normalizedY * size.height);
      canvas.drawCircle(Offset(x, y), 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';

/// 관리자 대시보드 활동 차트
///
/// fl_chart 기반 7일간 활동 추이 라인 차트
/// 가입, 게시글, 질문 3가지 데이터를 표시
class AdminActivityChart extends StatelessWidget {
  const AdminActivityChart({super.key, required this.data});

  /// 차트 데이터 리스트
  /// 각 항목은 {'date': 'YYYY-MM-DD', 'users': int, 'posts': int, 'questions': int}
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    // 데이터가 없으면 빈 상태 표시
    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('데이터가 없습니다.')),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 차트 제목
            const Text(
              '최근 7일 활동',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            // 범례
            Row(
              children: [
                _LegendDot(color: AppColors.brand, label: '가입'),
                const SizedBox(width: AppSpacing.lg),
                _LegendDot(color: AppColors.success, label: '게시글'),
                const SizedBox(width: AppSpacing.lg),
                _LegendDot(color: AppColors.warning, label: '질문'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // 라인 차트
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.borderLight,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.length) {
                            return const SizedBox.shrink();
                          }
                          // 날짜에서 MM-DD 부분만 표시
                          final date = data[index]['date']?.toString() ?? '';
                          final short =
                              date.length >= 5 ? date.substring(5) : date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              short,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          // 정수값만 표시
                          if (value == value.roundToDouble()) {
                            return Text(
                              '${value.toInt()}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    _buildLine(data, 'users', AppColors.brand),
                    _buildLine(data, 'posts', AppColors.success),
                    _buildLine(data, 'questions', AppColors.warning),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppColors.backgroundSurface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 라인 차트 데이터 빌더
  LineChartBarData _buildLine(
    List<Map<String, dynamic>> data,
    String key,
    Color color,
  ) {
    return LineChartBarData(
      spots: List.generate(data.length, (i) {
        return FlSpot(
          i.toDouble(),
          (data[i][key] as num?)?.toDouble() ?? 0,
        );
      }),
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 3,
          color: AppColors.backgroundSurface,
          strokeWidth: 2,
          strokeColor: color,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }
}

/// 차트 범례 점 위젯
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
        ),
      ],
    );
  }
}

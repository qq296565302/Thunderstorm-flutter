import 'package:flutter/material.dart';

/// 动态标签页组件 - 当前为占位，未来可扩展动态内容
class DynamicTab extends StatelessWidget {
  /// 联赛名称，用于显示或未来数据请求
  final String leagueName;

  const DynamicTab({
    super.key,
    required this.leagueName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_soccer,
            size: 80,
            color: Colors.orange.withOpacity(0.7),
          ),
          const SizedBox(height: 20),
          Text(
            '$leagueName - 动态信息',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '敬请期待更多精彩内容',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
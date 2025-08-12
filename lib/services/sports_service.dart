import 'dart:convert';
import 'package:http/http.dart' as http;

/// 体育赛程数据模型
class MatchSchedule {
  final String teamAName;     // 主队名称
  final String teamALogo;     // 主队logo
  final String teamBName;     // 客队名称
  final String teamBLogo;     // 客队logo
  final String startPlay;     // 比赛开始时间
  final List<String> tvList;  // 视频转播方

  MatchSchedule({
    required this.teamAName,
    required this.teamALogo,
    required this.teamBName,
    required this.teamBLogo,
    required this.startPlay,
    required this.tvList,
  });

  /// 从JSON创建对象
  /// [json] JSON数据
  /// [leagueName] 联赛名称，用于特殊处理
  factory MatchSchedule.fromJson(Map<String, dynamic> json, {String? leagueName}) {
    // 安全处理TVList字段
    List<String> tvList = [];
    final tvListData = json['TVList'];
    if (tvListData != null) {
      if (tvListData is List) {
        tvList = tvListData.map((e) => e.toString()).toList();
      } else if (tvListData is String) {
        // 如果是字符串，尝试按逗号分割或作为单个元素
        if (tvListData.isNotEmpty) {
          tvList = tvListData.contains(',') 
              ? tvListData.split(',').map((e) => e.trim()).toList()
              : [tvListData];
        }
      }
    }
    
    // 德甲赛程特殊处理：追加咪咕视频
    if (leagueName == '德甲' && tvList.isNotEmpty) {
      // 检查是否已经包含咪咕视频，避免重复添加
      if (!tvList.any((tv) => tv.contains('咪咕视频'))) {
        tvList.add('咪咕视频');
      }
    }
    
    return MatchSchedule(
      teamAName: json['team_A_name'] ?? '',
      teamALogo: json['team_A_logo'] ?? '',
      teamBName: json['team_B_name'] ?? '',
      teamBLogo: json['team_B_logo'] ?? '',
      startPlay: json['start_play'] ?? '',
      tvList: tvList,
    );
  }
}

/// 体育赛程服务类
class SportsService {
  // 单例模式
  static final SportsService _instance = SportsService._internal();
  factory SportsService() => _instance;
  SportsService._internal();

  /// 懂球帝API基础地址
  static const String baseUrl = 'https://www.dongqiudi.com/api/data/tab/league/new';

  /// 赛事ID映射
  static const Map<String, int> leagueIds = {
    '西甲': 3,
    '英超': 4,
    '德甲': 5,
    '欧冠': 6,
    '意甲': 9,
    '欧联': 14,
    '欧协联': 3904,
  };

  /// 获取指定赛事的赛程数据
  /// [leagueName] 赛事名称（如：'英超'、'西甲'等）
  /// [start] 开始参数，默认为空字符串
  Future<List<MatchSchedule>> getLeagueSchedule(String leagueName, {String start = ''}) async {
    try {
      // 获取赛事ID
      final leagueId = leagueIds[leagueName];
      if (leagueId == null) {
        throw Exception('不支持的赛事: $leagueName');
      }

      // 构建请求URL - 新的格式为 /new/{id}
      final url = '$baseUrl/$leagueId';
      final uri = Uri.parse(url).replace(
        queryParameters: {
          'start': start,
          'init': '1',
          'platform': 'www',
        },
      );

      // 发起HTTP请求
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      // 检查响应状态
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 检查数据结构
        if (data == null) {
          throw Exception('API返回数据为空');
        }
        
        // 尝试不同的数据结构
        List<dynamic> list = [];
        if (data is Map<String, dynamic>) {
          if (data.containsKey('list')) {
            final listData = data['list'];
            if (listData is List) {
              list = listData;
            } else if (listData is String) {
              // 如果list字段是字符串，尝试解析为JSON
              try {
                list = json.decode(listData) as List<dynamic>;
              } catch (e) {
                print('解析list字段失败: $e');
                list = [];
              }
            }
          } else if (data.containsKey('data')) {
            // 尝试data字段
            final dataField = data['data'];
            if (dataField is List) {
              list = dataField;
            } else if (dataField is Map && dataField.containsKey('list')) {
              final listData = dataField['list'];
              if (listData is List) {
                list = listData;
              }
            }
          }
        } else if (data is List) {
          list = data;
        }
        
        return list.map((item) => MatchSchedule.fromJson(item, leagueName: leagueName)).toList();
      } else {
        throw Exception('请求失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('获取赛程数据失败: $e');
    }
  }

  /// 获取所有支持的赛事列表
  List<String> getSupportedLeagues() {
    return leagueIds.keys.toList();
  }

  /// 检查是否支持指定赛事
  bool isLeagueSupported(String leagueName) {
    return leagueIds.containsKey(leagueName);
  }
}
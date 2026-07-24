import 'farm_model.dart';

class AiEvaluationResult {
  final double riskScore;
  final StatusLevel overallStatus;
  final bool isAlertTriggered;
  final Map<String, StatusLevel> paramStatuses;
  final List<String> adviceList;
  final String cropName;
  final String stageName;
  final bool isOfflineFallback;

  const AiEvaluationResult({
    required this.riskScore,
    required this.overallStatus,
    required this.isAlertTriggered,
    required this.paramStatuses,
    required this.adviceList,
    this.cropName = '',
    this.stageName = '',
    this.isOfflineFallback = false,
  });

  factory AiEvaluationResult.fromMap(Map<String, dynamic> data, {bool isOffline = false}) {
    final statusStr = (data['overall_status'] ?? 'normal').toString().toLowerCase();
    StatusLevel overall;
    if (statusStr == 'danger') {
      overall = StatusLevel.danger;
    } else if (statusStr == 'warning') {
      overall = StatusLevel.warning;
    } else {
      overall = StatusLevel.normal;
    }

    final rawParams = (data['param_statuses'] as Map<String, dynamic>?) ?? {};
    final Map<String, StatusLevel> params = {};
    rawParams.forEach((k, v) {
      final s = v.toString().toLowerCase();
      if (s == 'danger') {
        params[k] = StatusLevel.danger;
      } else if (s == 'warning') {
        params[k] = StatusLevel.warning;
      } else {
        params[k] = StatusLevel.normal;
      }
    });

    final rawAdvice = (data['advice_list'] as List<dynamic>?) ?? [];
    final advice = rawAdvice.map((e) => e.toString()).toList();
    if (advice.isEmpty) {
      advice.add('Tất cả chỉ số đang nằm trong ngưỡng an toàn.');
    }

    return AiEvaluationResult(
      riskScore: (data['risk_score'] as num?)?.toDouble() ?? 0.0,
      overallStatus: overall,
      isAlertTriggered: data['is_alert_triggered'] as bool? ?? false,
      paramStatuses: params,
      adviceList: advice,
      cropName: data['crop_name']?.toString() ?? '',
      stageName: data['stage_name']?.toString() ?? '',
      isOfflineFallback: isOffline,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'risk_score': riskScore,
      'overall_status': overallStatus.name,
      'is_alert_triggered': isAlertTriggered,
      'param_statuses': paramStatuses.map((k, v) => MapEntry(k, v.name)),
      'advice_list': adviceList,
      'crop_name': cropName,
      'stage_name': stageName,
      'is_offline_fallback': isOfflineFallback,
    };
  }

  StatusLevel getParamStatus(String paramName) {
    return paramStatuses[paramName] ?? StatusLevel.normal;
  }
}

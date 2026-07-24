class GrowthStage {
  final int stageId;
  final String stageName;
  final double tempMin;
  final double tempMax;
  final double soilMoistureMin;
  final double soilMoistureMax;
  final double airHumidityMin;
  final double airHumidityMax;
  final double luxMin;
  final double luxMax;
  final String notes;

  const GrowthStage({
    required this.stageId,
    required this.stageName,
    required this.tempMin,
    required this.tempMax,
    required this.soilMoistureMin,
    required this.soilMoistureMax,
    required this.airHumidityMin,
    required this.airHumidityMax,
    required this.luxMin,
    required this.luxMax,
    this.notes = '',
  });

  factory GrowthStage.fromMap(Map<String, dynamic> data) {
    return GrowthStage(
      stageId: (data['stage_id'] as num?)?.toInt() ?? 1,
      stageName: data['stage_name']?.toString() ?? 'Sinh trưởng chung',
      tempMin: (data['temp_min'] as num?)?.toDouble() ?? 24.0,
      tempMax: (data['temp_max'] as num?)?.toDouble() ?? 30.0,
      soilMoistureMin: (data['soil_moisture_min'] as num?)?.toDouble() ?? 60.0,
      soilMoistureMax: (data['soil_moisture_max'] as num?)?.toDouble() ?? 80.0,
      airHumidityMin: (data['air_humidity_min'] as num?)?.toDouble() ?? 70.0,
      airHumidityMax: (data['air_humidity_max'] as num?)?.toDouble() ?? 85.0,
      luxMin: (data['lux_min'] as num?)?.toDouble() ?? 50000.0,
      luxMax: (data['lux_max'] as num?)?.toDouble() ?? 80000.0,
      notes: data['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stage_id': stageId,
      'stage_name': stageName,
      'temp_min': tempMin,
      'temp_max': tempMax,
      'soil_moisture_min': soilMoistureMin,
      'soil_moisture_max': soilMoistureMax,
      'air_humidity_min': airHumidityMin,
      'air_humidity_max': airHumidityMax,
      'lux_min': luxMin,
      'lux_max': luxMax,
      'notes': notes,
    };
  }
}

class CropModel {
  final String cropId;
  final String cropName;
  final double soilPhMin;
  final double soilPhMax;
  final List<GrowthStage> growthStages;

  const CropModel({
    required this.cropId,
    required this.cropName,
    required this.soilPhMin,
    required this.soilPhMax,
    required this.growthStages,
  });

  factory CropModel.fromMap(Map<String, dynamic> data) {
    final stagesList = (data['growth_stages'] as List<dynamic>?) ?? [];
    return CropModel(
      cropId: data['crop_id']?.toString() ?? 'default',
      cropName: data['crop_name']?.toString() ?? 'Mặc định',
      soilPhMin: (data['soil_ph_min'] as num?)?.toDouble() ?? 5.5,
      soilPhMax: (data['soil_ph_max'] as num?)?.toDouble() ?? 6.5,
      growthStages: stagesList
          .map((s) => GrowthStage.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'crop_id': cropId,
      'crop_name': cropName,
      'soil_ph_min': soilPhMin,
      'soil_ph_max': soilPhMax,
      'growth_stages': growthStages.map((s) => s.toMap()).toList(),
    };
  }

  GrowthStage getStageById(int stageId) {
    return growthStages.firstWhere(
      (s) => s.stageId == stageId,
      orElse: () => growthStages.isNotEmpty ? growthStages.first : const GrowthStage(
        stageId: 1,
        stageName: 'Mặc định',
        tempMin: 24,
        tempMax: 30,
        soilMoistureMin: 60,
        soilMoistureMax: 80,
        airHumidityMin: 70,
        airHumidityMax: 85,
        luxMin: 50000,
        luxMax: 80000,
      ),
    );
  }
}

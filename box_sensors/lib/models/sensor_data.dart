class SensorData {
  final String device;
  final String punchBy;
  final String punchCount;
  final String timestamp;
  final String sensorValue;

  const SensorData({
    required this.device,
    required this.punchBy,
    required this.punchCount,
    required this.timestamp,
    required this.sensorValue,
  });

  /// Factory to create SensorData from the raw map (database/parsing)
  factory SensorData.fromMap(Map<String, dynamic> map) {
    return SensorData(
      device: map['device']?.toString() ?? '',
      punchBy: map['punchBy']?.toString() ?? '',
      punchCount: map['punchCount']?.toString() ?? '',
      timestamp: map['timestamp']?.toString() ?? '',
      sensorValue: map['sensorValue']?.toString() ?? '',
    );
  }

  /// Convert to map (if needed for reverse operations or debugging)
  Map<String, dynamic> toMap() {
    return {
      'device': device,
      'punchBy': punchBy,
      'punchCount': punchCount,
      'timestamp': timestamp,
      'sensorValue': sensorValue,
    };
  }
}

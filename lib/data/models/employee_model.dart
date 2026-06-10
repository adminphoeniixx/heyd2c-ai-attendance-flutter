class EmployeeModel {
  final int id;
  final String employeeId;
  final String name;
  final String designation;
  final String department;
  final bool hasFace;
  final String faceEncoding; // comma-separated floats from API / TFLite

  const EmployeeModel({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.designation,
    required this.department,
    required this.hasFace,
    required this.faceEncoding,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> j) => EmployeeModel(
        id: (j['id'] as num).toInt(),
        employeeId: j['employee_id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        designation: j['designation']?.toString() ?? '',
        department: j['department']?.toString() ?? '',
        hasFace: _asBool(j['has_face']),
        faceEncoding: _normalizeFaceEncoding(j['face_encoding']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee_id': employeeId,
        'name': name,
        'designation': designation,
        'department': department,
        'has_face': hasFace,
        'face_encoding': faceEncoding,
      };

  /// Parses faceEncoding string into a float vector for cosine comparison
  List<double> get embeddingVector {
    if (faceEncoding.isEmpty) return [];
    return faceEncoding
        .split(',')
        .map((s) => double.tryParse(s.trim()))
        .whereType<double>()
        .toList();
  }

  EmployeeModel copyWith({bool? hasFace, String? faceEncoding}) =>
      EmployeeModel(
        id: id,
        employeeId: employeeId,
        name: name,
        designation: designation,
        department: department,
        hasFace: hasFace ?? this.hasFace,
        faceEncoding: faceEncoding ?? this.faceEncoding,
      );

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  /// Normalises the face_encoding field from any server format to a plain
  /// comma-separated float string ("0.1,0.2,...") that embeddingVector can parse.
  ///
  /// Server may return:
  ///   • null / empty → ""
  ///   • List<dynamic>  [0.1, 0.2, …]  → "0.1,0.2,…"
  ///   • String JSON array "[0.1, 0.2, …]" → "0.1,0.2,…"
  ///   • String comma-sep  "0.1,0.2,…"  → as-is
  static String _normalizeFaceEncoding(Object? raw) {
    if (raw == null) return '';
    if (raw is List) {
      return raw.map((e) => e.toString()).join(',');
    }
    var s = raw.toString().trim();
    if (s.startsWith('[') && s.endsWith(']')) {
      s = s.substring(1, s.length - 1).trim();
    }
    return s;
  }
}

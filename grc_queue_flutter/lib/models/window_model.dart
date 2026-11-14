// lib/models/window_model.dart

class WindowModel {
  final int     windowId;
  final String  windowName;
  final String  serviceType;
  final bool    isOpen;
  final String? staffName;

  const WindowModel({
    required this.windowId,
    required this.windowName,
    required this.serviceType,
    required this.isOpen,
    this.staffName,
  });

  factory WindowModel.fromJson(Map<String, dynamic> j) {
    return WindowModel(
      windowId:    j['window_id']    as int,
      windowName:  j['window_name']  as String,
      serviceType: j['service_type'] as String,
      isOpen:      (j['is_open'] == 1 || j['is_open'] == true),
      staffName:   j['staff_name'] as String?,
    );
  }
}

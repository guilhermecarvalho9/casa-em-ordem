class PermissionsModel {
  final Map<String, List<String>> _map;

  const PermissionsModel._(this._map);

  static const Map<String, List<String>> defaults = {
    'tasks.add':       ['admin', 'owner', 'member'],
    'tasks.complete':  ['admin', 'owner', 'member', 'guest'],
    'tasks.delete':    ['admin', 'owner'],
    'bills.add':       ['admin', 'owner'],
    'bills.markPaid':  ['admin', 'owner', 'member'],
    'bills.delete':    ['admin', 'owner'],
    'events.add':      ['admin', 'owner', 'member'],
    'events.edit':     ['admin', 'owner', 'member'],
    'events.delete':   ['admin', 'owner'],
    'inventory.add':   ['admin', 'owner', 'member'],
    'inventory.edit':  ['admin', 'owner', 'member'],
    'inventory.delete':['admin', 'owner'],
    'shopping.add':    ['admin', 'owner', 'member', 'guest'],
    'shopping.delete': ['admin', 'owner', 'member'],
    'rules.add':       ['admin', 'owner'],
    'rules.delete':    ['admin', 'owner'],
    'damaged.add':     ['admin', 'owner', 'member'],
    'damaged.delete':  ['admin', 'owner'],
  };

  factory PermissionsModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return PermissionsModel._(defaults);
    final merged = Map<String, List<String>>.from(defaults);
    map.forEach((key, value) {
      if (value is List) merged[key] = List<String>.from(value);
    });
    return PermissionsModel._(merged);
  }

  bool can(String action, String role) {
    if (role == 'admin') return true;
    return (_map[action] ?? defaults[action] ?? ['admin']).contains(role);
  }

  List<String> rolesFor(String action) =>
      List<String>.from(_map[action] ?? defaults[action] ?? ['admin']);

  PermissionsModel withAction(String action, List<String> roles) {
    final updated = Map<String, List<String>>.from(_map)..[action] = roles;
    return PermissionsModel._(updated);
  }

  Map<String, dynamic> toMap() =>
      _map.map((k, v) => MapEntry(k, List<String>.from(v)));
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/auth_scope.dart';
import '../../data/healthreach_api.dart';
import '../../widgets/app_select.dart';

class AdminInventoryPage extends StatefulWidget {
  const AdminInventoryPage({super.key});

  @override
  State<AdminInventoryPage> createState() => _AdminInventoryPageState();
}

class _AdminInventoryPageState extends State<AdminInventoryPage> {
  static const String stockAll = 'all';
  static const String stockIn = 'in_stock';
  static const String stockLow = 'low_stock';
  static const String stockOut = 'out_of_stock';
  static const String stockExpiring = 'expiring_soon';

  final _api = HealthReachApi();
  final _searchController = TextEditingController();

  Timer? _debounce;
  int _token = 0;

  bool _loading = true;
  bool _querying = false;
  bool _saving = false;
  bool _resolvedRole = false;
  bool _isAdmin = false;

  String _category = 'all';
  String _stock = stockAll;
  String? _error;

  Map<String, dynamic> _stats = const {};
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolvedRole) return;
    _resolvedRole = true;
    final role = AuthScope.of(context).user?.role.toLowerCase().trim() ?? '';
    _isAdmin = role == 'admin';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController
      ..removeListener(_onSearch)
      ..dispose();
    super.dispose();
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _load(showLoader: false);
    });
  }

  Future<void> _load({bool showLoader = true}) async {
    final current = ++_token;
    setState(() {
      if (showLoader) {
        _loading = true;
      } else {
        _querying = true;
      }
      _error = null;
    });

    final search = _searchController.text.trim();

    try {
      final statsFuture = _api.getInventoryStats();
      final itemsFuture = _api.getInventory(
        category: _category == 'all' ? null : _category,
        lowStock: _stock == stockLow ? true : null,
        expiringSoon: _stock == stockExpiring ? true : null,
        search: search.isEmpty ? null : search,
      );

      final results = await Future.wait<dynamic>([statsFuture, itemsFuture]);
      var items = _toList(results[1]);
      if (_stock == stockOut) {
        items = items.where((item) => _qty(item) <= 0).toList();
      }
      if (_stock == stockIn) {
        items = items.where((item) => _qty(item) > 0).toList();
      }

      if (!mounted || current != _token) return;
      setState(() {
        _stats = _toMap(results[0]);
        _items = items;
        _loading = false;
        _querying = false;
      });
    } catch (error) {
      if (!mounted || current != _token) return;
      setState(() {
        _error = _err(error);
        _loading = false;
        _querying = false;
      });
    }
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final id = item == null ? '' : _id(item);
    Map<String, dynamic>? initial = item;
    if (id.isNotEmpty) {
      try {
        final latest = await _api.getInventoryItem(id);
        if (latest.isNotEmpty) initial = latest;
      } catch (_) {}
    }

    if (!mounted) return;
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MedicationDialog(
        initial: initial,
        categories: _categories(),
      ),
    );
    if (payload == null) return;

    setState(() => _saving = true);
    try {
      if (id.isEmpty) {
        await _api.createInventory(payload);
      } else {
        await _api.updateInventory(id, payload);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(id.isEmpty ? 'Medication added.' : 'Medication updated.')),
      );
      await _load(showLoader: false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_err(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openAdjust(Map<String, dynamic> item,
      {required bool stockInFlow}) async {
    final id = _id(item);
    if (id.isEmpty) return;

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AdjustDialog(stockIn: stockInFlow, item: item),
    );
    if (payload == null) return;

    setState(() => _saving = true);
    try {
      await _api.adjustInventory(id, payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock adjusted.')),
      );
      await _load(showLoader: false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_err(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openTransactions(Map<String, dynamic> item) async {
    final id = _id(item);
    if (id.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (context) => _TransactionsDialog(
        api: _api,
        inventoryId: id,
        name: _name(item),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    if (!_isAdmin) return;
    final id = _id(item);
    if (id.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Delete "${_name(item)}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _saving = true);
    try {
      await _api.deleteInventory(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Deleted.')));
      await _load(showLoader: false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_err(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          final table = constraints.maxWidth >= 1080;
          final pad = constraints.maxWidth < 640 ? 12.0 : 24.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
            children: [
              if (compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(context),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _openForm,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Medication'),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: _header(context)),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _openForm,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Medication'),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              if (_loading)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator()))
              else ...[
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      border: Border.all(color: const Color(0xFFFBCFE8)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_error!,
                        style: const TextStyle(color: Color(0xFFE06C75))),
                  ),
                _statsSection(),
                const SizedBox(height: 16),
                _listCard(tableView: table),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.inventory_2_outlined, color: AppTheme.deepBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Medication Inventory',
                  style: Theme.of(context).textTheme.titleLarge),
              Text(
                'Manage clinic medication stock and supplies',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statsSection() {
    final cards = [
      _StatCard(
        icon: Icons.inventory_2_outlined,
        label: 'Total Items',
        value: _read(_stats, const ['totalItems']),
        color: const Color(0xFF3B82F6),
      ),
      _StatCard(
        icon: Icons.trending_down_rounded,
        label: 'Low Stock',
        value: _read(_stats, const ['lowStock']),
        color: const Color(0xFFEAB308),
      ),
      _StatCard(
        icon: Icons.warning_amber_rounded,
        label: 'Out of Stock',
        value: _read(_stats, const ['outOfStock']),
        color: const Color(0xFFEF4444),
      ),
      _StatCard(
        icon: Icons.schedule_rounded,
        label: 'Expiring Soon',
        value: _read(_stats, const ['expiringSoon']),
        color: const Color(0xFFF97316),
      ),
      _StatCard(
        icon: Icons.event_busy_outlined,
        label: 'Expired',
        value: _read(_stats, const ['expired']),
        color: const Color(0xFF6B7280),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = width >= 1300
            ? 5
            : width >= 960
                ? 3
                : width >= 620
                    ? 2
                    : 1;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: width < 640 ? 3.2 : 2.7,
          children: cards,
        );
      },
    );
  }

  Widget _listCard({required bool tableView}) {
    final categories = _categories();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compactFilters = constraints.maxWidth < 1060;
              final controls = [
                SizedBox(
                  width: compactFilters ? double.infinity : 220,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search medications...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                SizedBox(
                  width: compactFilters ? double.infinity : 170,
                  child: AppDropdownFormField<String>(
                    value: _category,
                    items: categories
                        .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(
                                  v == 'all' ? 'All Categories' : _human(v)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _category = v);
                      _load(showLoader: false);
                    },
                  ),
                ),
                SizedBox(
                  width: compactFilters ? double.infinity : 150,
                  child: AppDropdownFormField<String>(
                    value: _stock,
                    items: stockOptions.entries
                        .map((e) => DropdownMenuItem(
                            value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _stock = v);
                      _load(showLoader: false);
                    },
                  ),
                ),
              ];

              if (compactFilters) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inventory List',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    ...controls.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: c,
                        )),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Text('Inventory List',
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  ...controls.expand((c) => [c, const SizedBox(width: 8)]),
                ]..removeLast(),
              );
            },
          ),
          const SizedBox(height: 12),
          if (_querying)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          if (_items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 42, color: AppTheme.textMuted),
                  const SizedBox(height: 8),
                  const Text('No medications in inventory'),
                  const SizedBox(height: 2),
                  Text(
                    'Try changing filters or add a new medication.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ),
            )
          else if (tableView)
            _InventoryTableView(
              items: _items,
              isAdmin: _isAdmin,
              saving: _saving,
              onStockIn: (row) => _openAdjust(row, stockInFlow: true),
              onStockOut: (row) => _openAdjust(row, stockInFlow: false),
              onEdit: (row) => _openForm(item: row),
              onLogs: _openTransactions,
              onDelete: _delete,
              getName: _name,
              getGeneric: _generic,
              getCategory: _itemCategory,
              getStrength: _strength,
              getUnit: _unit,
              getQty: _qty,
              getStatus: _status,
              getExpiry: _expiry,
            )
          else
            Column(
              children: _items
                  .map((row) => _InventoryMobileTile(
                        row: row,
                        isAdmin: _isAdmin,
                        saving: _saving,
                        onStockIn: () => _openAdjust(row, stockInFlow: true),
                        onStockOut: () => _openAdjust(row, stockInFlow: false),
                        onEdit: () => _openForm(item: row),
                        onLogs: () => _openTransactions(row),
                        onDelete: () => _delete(row),
                        name: _name(row),
                        generic: _generic(row),
                        category: _itemCategory(row),
                        strength: _strength(row),
                        unit: _unit(row),
                        qty: _qty(row),
                        status: _status(row),
                        expiry: _expiry(row),
                        reorderLevel: _reorder(row),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  String _id(Map<String, dynamic> row) =>
      _text(row['id'] ?? row['inventoryId'] ?? row['inventory_id']);

  String _name(Map<String, dynamic> row) =>
      _text(row['medicationName'] ?? row['medication_name'],
          fallback: 'Medication');

  String _generic(Map<String, dynamic> row) =>
      _text(row['genericName'] ?? row['generic_name']);

  String _itemCategory(Map<String, dynamic> row) =>
      _text(row['category'], fallback: 'other');

  String _strength(Map<String, dynamic> row) =>
      _text(row['strength'], fallback: '-');

  String _unit(Map<String, dynamic> row) {
    return _text(row['unitOfMeasure'] ?? row['unit_of_measure'] ?? row['unit'],
        fallback: 'units');
  }

  int _qty(Map<String, dynamic> row) {
    return _intVal(row['quantityInStock'] ??
        row['quantity_in_stock'] ??
        row['quantity'] ??
        row['currentQuantity'] ??
        row['current_quantity']);
  }

  int _reorder(Map<String, dynamic> row) =>
      _intVal(row['reorderLevel'] ?? row['reorder_level']);

  String _status(Map<String, dynamic> row) {
    final qty = _qty(row);
    final reorder = _reorder(row);
    final expiry = _dateVal(row['expirationDate'] ?? row['expiration_date']);

    if (expiry != null &&
        expiry.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return 'expired';
    }
    if (qty <= 0) return 'out_of_stock';
    if (reorder > 0 && qty <= reorder) return 'low_stock';
    return 'in_stock';
  }

  String _expiry(Map<String, dynamic> row) {
    final parsed = _dateVal(row['expirationDate'] ?? row['expiration_date']);
    if (parsed == null) return 'N/A';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[parsed.month - 1]} ${parsed.year}';
  }

  List<String> _categories() {
    final values = <String>{'all'};
    final byCategory = _stats['byCategory'] ?? _stats['by_category'];
    if (byCategory is List) {
      for (final row in byCategory) {
        if (row is Map) {
          final c = _text(row['category']);
          if (c.isNotEmpty) values.add(c);
        } else {
          final c = row?.toString().trim() ?? '';
          if (c.isNotEmpty) values.add(c);
        }
      }
    }
    for (final row in _items) {
      final c = _itemCategory(row);
      if (c.isNotEmpty) values.add(c);
    }
    final list = values.toList();
    list.sort((a, b) {
      if (a == 'all') return -1;
      if (b == 'all') return 1;
      return a.compareTo(b);
    });
    return list;
  }

  int _read(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final direct = int.tryParse(data[key]?.toString() ?? '');
      if (direct != null) return direct;
      final snake = key
          .replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m[0]}')
          .toLowerCase();
      final alt = int.tryParse(data[snake]?.toString() ?? '');
      if (alt != null) return alt;
    }
    return 0;
  }

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _toList(dynamic data) {
    if (data is! List) return <Map<String, dynamic>>[];
    return data.whereType<Map>().map((row) {
      return Map<String, dynamic>.from(
          row.map((k, v) => MapEntry(k.toString(), v)));
    }).toList();
  }

  int _intVal(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _dateVal(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  String _text(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _human(String value) {
    final text = value.trim();
    if (text.isEmpty) return '-';
    return text
        .split(RegExp(r'[_\s]+'))
        .where((word) => word.isNotEmpty)
        .map((word) =>
            '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _err(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                    fontSize: 30, height: 1, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryTableView extends StatelessWidget {
  const _InventoryTableView({
    required this.items,
    required this.isAdmin,
    required this.saving,
    required this.onStockIn,
    required this.onStockOut,
    required this.onEdit,
    required this.onLogs,
    required this.onDelete,
    required this.getName,
    required this.getGeneric,
    required this.getCategory,
    required this.getStrength,
    required this.getUnit,
    required this.getQty,
    required this.getStatus,
    required this.getExpiry,
  });

  final List<Map<String, dynamic>> items;
  final bool isAdmin;
  final bool saving;
  final ValueChanged<Map<String, dynamic>> onStockIn;
  final ValueChanged<Map<String, dynamic>> onStockOut;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onLogs;
  final ValueChanged<Map<String, dynamic>> onDelete;
  final String Function(Map<String, dynamic>) getName;
  final String Function(Map<String, dynamic>) getGeneric;
  final String Function(Map<String, dynamic>) getCategory;
  final String Function(Map<String, dynamic>) getStrength;
  final String Function(Map<String, dynamic>) getUnit;
  final int Function(Map<String, dynamic>) getQty;
  final String Function(Map<String, dynamic>) getStatus;
  final String Function(Map<String, dynamic>) getExpiry;

  @override
  Widget build(BuildContext context) {
    Widget h(String text, {int flex = 1, TextAlign? align}) {
      return Expanded(
        flex: flex,
        child: Text(
          text,
          textAlign: align,
          style: const TextStyle(
              color: AppTheme.textMuted, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Row(
            children: [
              h('Medication', flex: 28),
              h('Category', flex: 14),
              h('Strength', flex: 12),
              h('Qty', flex: 12),
              h('Status', flex: 12),
              h('Expiration', flex: 12),
              h('Actions', flex: 18, align: TextAlign.right),
            ],
          ),
        ),
        const Divider(height: 1),
        ...items.map((row) {
          final qty = getQty(row);
          final status = getStatus(row);
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 28,
                  child: Row(
                    children: [
                      const Icon(Icons.medication_outlined,
                          color: AppTheme.deepBlue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(getName(row),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            if (getGeneric(row).isNotEmpty)
                              Text(getGeneric(row),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(flex: 14, child: _chip(_human(getCategory(row)))),
                Expanded(flex: 12, child: Text(getStrength(row))),
                Expanded(flex: 12, child: Text('$qty ${getUnit(row)}')),
                Expanded(flex: 12, child: _statusChip(status)),
                Expanded(flex: 12, child: Text(getExpiry(row))),
                Expanded(
                  flex: 18,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 2,
                      children: [
                        IconButton(
                            tooltip: 'Stock In',
                            onPressed: saving ? null : () => onStockIn(row),
                            icon: const Icon(Icons.arrow_downward_rounded)),
                        IconButton(
                            tooltip: 'Stock Out',
                            onPressed: saving ? null : () => onStockOut(row),
                            icon: const Icon(Icons.arrow_upward_rounded)),
                        IconButton(
                            tooltip: 'Edit',
                            onPressed: saving ? null : () => onEdit(row),
                            icon: const Icon(Icons.edit_outlined)),
                        IconButton(
                            tooltip: 'Transactions',
                            onPressed: saving ? null : () => onLogs(row),
                            icon: const Icon(Icons.history_rounded)),
                        if (isAdmin)
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: saving ? null : () => onDelete(row),
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Color(0xFFE11D48)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static Widget _chip(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.border),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  static Widget _statusChip(String status) {
    final s = status.toLowerCase().trim();
    late String label;
    late Color fg;
    late Color bg;
    if (s == 'out_of_stock') {
      label = 'Out of Stock';
      fg = const Color(0xFF991B1B);
      bg = const Color(0xFFFEE2E2);
    } else if (s == 'low_stock') {
      label = 'Low Stock';
      fg = const Color(0xFF92400E);
      bg = const Color(0xFFFEF3C7);
    } else if (s == 'expired') {
      label = 'Expired';
      fg = const Color(0xFF334155);
      bg = const Color(0xFFE2E8F0);
    } else {
      label = 'In Stock';
      fg = const Color(0xFF1D4ED8);
      bg = const Color(0xFFE0E7FF);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(label,
            style: TextStyle(
                color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  static String _human(String value) {
    final t = value.trim();
    if (t.isEmpty) return '-';
    return t
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

class _InventoryMobileTile extends StatelessWidget {
  const _InventoryMobileTile({
    required this.row,
    required this.isAdmin,
    required this.saving,
    required this.onStockIn,
    required this.onStockOut,
    required this.onEdit,
    required this.onLogs,
    required this.onDelete,
    required this.name,
    required this.generic,
    required this.category,
    required this.strength,
    required this.unit,
    required this.qty,
    required this.status,
    required this.expiry,
    required this.reorderLevel,
  });

  final Map<String, dynamic> row;
  final bool isAdmin;
  final bool saving;
  final VoidCallback onStockIn;
  final VoidCallback onStockOut;
  final VoidCallback onEdit;
  final VoidCallback onLogs;
  final VoidCallback onDelete;
  final String name;
  final String generic;
  final String category;
  final String strength;
  final String unit;
  final int qty;
  final String status;
  final String expiry;
  final int reorderLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (generic.isNotEmpty)
                      Text(generic,
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              _InventoryTableView._chip(_human(category)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              Text('Strength: $strength'),
              Text('Qty: $qty $unit'),
              Text('Expires: $expiry'),
              Text('Reorder: $reorderLevel'),
            ],
          ),
          const SizedBox(height: 8),
          _InventoryTableView._statusChip(status),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              OutlinedButton.icon(
                  onPressed: saving ? null : onStockIn,
                  icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                  label: const Text('Stock In')),
              OutlinedButton.icon(
                  onPressed: saving ? null : onStockOut,
                  icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                  label: const Text('Stock Out')),
              OutlinedButton.icon(
                  onPressed: saving ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit')),
              OutlinedButton.icon(
                  onPressed: saving ? null : onLogs,
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text('Logs')),
              if (isAdmin)
                OutlinedButton.icon(
                  onPressed: saving ? null : onDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 16, color: Color(0xFFE11D48)),
                  label: const Text('Delete',
                      style: TextStyle(color: Color(0xFFE11D48))),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _human(String value) {
    final t = value.trim();
    if (t.isEmpty) return '-';
    return t
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

class _MedicationDialog extends StatefulWidget {
  const _MedicationDialog({
    required this.initial,
    required this.categories,
  });

  final Map<String, dynamic>? initial;
  final List<String> categories;

  @override
  State<_MedicationDialog> createState() => _MedicationDialogState();
}

class _MedicationDialogState extends State<_MedicationDialog> {
  final _name = TextEditingController();
  final _generic = TextEditingController();
  final _strength = TextEditingController();
  final _manufacturer = TextEditingController();
  final _batch = TextEditingController();
  final _qty = TextEditingController();
  final _reorder = TextEditingController();
  final _unitCost = TextEditingController();
  final _location = TextEditingController();
  final _notes = TextEditingController();

  DateTime? _expiry;
  String _category = 'other';
  String _formulation = 'tablet';
  String _unit = 'units';
  String _storage = '';
  bool _requiresPrescription = false;
  bool _controlled = false;
  String? _error;

  bool get editing => widget.initial != null && widget.initial!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? const <String, dynamic>{};
    _name.text = _text(i['medicationName'] ?? i['medication_name']);
    _generic.text = _text(i['genericName'] ?? i['generic_name']);
    _strength.text = _text(i['strength']);
    _manufacturer.text = _text(i['manufacturer']);
    _batch.text = _text(i['batchNumber'] ?? i['batch_number']);
    _qty.text = _text(
        i['quantityInStock'] ??
            i['quantity_in_stock'] ??
            i['initialQuantity'] ??
            i['initial_quantity'],
        fallback: '0');
    _reorder.text =
        _text(i['reorderLevel'] ?? i['reorder_level'], fallback: '10');
    _unitCost.text =
        _text(i['unitCostCents'] ?? i['unit_cost_cents'], fallback: '0');
    _location.text = _text(i['storageLocation'] ?? i['storage_location']);
    _notes.text = _text(i['notes']);

    _category = _text(i['category'], fallback: 'other');
    _formulation = _text(i['formulation'], fallback: 'tablet');
    _unit =
        _text(i['unitOfMeasure'] ?? i['unit_of_measure'], fallback: 'units');
    _storage = _text(i['storageConditions'] ?? i['storage_conditions']);
    _requiresPrescription =
        (i['requiresPrescription'] ?? i['requires_prescription']) == true;
    _controlled =
        (i['controlledSubstance'] ?? i['controlled_substance']) == true;
    _expiry =
        DateTime.tryParse(_text(i['expirationDate'] ?? i['expiration_date']));
  }

  @override
  void dispose() {
    _name.dispose();
    _generic.dispose();
    _strength.dispose();
    _manufacturer.dispose();
    _batch.dispose();
    _qty.dispose();
    _reorder.dispose();
    _unitCost.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        widget.categories.where((v) => v != 'all').toList(growable: true);
    if (categories.isEmpty) categories.addAll(defaultCategories);
    if (!categories.contains(_category)) categories.add(_category);

    return AlertDialog(
      title: Text(editing ? 'Edit Medication' : 'Add New Medication'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!,
                      style: const TextStyle(color: Color(0xFFE11D48))),
                ),
              TextField(
                  controller: _name,
                  decoration:
                      const InputDecoration(labelText: 'Medication Name *')),
              const SizedBox(height: 10),
              _two(
                child1: TextField(
                    controller: _generic,
                    decoration:
                        const InputDecoration(labelText: 'Generic Name')),
                child2: AppDropdownFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Category *'),
                  items: categories
                      .map((v) =>
                          DropdownMenuItem(value: v, child: Text(_human(v))))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _category = v);
                  },
                ),
              ),
              const SizedBox(height: 10),
              _two(
                child1: AppDropdownFormField<String>(
                  value: _formulation,
                  decoration: const InputDecoration(labelText: 'Formulation *'),
                  items: formulations
                      .map((v) =>
                          DropdownMenuItem(value: v, child: Text(_human(v))))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _formulation = v);
                  },
                ),
                child2: TextField(
                    controller: _strength,
                    decoration: const InputDecoration(labelText: 'Strength *')),
              ),
              const SizedBox(height: 10),
              _two(
                child1: TextField(
                    controller: _manufacturer,
                    decoration:
                        const InputDecoration(labelText: 'Manufacturer')),
                child2: TextField(
                    controller: _batch,
                    decoration:
                        const InputDecoration(labelText: 'Batch Number')),
              ),
              const SizedBox(height: 10),
              _two(
                child1: _DateInput(
                    label: 'Expiration Date',
                    value: _expiry,
                    onChanged: (v) => setState(() => _expiry = v)),
                child2: TextField(
                    controller: _qty,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Initial Quantity')),
              ),
              const SizedBox(height: 10),
              _two(
                child1: AppDropdownFormField<String>(
                  value: _unit,
                  decoration:
                      const InputDecoration(labelText: 'Unit of Measure'),
                  items: units
                      .map((v) =>
                          DropdownMenuItem(value: v, child: Text(_human(v))))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _unit = v);
                  },
                ),
                child2: TextField(
                    controller: _reorder,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Reorder Level')),
              ),
              const SizedBox(height: 10),
              _two(
                child1: TextField(
                    controller: _unitCost,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Unit Cost (cents)')),
                child2: TextField(
                    controller: _location,
                    decoration:
                        const InputDecoration(labelText: 'Storage Location')),
              ),
              const SizedBox(height: 10),
              AppDropdownFormField<String>(
                value: _storage.isEmpty ? null : _storage,
                decoration:
                    const InputDecoration(labelText: 'Storage Conditions'),
                items: storageConditions
                    .map((v) =>
                        DropdownMenuItem(value: v, child: Text(_human(v))))
                    .toList(),
                onChanged: (v) => setState(() => _storage = v ?? ''),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Requires Prescription'),
                        value: _requiresPrescription,
                        onChanged: (v) =>
                            setState(() => _requiresPrescription = v),
                      ),
                    ),
                    Expanded(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Controlled Substance'),
                        value: _controlled,
                        onChanged: (v) => setState(() => _controlled = v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        ElevatedButton(
            onPressed: _submit,
            child: Text(editing ? 'Save Changes' : 'Add Medication')),
      ],
    );
  }

  Widget _two({required Widget child1, required Widget child2}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 580) {
          return Column(
            children: [child1, const SizedBox(height: 10), child2],
          );
        }
        return Row(
          children: [
            Expanded(child: child1),
            const SizedBox(width: 10),
            Expanded(child: child2),
          ],
        );
      },
    );
  }

  void _submit() {
    final name = _name.text.trim();
    final strength = _strength.text.trim();
    if (name.isEmpty || strength.isEmpty || _category.trim().isEmpty) {
      setState(() => _error =
          'Medication name, category, formulation and strength are required.');
      return;
    }

    final payload = <String, dynamic>{
      'medicationName': name,
      'genericName': _generic.text.trim(),
      'category': _category,
      'formulation': _formulation,
      'strength': strength,
      'manufacturer': _manufacturer.text.trim(),
      'batchNumber': _batch.text.trim(),
      'expirationDate': _expiry?.toIso8601String(),
      'unitOfMeasure': _unit,
      'reorderLevel': int.tryParse(_reorder.text.trim()),
      'unitCostCents': int.tryParse(_unitCost.text.trim()),
      'storageLocation': _location.text.trim(),
      'storageConditions': _storage,
      'requiresPrescription': _requiresPrescription,
      'controlledSubstance': _controlled,
      'notes': _notes.text.trim(),
    };

    final qty = int.tryParse(_qty.text.trim());
    if (qty != null) {
      payload['quantityInStock'] = qty;
      payload['initialQuantity'] = qty;
    }

    payload.removeWhere((k, v) {
      if (v == null) return true;
      if (v is String) return v.trim().isEmpty;
      return false;
    });

    Navigator.of(context).pop(payload);
  }

  String _text(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _human(String value) {
    final t = value.trim();
    if (t.isEmpty) return '-';
    return t
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

class _AdjustDialog extends StatefulWidget {
  const _AdjustDialog({required this.stockIn, required this.item});

  final bool stockIn;
  final Map<String, dynamic> item;

  @override
  State<_AdjustDialog> createState() => _AdjustDialogState();
}

class _AdjustDialogState extends State<_AdjustDialog> {
  final _qty = TextEditingController();
  final _reason = TextEditingController();
  final _reference = TextEditingController();
  final _patientId = TextEditingController();
  final _batch = TextEditingController();
  final _notes = TextEditingController();

  DateTime? _expiration;
  String _transactionType = 'stock_in';
  String? _error;

  @override
  void initState() {
    super.initState();
    _transactionType = widget.stockIn ? 'stock_in' : 'stock_out';
  }

  @override
  void dispose() {
    _qty.dispose();
    _reason.dispose();
    _reference.dispose();
    _patientId.dispose();
    _batch.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.item['medicationName'] ??
            widget.item['medication_name'] ??
            'Medication')
        .toString();

    return AlertDialog(
      title: Text(widget.stockIn ? 'Adjust Stock In' : 'Adjust Stock Out'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!,
                      style: const TextStyle(color: Color(0xFFE11D48))),
                ),
              AppDropdownFormField<String>(
                value: _transactionType,
                decoration:
                    const InputDecoration(labelText: 'Transaction Type *'),
                items: const [
                  DropdownMenuItem(value: 'stock_in', child: Text('Stock In')),
                  DropdownMenuItem(
                      value: 'stock_out', child: Text('Stock Out')),
                  DropdownMenuItem(
                      value: 'adjustment', child: Text('Adjustment')),
                  DropdownMenuItem(value: 'dispense', child: Text('Dispense')),
                  DropdownMenuItem(value: 'return', child: Text('Return')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _transactionType = v);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                  controller: _qty,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity *')),
              const SizedBox(height: 10),
              TextField(
                  controller: _reason,
                  decoration: const InputDecoration(labelText: 'Reason')),
              const SizedBox(height: 10),
              TextField(
                  controller: _reference,
                  decoration:
                      const InputDecoration(labelText: 'Reference Number')),
              const SizedBox(height: 10),
              TextField(
                  controller: _patientId,
                  decoration: const InputDecoration(labelText: 'Patient ID')),
              const SizedBox(height: 10),
              TextField(
                  controller: _batch,
                  decoration: const InputDecoration(labelText: 'Batch Number')),
              const SizedBox(height: 10),
              _DateInput(
                  label: 'Expiration Date',
                  value: _expiration,
                  onChanged: (v) => setState(() => _expiration = v)),
              const SizedBox(height: 10),
              TextField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  void _submit() {
    final qty = int.tryParse(_qty.text.trim());
    if (qty == null || qty <= 0) {
      setState(() => _error = 'Enter a valid quantity.');
      return;
    }

    final payload = <String, dynamic>{
      'transactionType': _transactionType,
      'quantity': qty,
      'reason': _reason.text.trim(),
      'referenceNumber': _reference.text.trim(),
      'patientId': _patientId.text.trim(),
      'batchNumber': _batch.text.trim(),
      'expirationDate': _expiration?.toIso8601String(),
      'notes': _notes.text.trim(),
    };

    payload.removeWhere((k, v) {
      if (v == null) return true;
      if (v is String) return v.trim().isEmpty;
      return false;
    });

    Navigator.of(context).pop(payload);
  }
}

class _TransactionsDialog extends StatefulWidget {
  const _TransactionsDialog({
    required this.api,
    required this.inventoryId,
    required this.name,
  });

  final HealthReachApi api;
  final String inventoryId;
  final String name;

  @override
  State<_TransactionsDialog> createState() => _TransactionsDialogState();
}

class _TransactionsDialogState extends State<_TransactionsDialog> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data =
          await widget.api.getInventoryTransactions(widget.inventoryId);
      final rows = data.whereType<Map>().map((r) {
        return Map<String, dynamic>.from(
            r.map((k, v) => MapEntry(k.toString(), v)));
      }).toList();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException ? error.message : error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Transactions - ${widget.name}'),
      content: SizedBox(
        width: 720,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
                ? Text(_error!,
                    style: const TextStyle(color: Color(0xFFE11D48)))
                : _rows.isEmpty
                    ? const Text('No transaction logs found.')
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 420),
                        child: ListView.separated(
                          itemCount: _rows.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final row = _rows[index];
                            final type = _text(
                                row['transactionType'] ??
                                    row['transaction_type'],
                                fallback: 'transaction');
                            final qty = _text(row['quantity'], fallback: '--');
                            final at =
                                _date(row['createdAt'] ?? row['created_at']);
                            final by = _who(row);
                            final note = _text(row['notes'] ?? row['reason']);
                            final parts = <String>[at];
                            if (by.isNotEmpty) parts.add('By: $by');
                            if (note.isNotEmpty) parts.add(note);

                            return ListTile(
                              dense: true,
                              title: Text('${_human(type)} - Qty: $qty',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(parts.join(' | ')),
                            );
                          },
                        ),
                      ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close')),
      ],
    );
  }

  String _who(Map<String, dynamic> row) {
    final first =
        _text(row['performedByFirstName'] ?? row['performed_by_first_name']);
    final last =
        _text(row['performedByLastName'] ?? row['performed_by_last_name']);
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;
    return _text(row['performedByName'] ??
        row['performed_by_name'] ??
        row['performedBy'] ??
        row['performed_by']);
  }

  String _date(dynamic value) {
    final d = DateTime.tryParse(value?.toString() ?? '');
    if (d == null) return 'N/A';
    return '${d.year}-${_pad(d.month)}-${_pad(d.day)} ${_pad(d.hour)}:${_pad(d.minute)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String _text(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _human(String value) {
    final t = value.trim();
    if (t.isEmpty) return '-';
    return t
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

class _DateInput extends StatelessWidget {
  const _DateInput({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? ''
        : '${value!.year}-${_pad(value!.month)}-${_pad(value!.day)}';

    return TextField(
      readOnly: true,
      controller: TextEditingController(text: text),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null)
              IconButton(
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.clear_rounded),
              ),
            IconButton(
              onPressed: () => _pick(context),
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          ],
        ),
      ),
      onTap: () => _pick(context),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 15),
      lastDate: DateTime(now.year + 30),
    );
    onChanged(picked);
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

const Map<String, String> stockOptions = {
  _AdminInventoryPageState.stockAll: 'All Stock',
  _AdminInventoryPageState.stockIn: 'In Stock',
  _AdminInventoryPageState.stockLow: 'Low Stock',
  _AdminInventoryPageState.stockOut: 'Out of Stock',
  _AdminInventoryPageState.stockExpiring: 'Expiring Soon',
};

const List<String> defaultCategories = [
  'other',
  'antibiotic',
  'analgesic',
  'antiseptic',
  'consumable',
  'vaccine',
];

const List<String> formulations = [
  'tablet',
  'capsule',
  'syrup',
  'injection',
  'cream',
  'other',
];

const List<String> units = [
  'units',
  'boxes',
  'packs',
  'bottles',
  'vials',
  'tubes',
];

const List<String> storageConditions = [
  'room_temperature',
  'refrigerated',
  'frozen',
  'controlled',
  'other',
];

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class AppDropdownFormField<T> extends StatelessWidget {
  const AppDropdownFormField({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.decoration,
    this.hint,
    this.disabledHint,
    this.validator,
    this.onSaved,
    this.autovalidateMode,
    this.focusNode,
    this.borderRadius = const BorderRadius.all(Radius.circular(_kSelectRadius)),
    this.menuMaxHeight = 320,
    this.isDense = true,
  });

  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final InputDecoration? decoration;
  final Widget? hint;
  final Widget? disabledHint;
  final FormFieldValidator<T>? validator;
  final FormFieldSetter<T>? onSaved;
  final AutovalidateMode? autovalidateMode;
  final FocusNode? focusNode;
  final BorderRadius borderRadius;
  final double menuMaxHeight;
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final decoration = _inputDecoration(
      context,
      enabled,
      value != null,
      this.decoration,
    );

    return DropdownButtonFormField<T>(
      value: value,
      items: _styledItems(context, items),
      onChanged: onChanged,
      decoration: decoration,
      hint: hint,
      disabledHint: disabledHint,
      validator: validator,
      onSaved: onSaved,
      autovalidateMode: autovalidateMode,
      focusNode: focusNode,
      isExpanded: true,
      isDense: isDense,
      menuMaxHeight: menuMaxHeight,
      borderRadius: borderRadius,
      dropdownColor: Colors.white,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppTheme.deepBlue,
      ),
      style: _textStyle(context, enabled: enabled),
      selectedItemBuilder: items == null
          ? null
          : (context) => _selectedItems(
                context,
                items!,
                enabled: enabled,
              ),
    );
  }
}

class AppDropdownButton<T> extends StatelessWidget {
  const AppDropdownButton({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.hint,
    this.disabledHint,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    this.borderRadius = const BorderRadius.all(Radius.circular(_kSelectRadius)),
    this.menuMaxHeight = 320,
    this.isExpanded = false,
  });

  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final Widget? hint;
  final Widget? disabledHint;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double menuMaxHeight;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final hasValue = value != null;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _fillColor(enabled: enabled, hasValue: hasValue),
        borderRadius: borderRadius,
        border: Border.fromBorderSide(
          _borderSide(enabled: enabled, hasValue: hasValue),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D3A7BD5),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: _styledItems(context, items)!,
          onChanged: onChanged,
          hint: hint,
          disabledHint: disabledHint,
          isExpanded: isExpanded,
          menuMaxHeight: menuMaxHeight,
          borderRadius: borderRadius,
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.deepBlue,
          ),
          style: _textStyle(context, enabled: enabled),
          selectedItemBuilder: (context) => _selectedItems(
            context,
            items,
            enabled: enabled,
          ),
        ),
      ),
    );
  }
}

const double _kSelectRadius = 18;

InputDecoration _inputDecoration(
  BuildContext context,
  bool enabled,
  bool hasValue,
  InputDecoration? decoration,
) {
  final theme = Theme.of(context);
  return (decoration ?? const InputDecoration()).copyWith(
    filled: true,
    fillColor: _fillColor(enabled: enabled, hasValue: hasValue),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    labelStyle: theme.textTheme.bodyMedium?.copyWith(
      color: AppTheme.textMuted,
      fontWeight: FontWeight.w500,
    ),
    floatingLabelStyle: theme.textTheme.bodySmall?.copyWith(
      color: AppTheme.deepBlue,
      fontWeight: FontWeight.w600,
    ),
    hintStyle: theme.textTheme.bodyMedium?.copyWith(
      color: AppTheme.textMuted,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kSelectRadius),
      borderSide: _borderSide(enabled: enabled, hasValue: hasValue),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kSelectRadius),
      borderSide: _borderSide(enabled: enabled, hasValue: hasValue),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kSelectRadius),
      borderSide: const BorderSide(
        color: AppTheme.deepBlue,
        width: 1.5,
      ),
    ),
  );
}

TextStyle? _textStyle(
  BuildContext context, {
  required bool enabled,
  bool isSelected = false,
}) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: enabled ? AppTheme.textPrimary : AppTheme.textMuted,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      );
}

List<DropdownMenuItem<T>>? _styledItems<T>(
  BuildContext context,
  List<DropdownMenuItem<T>>? items,
) {
  if (items == null) return null;

  return items
      .map(
        (item) => DropdownMenuItem<T>(
          value: item.value,
          enabled: item.enabled,
          onTap: item.onTap,
          alignment: item.alignment,
          child: DefaultTextStyle.merge(
            style: _textStyle(
              context,
              enabled: item.enabled,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: item.child,
          ),
        ),
      )
      .toList();
}

List<Widget> _selectedItems<T>(
  BuildContext context,
  List<DropdownMenuItem<T>> items, {
  required bool enabled,
}) {
  return items
      .map(
        (item) => Align(
          alignment: Alignment.centerLeft,
          child: DefaultTextStyle.merge(
            style: _textStyle(
              context,
              enabled: enabled,
              isSelected: true,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: item.child,
          ),
        ),
      )
      .toList();
}

Color _fillColor({
  required bool enabled,
  required bool hasValue,
}) {
  if (!enabled) return AppTheme.background;
  if (hasValue) return const Color(0xFFF5FAFF);
  return Colors.white;
}

BorderSide _borderSide({
  required bool enabled,
  required bool hasValue,
}) {
  if (!enabled) {
    return const BorderSide(color: AppTheme.border);
  }
  if (hasValue) {
    return const BorderSide(color: Color(0xFFB6D5FF), width: 1.1);
  }
  return const BorderSide(color: AppTheme.border);
}

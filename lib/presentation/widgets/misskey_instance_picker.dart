import 'package:flutter/material.dart';

/// Dialog for selecting a Misskey instance for sharing.
///
/// Provides common instances and allows custom instance input.
class MisskeyInstancePicker extends StatefulWidget {
  const MisskeyInstancePicker({super.key});

  /// Shows the Misskey instance picker dialog.
  ///
  /// Returns the selected instance domain (e.g., "misskey.io") or null if cancelled.
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => const MisskeyInstancePicker(),
    );
  }

  @override
  State<MisskeyInstancePicker> createState() => _MisskeyInstancePickerState();
}

class _MisskeyInstancePickerState extends State<MisskeyInstancePicker> {
  // Common Misskey instances
  static const List<String> _commonInstances = [
    'misskey.io',
    'misskey.dev',
    'fedibird.com',
    'mstdn.jp',
  ];

  String _selectedInstance = 'misskey.io';
  bool _isCustom = false;
  final TextEditingController _customController = TextEditingController();
  String? _customError;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  /// Validates a custom instance domain.
  bool _validateCustomInstance(String value) {
    if (value.isEmpty) {
      setState(() {
        _customError = 'Please enter an instance domain';
      });
      return false;
    }

    // Basic domain validation
    final domainRegex = RegExp(
      r'^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*(\.[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*)*\.[a-zA-Z]{2,}$',
    );

    if (!domainRegex.hasMatch(value)) {
      setState(() {
        _customError = 'Please enter a valid domain';
      });
      return false;
    }

    setState(() {
      _customError = null;
    });
    return true;
  }

  void _handleOk() {
    if (_isCustom) {
      final customValue = _customController.text.trim();
      if (_validateCustomInstance(customValue)) {
        Navigator.of(context).pop(customValue);
      }
    } else {
      Navigator.of(context).pop(_selectedInstance);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Misskey Instance'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Common instances
            ..._commonInstances.map(
              (instance) => RadioListTile<String>(
                title: Text(instance),
                value: instance,
                groupValue: _isCustom ? null : _selectedInstance,
                onChanged: (value) {
                  setState(() {
                    _selectedInstance = value!;
                    _isCustom = false;
                    _customError = null;
                  });
                },
              ),
            ),

            const Divider(),

            // Custom instance option
            RadioListTile<bool>(
              title: const Text('Custom'),
              value: true,
              groupValue: _isCustom ? true : null,
              onChanged: (value) {
                setState(() {
                  _isCustom = value!;
                  _customError = null;
                });
              },
            ),

            // Custom instance input
            if (_isCustom)
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 8.0,
                ),
                child: TextField(
                  controller: _customController,
                  decoration: InputDecoration(
                    hintText: 'e.g., your-instance.com',
                    labelText: 'Instance domain',
                    errorText: _customError,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    if (_customError != null) {
                      _validateCustomInstance(value);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _handleOk, child: const Text('OK')),
      ],
    );
  }
}

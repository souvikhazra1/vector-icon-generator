import 'package:flutter/material.dart';

class CheckBoxStateful extends StatefulWidget {

  final ValueChanged<bool> onChanged;
  final bool value;

  const CheckBoxStateful({super.key, required this.onChanged, required this.value});

  @override
  State<StatefulWidget> createState() => _CheckBoxStatefulState();
}

class _CheckBoxStatefulState extends State<CheckBoxStateful> {
  bool _value = false;


  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Checkbox(value: _value, onChanged: (value) {
      setState(() => _value = value ?? false);
      widget.onChanged(value ?? false);
    });
  }
}
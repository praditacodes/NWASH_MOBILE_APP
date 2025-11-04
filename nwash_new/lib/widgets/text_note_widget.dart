import 'package:flutter/material.dart';

class TextNoteWidget extends StatefulWidget {
  final String notes;
  final ValueChanged<String> onNotesChanged;

  const TextNoteWidget({required this.notes, required this.onNotesChanged});

  @override
  State<TextNoteWidget> createState() => _TextNoteWidgetState();
}

class _TextNoteWidgetState extends State<TextNoteWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.notes);
  }

  @override
  void didUpdateWidget(covariant TextNoteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes != widget.notes) {
      _controller.text = widget.notes;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(
          decoration: InputDecoration(hintText: 'Enter notes here'),
          maxLines: 2,
          controller: _controller,
          onChanged: widget.onNotesChanged,
        ),
      ],
    );
  }
}
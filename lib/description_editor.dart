import 'package:flutter/material.dart';

class DescriptionEditor extends StatefulWidget {
  final String currentDescription;
  final Function(String) onDescriptionSubmitted;

  const DescriptionEditor({
    super.key,
    required this.currentDescription,
    required this.onDescriptionSubmitted,
  });

  @override
  _DescriptionEditorState createState() => _DescriptionEditorState();
}

class _DescriptionEditorState extends State<DescriptionEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentDescription);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitDescription() {
    widget.onDescriptionSubmitted(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 345,
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black87, width: 6),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8.0),
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: 1,
              decoration: const InputDecoration(
                hintText: 'Enter description',
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          SizedBox(
            width: 50,
            height: 50,
            child: TextButton(
              onPressed: () {
                _submitDescription();
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.black87,
              ),
              child: const Text(
                '✓',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
        ],
      ),
    );
  }
}

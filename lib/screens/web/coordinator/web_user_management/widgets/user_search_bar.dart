import 'package:flutter/material.dart';
import '../utils/user_management_constants.dart';

class UserSearchBar extends StatefulWidget {
  final String searchQuery;
  final Function(String) onSearchChanged;

  const UserSearchBar({
    Key? key,
    required this.searchQuery,
    required this.onSearchChanged,
  }) : super(key: key);

  @override
  State<UserSearchBar> createState() => _UserSearchBarState();
}

class _UserSearchBarState extends State<UserSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(UserSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery &&
        widget.searchQuery != _controller.text) {
      _controller.text = widget.searchQuery;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: widget.onSearchChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by name, email, or student ID...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              UserManagementConstants.searchIcon,
              color: _isFocused ? const Color(0xFF6366F1) : Colors.grey[600],
              size: 20,
            ),
          ),
          suffixIcon: widget.searchQuery.isNotEmpty
              ? Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _controller.clear();
                      widget.onSearchChanged('');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.clear,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ),
                  ),
                )
              : null,
          filled: true,
          fillColor: _isFocused ? Colors.white : Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _isFocused 
                  ? const Color(0xFF6366F1) 
                  : Colors.grey[300]!,
              width: _isFocused ? 2 : 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF6366F1),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
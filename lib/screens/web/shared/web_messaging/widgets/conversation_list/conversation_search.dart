import 'package:flutter/material.dart';
import '../../utils/messaging_constants.dart';

class ConversationSearch extends StatefulWidget {
  final Function(String) onSearchChanged;
  final String searchQuery;

  const ConversationSearch({
    super.key,
    required this.onSearchChanged,
    required this.searchQuery,
  });

  @override
  State<ConversationSearch> createState() => _ConversationSearchState();
}

class _ConversationSearchState extends State<ConversationSearch> {
  late TextEditingController _searchController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MessagingConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: widget.onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[500],
          ),
          suffixIcon: widget.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    widget.onSearchChanged('');
                    _focusNode.unfocus();
                  },
                  color: Colors.grey[500],
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MessagingConstants.inputBorderRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MessagingConstants.inputBorderRadius),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MessagingConstants.inputBorderRadius),
            borderSide: const BorderSide(
              color: MessagingConstants.primaryColor,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
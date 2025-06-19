import 'package:flutter/material.dart';
import '../utils/announcement_constants.dart';

class FiltersAndSort extends StatelessWidget {
  final List<String> selectedFilters;
  final String sortBy;
  final Function(String, bool) onFilterChanged;
  final Function(String) onSortChanged;

  const FiltersAndSort({
    super.key,
    required this.selectedFilters,
    required this.sortBy,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AnnouncementConstants.filterOptions.map((filter) {
                final isSelected = selectedFilters.contains(filter);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) => onFilterChanged(filter, selected),
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF0F2D52),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    elevation: isSelected ? 4 : 0,
                    shadowColor: const Color(0xFF0F2D52).withOpacity(0.3),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButton<String>(
            value: sortBy,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F2D52)),
            items: AnnouncementConstants.sortOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option['value'] as String,
                child: Row(
                  children: [
                    Icon(option['icon'] as IconData, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(option['label'] as String),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onSortChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }
}
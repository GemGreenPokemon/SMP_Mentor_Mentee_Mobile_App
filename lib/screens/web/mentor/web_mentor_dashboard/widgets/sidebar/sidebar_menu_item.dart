import 'package:flutter/material.dart';
import '../../models/sidebar_item.dart';
import '../../utils/dashboard_constants.dart';

class SidebarMenuItem extends StatefulWidget {
  final SidebarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const SidebarMenuItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<SidebarMenuItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: AnimatedContainer(
          duration: DashboardDurations.hoverAnimation,
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  )
                : null,
            color: !widget.isSelected && isHovered
                ? Colors.white.withOpacity(0.08)
                : null,
            borderRadius: BorderRadius.circular(12),
            border: widget.isSelected
                ? Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  )
                : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DashboardSizes.spacingMedium,
              vertical: 4,
            ),
            leading: AnimatedContainer(
              duration: DashboardDurations.hoverAnimation,
              padding: const EdgeInsets.all(DashboardSizes.spacingSmall),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.item.icon,
                color: widget.isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.7),
                size: 22,
              ),
            ),
            title: Text(
              widget.item.title,
              style: TextStyle(
                fontWeight: widget.isSelected
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: widget.isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.85),
                fontSize: 15,
              ),
            ),
            trailing: widget.isSelected
                ? Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  )
                : null,
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}
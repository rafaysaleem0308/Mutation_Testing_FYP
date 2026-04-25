import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hello/core/services/api_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  /// Optional callback when unread count changes (for badge updates)
  final ValueChanged<int>? onUnreadCountChanged;

  const NotificationsScreen({super.key, this.onUnreadCountChanged});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _refreshTimer = Timer.periodic(Duration(seconds: 15), (_) => _loadNotifications(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      final result = await ApiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(
            result['notifications'] ?? [],
          );
          _unreadCount = result['unreadCount'] ?? 0;
          _isLoading = false;
        });
        widget.onUnreadCountChanged?.call(_unreadCount);
      }
    } catch (e) {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    final success = await ApiService.markNotificationsRead();
    if (success && mounted) {
      setState(() {
        for (var n in _notifications) {
          n['isRead'] = true;
        }
        _unreadCount = 0;
      });
      widget.onUnreadCountChanged?.call(0);
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear All Notifications', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('This will remove all your notifications. Continue?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Clear', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ApiService.clearAllNotifications();
      if (success && mounted) {
        setState(() {
          _notifications.clear();
          _unreadCount = 0;
        });
        widget.onUnreadCountChanged?.call(0);
      }
    }
  }

  Future<void> _deleteNotification(String id, int index) async {
    final success = await ApiService.deleteNotification(id);
    if (success && mounted) {
      final wasUnread = _notifications[index]['isRead'] != true;
      setState(() {
        _notifications.removeAt(index);
        if (wasUnread) _unreadCount = (_unreadCount - 1).clamp(0, 9999);
      });
      widget.onUnreadCountChanged?.call(_unreadCount);
    }
  }

  Future<void> _onNotificationTap(Map<String, dynamic> notification) async {
    // Mark this one as read
    final id = notification['_id']?.toString();
    if (id != null && notification['isRead'] != true) {
      await ApiService.markNotificationsRead(notificationId: id);
      if (mounted) {
        setState(() {
          notification['isRead'] = true;
          _unreadCount = (_unreadCount - 1).clamp(0, 9999);
        });
        widget.onUnreadCountChanged?.call(_unreadCount);
      }
    }

    // Navigate based on type
    final type = notification['type']?.toString() ?? '';
    final refType = notification['referenceType']?.toString() ?? '';
    final refId = notification['referenceId']?.toString() ?? '';

    if (!mounted) return;

    if (refType == 'order' && refId.isNotEmpty) {
      Navigator.pushNamed(context, '/track_order');
    } else if (refType == 'chat' && refId.isNotEmpty) {
      Navigator.pushNamed(context, '/my-chats');
    } else if (type == 'new_message') {
      Navigator.pushNamed(context, '/my-chats');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 22,
              ),
            ),
            if (_unreadCount > 0) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFFFF512F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_notifications.isNotEmpty && _unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Read all',
                style: GoogleFonts.inter(
                  color: Color(0xFFFF9D42),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_outlined, color: Colors.grey[600]),
              onPressed: _clearAll,
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFFF9D42)))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  physics: AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationTile(_notifications[index], index)
                        .animate()
                        .fadeIn(delay: (index * 40).ms)
                        .slideX(begin: 0.05, end: 0);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Color(0xFFFF9D42).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: Color(0xFFFF9D42).withValues(alpha: 0.4),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You\'ll be notified about orders,\nmessages, and updates here',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification, int index) {
    final bool isRead = notification['isRead'] == true;
    final String title = notification['title'] ?? 'Notification';
    final String body = notification['body'] ?? '';
    final String type = notification['type'] ?? 'system';

    String time = '';
    try {
      if (notification['createdAt'] != null) {
        DateTime date = DateTime.parse(notification['createdAt']);
        DateTime now = DateTime.now();
        Duration diff = now.difference(date);

        if (diff.inMinutes < 1) {
          time = 'Just now';
        } else if (diff.inMinutes < 60) {
          time = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          time = '${diff.inHours}h ago';
        } else if (diff.inDays < 7) {
          time = '${diff.inDays}d ago';
        } else {
          time = DateFormat('MMM d').format(date);
        }
      }
    } catch (_) {}

    return Dismissible(
      key: Key(notification['_id']?.toString() ?? index.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) =>
          _deleteNotification(notification['_id']?.toString() ?? '', index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      child: GestureDetector(
        onTap: () => _onNotificationTap(notification),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(16),
            border: isRead
                ? null
                : Border.all(
                    color: Color(0xFFFF9D42).withValues(alpha: 0.2),
                    width: 1,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getTypeColor(type).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTypeIcon(type),
                  color: _getTypeColor(type),
                  size: 20,
                ),
              ),
              SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight:
                                  isRead ? FontWeight.w500 : FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      body,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Unread indicator
              if (!isRead) ...[
                SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF512F),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'order_placed':
        return Icons.shopping_bag_outlined;
      case 'order_accepted':
        return Icons.check_circle_outline;
      case 'order_ready':
        return Icons.local_dining_outlined;
      case 'order_delivered':
        return Icons.done_all_rounded;
      case 'order_cancelled':
        return Icons.cancel_outlined;
      case 'new_message':
        return Icons.chat_bubble_outline_rounded;
      case 'new_review':
        return Icons.star_outline_rounded;
      case 'promo':
        return Icons.local_offer_outlined;
      case 'welcome':
        return Icons.waving_hand_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'order_placed':
        return Color(0xFF2196F3);
      case 'order_accepted':
        return Color(0xFF4CAF50);
      case 'order_ready':
        return Color(0xFFFF9D42);
      case 'order_delivered':
        return Color(0xFF4CAF50);
      case 'order_cancelled':
        return Color(0xFFF44336);
      case 'new_message':
        return Color(0xFF7C4DFF);
      case 'new_review':
        return Color(0xFFFFB74D);
      case 'promo':
        return Color(0xFFE91E63);
      case 'welcome':
        return Color(0xFFFF9D42);
      default:
        return Color(0xFF78909C);
    }
  }
}

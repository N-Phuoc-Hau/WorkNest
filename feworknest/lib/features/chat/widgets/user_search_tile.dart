import 'package:flutter/material.dart';

class UserSearchTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onTap;

  const UserSearchTile({
    super.key,
    required this.user,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['name'] ?? 'Unknown User';
    final avatar = user['avatar'];
    final role = user['role'] ?? '';
    final company = user['company'];
    final title = user['title'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[300],
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Icon(
                        Icons.person,
                        size: 24,
                        color: Colors.grey[600],
                      )
                    : null,
              ),
              
              const SizedBox(width: 12),
              
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Role and company/title
                    if (role == 'recruiter' && company != null)
                      Text(
                        company,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      )
                    else if (role == 'candidate' && title != null)
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    
                    const SizedBox(height: 4),
                    
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: role == 'recruiter' ? Colors.blue[100] : Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        role == 'recruiter' ? 'Nhà tuyển dụng' : 'Ứng viên',
                        style: TextStyle(
                          fontSize: 12,
                          color: role == 'recruiter' ? Colors.blue[700] : Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Chat icon
              Icon(
                Icons.chat_bubble_outline,
                color: Colors.grey[500],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
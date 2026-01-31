import 'package:flutter/material.dart';

class HeaderCard extends StatelessWidget {
  final String name;
  final String title;
  final String department;
  final VoidCallback onLogout;

  const HeaderCard({
    super.key,
    required this.name,
    required this.title,
    required this.department,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 140,
      color: Colors.indigo,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$title · $department',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              onPressed: onLogout,
            )
          ],
        ),
      ),
    );
  }
}
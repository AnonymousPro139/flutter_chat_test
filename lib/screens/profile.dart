import 'package:flutter/material.dart';
import 'package:test_firebase/models/user.dart';

class ProfileScreen extends StatelessWidget {
  final AppUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   // title: const Text("Profile"),
      //   centerTitle: true,
      //   actions: [
      //     IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined)),
      //   ],
      // ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 18),

              // 1. Profile Header Section
              _buildHeader(context),

              const SizedBox(height: 30),

              // 2. Settings / Info Section
              _buildSectionTitle("Account"),
              _buildInfoTile(Icons.verified_user_outlined, "ID", user.id),
              _buildInfoTile(Icons.phone_android_outlined, "Phone", user.phone),

              const Divider(indent: 20, endIndent: 20, height: 40),

              _buildSectionTitle("Settings"),
              _buildSettingsTile(
                Icons.notifications_none,
                "Notifications",
                () {},
              ),
              _buildSettingsTile(
                Icons.lock_outline,
                "Privacy & Security",
                () {},
              ),
              _buildSettingsTile(Icons.help_outline, "Help & Support", () {}),

              const SizedBox(height: 40),

              // 3. Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () {
                      // Sign out logic here
                    },
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text(
                      "Log Out",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Component Builders ---

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                user.phone.toUpperCase(),
                style: TextStyle(
                  fontSize: 40,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: const Icon(Icons.camera_alt, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "User Name",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // Applying the "Badge" style you requested for the ID
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.inversePrimary.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "ID: ${user.id}",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color.fromARGB(255, 143, 142, 142),
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}

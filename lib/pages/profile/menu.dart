import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zuff/pages/profile/suredelete.dart';
import 'package:zuff/pages/profile/surelogout.dart';

import '../../providers/themeprovider.dart';
import '../../theme/theme.dart';
import 'edit_profile.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildMenuCard(
              context,
              icon: Icons.person_outline,
              title: "Edit Account",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileWidget()),
              ),
            ),
            const SizedBox(height: 12),
            _buildThemeCard(context),
            const SizedBox(height: 12),
            _buildMenuCard(
              context,
              icon: Icons.help_outline,
              title: "Help Center",
              onTap: () {
                // Navigate to help center
              },
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              context,
              icon: Icons.logout_outlined,
              title: "Log Out",
              onTap: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.4), // Blacked-out background
                  builder: (context) => const SureLogout(),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
                context,
                icon: Icons.delete,
                title: "Delete Account",
                onTap: () {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.4), // Blacked-out background
                    builder: (context) => const SureDelete(),
                  );
                },

              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context) {
    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {}, // Optional: Add tap to toggle
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.dark_mode_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Dark Theme",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const SizedBox(
                width: 50,
                child: ThemeSwitch(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SwitchTheme(
      data: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
            if (themeProvider.themeData == darkMode) {
              return Theme.of(context).colorScheme.onPrimary;
            }
            return Theme.of(context).colorScheme.primary;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
            return states.contains(WidgetState.selected)
                ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                : Colors.grey.withOpacity(0.5);
          },
        ),
      ),
      child: Switch(
        value: themeProvider.themeData == darkMode,
        onChanged: (bool value) {
          Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
        },
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

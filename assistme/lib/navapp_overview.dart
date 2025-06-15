import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Team members with all provided information
    final List<Map<String, String>> teamMembers = [
      {
        'name': 'Purnendu Mondal',
        'role': 'Lead Developer',
        'email': 'purnendumondal389@gmail.com',
        'github': 'PurnenduMondal-asCoder',
        'linkedin': 'purnendu-mondal-785078272'
      },
      {
        'name': 'Sandipan Sen',
        'role': 'UI/UX Specialist',
        'email': 'sandipanbca21@gmail.com',
        'github': '',
        'linkedin': ''
      },
      {
        'name': 'Jeet Nandi',
        'role': 'Backend Engineer',
        'email': 'jeetnandi873@gmail.com',
        'github': '',
        'linkedin': ''
      },
      {
        'name': 'Sanket Gandhi',
        'role': 'Quality Assurance',
        'email': 'gandhisanketoct@gmail.com',
        'github': '',
        'linkedin': ''
      },
    ];

    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text('About AssistMe'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Image.asset(
                   'assets/image/app_icon.png',
                   height: 130,
                   width: 150,
                  ),
                  const Text(
                    'AssistMe',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const Text(
                    'Enhancing Accessible Communication',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            _sectionHeader('Application Overview'),
            _paragraph(
              'AssistMe is an accessibility-focused application designed to facilitate communication for individuals with speech, vision, or mobility impairments. The platform integrates multiple communication modalities and safety features to promote independence and accessibility.',
            ),

            _sectionHeader('Core Features'),
            _bullet('Multi-modal communication (text, voice, symbols)'),
            _bullet('Voice command recognition and speech synthesis'),
            _bullet('Emergency alert system with GPS location sharing'),
            _bullet('Customizable user profiles for personalized experiences'),
            _bullet('Secure cloud synchronization across devices'),

            _sectionHeader('Technical Specifications'),
            _bullet('Built with Flutter framework for cross-platform compatibility'),
            _bullet('Firebase backend for real-time data synchronization'),
            _bullet('Material Design 3 compliant interface'),
            _bullet('Accessibility-optimized UI components'),

            _sectionHeader('Development Team'),
            ...teamMembers.map((member) => _developer(
              context,
              member['name']!,
              member['role']!,
              email: member['email'],
              github: member['github']!.isNotEmpty ? member['github'] : null,
              linkedin: member['linkedin']!.isNotEmpty ? member['linkedin'] : null,
            )),

            _sectionHeader('Version Information'),
            _paragraph('Current Version: 1.0.0 (Stable)\nRelease Date: June 5, 2025'),

            _sectionHeader('Acknowledgements'),
            _paragraph(
              'We extend our gratitude to the open-source community and the following technologies that made this project possible:\n\n'
              '• Flutter & Dart\n• Firebase Services\n• Google Maps API\n• Material Design Components\n• TTS/STT Libraries',
            ),

            const SizedBox(height: 30),
            Center(
              child: Text(
                '© 2025 AssistMe | All Rights Reserved',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget _paragraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, height: 1.6),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.circle, size: 8, color: Colors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _developer(
    BuildContext context,
    String name, 
    String role, 
    {String? email, String? github, String? linkedin}
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, size: 24, color: Colors.black54),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    role,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (email != null || github != null || linkedin != null)
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (email != null)
                    _contactChip(
                      icon: Icons.email,
                      label: 'Email',
                      onTap: () => _launchEmail(context, email),
                    ),
                  if (github != null)
                    _contactChip(
                      icon: Icons.code,
                      label: 'GitHub',
                      onTap: () => _launchUrl(context, 'https://github.com/$github'),
                    ),
                  if (linkedin != null)
                    _contactChip(
                      icon: Icons.work,
                      label: 'LinkedIn',
                      onTap: () => _launchUrl(context, 'https://linkedin.com/in/$linkedin'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _contactChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.teal[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.teal[800]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.teal[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $url')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching URL: $e')),
        );
      }
    }
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final uri = Uri.parse('mailto:$email');
    try {
      if (!await launchUrl(uri)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch email client')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching email: $e')),
        );
      }
    }
  }
}
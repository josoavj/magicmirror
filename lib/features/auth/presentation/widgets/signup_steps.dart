import 'package:flutter/material.dart';
import 'package:magicmirror/features/auth/presentation/widgets/auth_ui_components.dart';

class SignupAccountStep extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const SignupAccountStep({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  State<SignupAccountStep> createState() => _SignupAccountStepState();
}

class _SignupAccountStepState extends State<SignupAccountStep> {
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 6),
          AuthTextField(
            controller: widget.emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: widget.passwordController,
            label: 'Mot de passe',
            obscureText: !_showPassword,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: widget.confirmPasswordController,
            label: 'Confirmer mot de passe',
            obscureText: !_showConfirmPassword,
            suffixIcon: IconButton(
              onPressed:
                  () => setState(() => _showConfirmPassword = !_showConfirmPassword),
              icon: Icon(
                _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SignupProfileStep extends StatelessWidget {
  final TextEditingController displayNameController;
  final TextEditingController avatarUrlController;
  final String gender;
  final DateTime? birthDate;
  final int heightCm;
  final VoidCallback onPickAvatar;
  final VoidCallback onPickBirthDate;
  final Function(String?) onGenderChanged;
  final Function(double) onHeightChanged;
  final bool isLoading;

  const SignupProfileStep({
    super.key,
    required this.displayNameController,
    required this.avatarUrlController,
    required this.gender,
    this.birthDate,
    required this.heightCm,
    required this.onPickAvatar,
    required this.onPickBirthDate,
    required this.onGenderChanged,
    required this.onHeightChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final birthDateLabel =
        birthDate == null
            ? 'Choisir une date'
            : '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}';

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onPickAvatar,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Importer une photo'),
            ),
          ),
          const SizedBox(height: 10),
          AuthTextField(
            controller: displayNameController,
            label: 'Nom affiché',
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: avatarUrlController,
            label: 'Photo (URL)',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: gender,
            dropdownColor: const Color(0xFF1A1A1A),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Sexe',
              labelStyle: const TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
            items:
                ['Femme', 'Homme', 'Non binaire', 'Non précise']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
            onChanged: onGenderChanged,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onPickBirthDate,
              icon: const Icon(Icons.cake_outlined),
              label: Text(birthDateLabel),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Taille: $heightCm cm',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Slider(
            min: 120,
            max: 230,
            divisions: 110,
            value: heightCm.toDouble(),
            onChanged: isLoading ? null : onHeightChanged,
          ),
        ],
      ),
    );
  }
}

class SignupPreferenceStep extends StatelessWidget {
  final String morphology;
  final Set<String> selectedStyles;
  final Function(String?) onMorphologyChanged;
  final Function(String, bool) onStyleToggled;

  const SignupPreferenceStep({
    super.key,
    required this.morphology,
    required this.selectedStyles,
    required this.onMorphologyChanged,
    required this.onStyleToggled,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: morphology,
            dropdownColor: const Color(0xFF1A1A1A),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Morphologie',
              labelStyle: const TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
            items:
                [
                      'Silhouette non définie',
                      'Hanches et épaules équilibrées',
                      'Hanches plus marquées',
                      'Silhouette droite',
                      'Épaules plus larges',
                      'Épaules très marquées',
                      'Taille très marquée',
                      'Hanches très marquées',
                    ]
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
            onChanged: onMorphologyChanged,
          ),
          const SizedBox(height: 14),
          const Text(
            'Styles vestimentaires',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                      'Casual',
                      'Elegant',
                      'Sport',
                      'Streetwear',
                      'Business',
                      'Minimaliste',
                    ]
                    .map((style) {
                      final selected = selectedStyles.contains(style);
                      return FilterChip(
                        label: Text(style),
                        selected: selected,
                        onSelected: (val) => onStyleToggled(style, val),
                      );
                    })
                    .toList(),
          ),
        ],
      ),
    );
  }
}

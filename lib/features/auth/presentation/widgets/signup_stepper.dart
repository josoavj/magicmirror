import 'package:flutter/material.dart';

class SignupStepper extends StatelessWidget {
  final PageController pageController;
  final int currentStep;
  final List<Widget> steps;
  final List<String> stepTitles;

  const SignupStepper({
    super.key,
    required this.pageController,
    required this.currentStep,
    required this.steps,
    required this.stepTitles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStepProgress(),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            stepTitles[currentStep],
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: PageView(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: steps,
          ),
        ),
      ],
    );
  }

  Widget _buildStepProgress() {
    return Row(
      children: List.generate(steps.length, (index) {
        final active = index <= currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            margin: EdgeInsets.only(right: index == steps.length - 1 ? 0 : 8),
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: active
                  ? Colors.cyanAccent
                  : Colors.white.withValues(alpha: 0.2),
            ),
          ),
        );
      }),
    );
  }
}

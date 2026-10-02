import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalDetailsText extends StatelessWidget {
  const LegalDetailsText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    final linkStyle = bodyStyle?.copyWith(
      color: Theme.of(context).colorScheme.primary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in text.split('\n'))
          if (line.contains('github.com/josoavj'))
            _LinkLine(
              text: line,
              uri: Uri.parse('https://github.com/josoavj'),
              style: linkStyle,
            )
          else if (line.contains('+261 33 60 223 60'))
            _LinkLine(
              text: line,
              uri: Uri.parse('tel:+261336022360'),
              style: linkStyle,
            )
          else
            Text(line, style: bodyStyle),
      ],
    );
  }
}

class _LinkLine extends StatelessWidget {
  const _LinkLine({required this.text, required this.uri, required this.style});

  final String text;
  final Uri uri;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(text, style: style),
      ),
    );
  }
}

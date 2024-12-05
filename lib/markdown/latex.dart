import "package:markdown/markdown.dart";
import "package:flutter/material.dart" hide Element;
import "package:flutter_math_fork/flutter_math.dart";
import "package:flutter_markdown/flutter_markdown.dart";

class LatexElementBuilder extends MarkdownElementBuilder {
  final TextStyle? textStyle;
  final double? textScaleFactor;

  LatexElementBuilder({
    this.textStyle,
    this.textScaleFactor,
  });

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final String text = element.textContent.trim();
    if (text.isEmpty) return const SizedBox();

    final mathStyle = switch (element.attributes["MathStyle"]) {
      "display" => MathStyle.display,
      _ => MathStyle.text,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.antiAlias,
      child: Math.tex(
        text,
        mathStyle: mathStyle,
        textStyle: textStyle,
        textScaleFactor: textScaleFactor,
      ),
    );
  }
}

class _LatexDelimiter {
  final String left;
  final String right;
  final bool display;

  const _LatexDelimiter({
    required this.left,
    required this.right,
    required this.display,
  });
}

class LatexInlineSyntax extends InlineSyntax {
  static const _delimiters = [
    _LatexDelimiter(left: r"$$", right: r"$$", display: true),
    _LatexDelimiter(left: r"$", right: r"$", display: false),
    _LatexDelimiter(left: r"\[", right: r"\]", display: true),
    _LatexDelimiter(left: r"\(", right: r"\)", display: false),
    _LatexDelimiter(left: r"\ce{", right: "}", display: false),
    _LatexDelimiter(left: r"\pu{", right: "}", display: false),
  ];

  static String _buildPattern() => _delimiters.map((d) {
        final right = RegExp.escape(d.right);
        final left = RegExp.escape(d.left);
        return "$left([\\s\\S]+?)$right";
      }).join("|");

  LatexInlineSyntax() : super(_buildPattern());

  @override
  bool onMatch(InlineParser parser, Match match) {
    final fullMatch = match[0]!;

    final delimiter = _delimiters.firstWhere(
      (d) => fullMatch.startsWith(d.left) && fullMatch.endsWith(d.right),
      orElse: () => _delimiters[1],
    );

    final content = fullMatch.substring(
      delimiter.left.length,
      fullMatch.length - delimiter.right.length,
    );

    final text = Element.text("latex", content)
      ..attributes["MathStyle"] = delimiter.display ? "display" : "text";

    parser.addNode(text);
    return true;
  }
}

class LatexBlockSyntax extends BlockSyntax {
  static final dollarPattern = RegExp(r"^\$\$\s*$");
  static final bracketPattern = RegExp(r"^\\\[\s*$");
  static final endDollarPattern = RegExp(r"^\$\$\s*$");
  static final endBracketPattern = RegExp(r"^\\\]\s*$");

  @override
  RegExp get pattern => RegExp(r"^\$\$|^\\\[");

  @override
  bool canParse(BlockParser parser) {
    return dollarPattern.hasMatch(parser.current.content) ||
        bracketPattern.hasMatch(parser.current.content);
  }

  @override
  Node parse(BlockParser parser) {
    final lines = <String>[];
    final start = parser.current.content;
    final isDollar = dollarPattern.hasMatch(start);

    parser.advance();

    while (!parser.isDone) {
      final line = parser.current.content;
      if ((isDollar && endDollarPattern.hasMatch(line)) ||
          (!isDollar && endBracketPattern.hasMatch(line))) {
        parser.advance();
        break;
      }
      lines.add(line);
      parser.advance();
    }

    final text = Element.text("latex", lines.join("\n").trim());
    text.attributes["MathStyle"] = "display";
    return Element("p", [text]);
  }
}

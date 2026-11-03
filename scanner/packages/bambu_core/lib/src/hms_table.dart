import 'dart:convert';

/// A tabela de erros HMS do BMCU, gerada no repositorio bmcu-guide
/// (`data/hms-bmcu.json`). O app nao conhece nenhum erro por conta propria:
/// tudo vem daqui, para que corrigir uma explicacao nao exija versao nova.
class HmsTable {
  HmsTable._({
    required this.problems,
    required this.codes,
    required this.latestVersion,
    required this.latestLabel,
    required this.latestUrl,
    required this.notApplicableKeywords,
    required this.notApplicableText,
    required this.fallbackByModule,
    required this.generated,
  });

  factory HmsTable.parse(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final version = json['bmcu_version'] as Map<String, dynamic>;
    final notApplicable = json['not_applicable'] as Map<String, dynamic>;
    final problems = {
      for (final p in json['problems'] as List)
        (p as Map<String, dynamic>)['id'] as String: HmsProblem.fromJson(p),
    };
    final codes = <String, HmsCodeEntry>{};
    (json['codes'] as Map<String, dynamic>).forEach((code, value) {
      final v = value as Map<String, dynamic>;
      codes[code] = HmsCodeEntry(
        problem: problems[v['problem']]!,
        possible: v['confidence'] == 'possible',
        official: Map<String, String>.from(v['official'] as Map),
      );
    });
    return HmsTable._(
      problems: problems,
      codes: codes,
      latestVersion: BmcuVersion.parse(version['latest'] as String),
      latestLabel: version['latest_label'] as String,
      latestUrl: version['latest_url'] as String,
      notApplicableKeywords:
          List<String>.from(notApplicable['keywords'] as List),
      notApplicableText: Map<String, String>.from(notApplicable['text'] as Map),
      fallbackByModule: {
        for (final e in (json['fallback'] as Map<String, dynamic>).entries)
          e.key: Map<String, String>.from(e.value as Map),
      },
      generated: json['generated'] as String?,
    );
  }

  final Map<String, HmsProblem> problems;
  final Map<String, HmsCodeEntry> codes;
  final BmcuVersion latestVersion;
  final String latestLabel;
  final String latestUrl;
  final List<String> notApplicableKeywords;
  final Map<String, String> notApplicableText;
  final Map<String, Map<String, String>> fallbackByModule;
  final String? generated;

  /// O que a tabela sabe sobre um codigo de 16 (HMS) ou 8 (erro) digitos.
  HmsLookup lookup(String ecode) {
    final code = ecode.toUpperCase().replaceAll('_', '');
    final entry = codes[code];
    if (entry != null) {
      return entry.possible
          ? HmsPossible(entry.problem, entry.official)
          : HmsKnown(entry.problem, entry.official);
    }
    final fallback = fallbackByModule[code.substring(0, 2)];
    if (fallback != null) return HmsGenericAms(fallback);
    return const HmsUnknown();
  }

  /// Erro oficial que fala de uma peca que o BMCU nao tem. So da para saber
  /// com o texto oficial em maos, que o app busca da Bambu quando o codigo
  /// nao esta na tabela.
  bool isNotApplicable(String officialEnglish) => notApplicableKeywords.any(
        (k) => officialEnglish.toLowerCase().contains(k.toLowerCase()),
      );

  /// Problemas conhecidos da versao instalada que uma atualizacao resolve.
  List<HmsProblem> bugsFixedAfter(BmcuVersion installed) => [
        for (final p in problems.values)
          if (p.fixedIn != null &&
              installed < p.fixedIn! &&
              (p.affected.isEmpty || p.affected.contains(installed)))
            p,
      ];
}

class HmsProblem {
  const HmsProblem({
    required this.id,
    required this.category,
    required this.severity,
    required this.printers,
    required this.sources,
    required this.text,
    this.fixedIn,
    this.affected = const [],
  });

  factory HmsProblem.fromJson(Map<String, dynamic> json) => HmsProblem(
        id: json['id'] as String,
        category: json['category'] as String,
        severity: HmsSeverity.values.byName(json['severity'] as String),
        printers: List<String>.from(json['printers'] as List),
        sources: List<int>.from(json['sources'] as List),
        fixedIn: json['bmcu_fixed_in'] == null
            ? null
            : BmcuVersion.parse(json['bmcu_fixed_in'] as String),
        affected: [
          for (final v in json['bmcu_affected'] as List? ?? const [])
            BmcuVersion.parse(v as String),
        ],
        text: {
          for (final e in (json['text'] as Map<String, dynamic>).entries)
            e.key: ProblemText.fromJson(e.value as Map<String, dynamic>),
        },
      );

  final String id;

  /// expected, config, calibration, feeding, hardware, firmware-bug...
  final String category;
  final HmsSeverity severity;
  final List<String> printers;

  /// Numeros das issues do BMCU-C-PJARCZAK de onde veio a explicacao.
  final List<int> sources;
  final BmcuVersion? fixedIn;
  final List<BmcuVersion> affected;
  final Map<String, ProblemText> text;

  bool get expected => category == 'expected';

  /// A tabela escreve os modelos como texto livre ("A1 mini >= 01.08.00.00",
  /// "P1S/P1P >= ...", "X1C 01.09-01.11", "all"). Aqui so o nome conta: a
  /// faixa de firmware fica para a pessoa ler.
  bool appliesTo(String model) {
    if (printers.isEmpty) return true;
    for (final entry in printers) {
      final names = entry
          .replaceAll(RegExp(r'\s*[<>]=.*$'), '')
          .replaceAll(RegExp(r'\s+\d.*$'), '')
          .split('/');
      for (final name in names) {
        final n = name.trim();
        if (n == 'all' || n == model) return true;
      }
    }
    return false;
  }

  /// Texto no idioma pedido, caindo para o ingles.
  ProblemText textFor(String lang) => text[lang] ?? text['en']!;
}

enum HmsSeverity { info, warning, blocking }

class ProblemText {
  const ProblemText({
    required this.title,
    required this.meaning,
    required this.steps,
  });

  factory ProblemText.fromJson(Map<String, dynamic> json) => ProblemText(
        title: json['title'] as String,
        meaning: json['meaning'] as String,
        steps: List<String>.from(json['steps'] as List),
      );

  final String title;
  final String meaning;
  final List<String> steps;
}

class HmsCodeEntry {
  const HmsCodeEntry({
    required this.problem,
    required this.possible,
    required this.official,
  });

  final HmsProblem problem;
  final bool possible;
  final Map<String, String> official;
}

sealed class HmsLookup {
  const HmsLookup();
}

/// Codigo confirmado nas issues.
class HmsKnown extends HmsLookup {
  const HmsKnown(this.problem, this.official);

  final HmsProblem problem;
  final Map<String, String> official;
}

/// Codigo que pode ser este problema, mas ninguem copiou o codigo exato.
class HmsPossible extends HmsLookup {
  const HmsPossible(this.problem, this.official);

  final HmsProblem problem;
  final Map<String, String> official;
}

/// Erro de AMS sem explicacao especifica para BMCU.
class HmsGenericAms extends HmsLookup {
  const HmsGenericAms(this.text);

  final Map<String, String> text;
}

class HmsUnknown extends HmsLookup {
  const HmsUnknown();
}

/// Versao do BMCU normalizada como major.minor (10.5, 11.0).
class BmcuVersion implements Comparable<BmcuVersion> {
  const BmcuVersion(this.major, this.minor);

  /// Aceita '10.5' (da tabela) e o sw_ver da impressora ('10.50.00.00').
  ///
  /// O BMCU manda quatro bytes que a impressora mostra invertidos. Da V10 em
  /// diante o primeiro campo e a versao e o segundo e a casa decimal vezes 10.
  /// As V6 a V9 mandavam a versao vezes 10 no primeiro campo (V9 = 90.00).
  static BmcuVersion parse(String value) {
    final parts = value.split('.').map(int.parse).toList();
    final major = parts[0];
    final minor = parts.length > 1 ? parts[1] : 0;
    if (parts.length == 4) {
      if (major >= 60 && minor == 0) return BmcuVersion(major ~/ 10, 0);
      return BmcuVersion(major, minor ~/ 10);
    }
    return BmcuVersion(major, minor);
  }

  final int major;
  final int minor;

  @override
  int compareTo(BmcuVersion other) =>
      major != other.major ? major - other.major : minor - other.minor;

  bool operator <(BmcuVersion other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is BmcuVersion && other.major == major && other.minor == minor;

  @override
  int get hashCode => Object.hash(major, minor);

  /// Como o projeto chama as versoes: V10.5, v11.
  @override
  String toString() => minor == 0 ? 'v$major' : 'V$major.$minor';
}

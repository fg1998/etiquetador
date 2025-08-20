enum Refrigeracao {
  ambiente,
  refrigerado,
  congelado;

  static Refrigeracao fromAny(dynamic v) {
    if (v == null) return Refrigeracao.ambiente;
    if (v is bool) return v ? Refrigeracao.refrigerado : Refrigeracao.ambiente;
    final s = v.toString().toLowerCase().trim();
    switch (s) {
      case 'refrigerado':
      case 'frio':
      case 'geladeira':
      case 'true':
        return Refrigeracao.refrigerado;
      case 'congelado':
      case 'freezer':
        return Refrigeracao.congelado;
      case 'ambiente':
      case 'false':
      default:
        return Refrigeracao.ambiente;
    }
  }

  String get asString {
    switch (this) {
      case Refrigeracao.ambiente:
        return 'ambiente';
      case Refrigeracao.refrigerado:
        return 'refrigerado';
      case Refrigeracao.congelado:
        return 'congelado';
    }
  }
}

class Item {
  String nome;
  int dias;
  Refrigeracao refrigeracao;

  Item({required this.nome, required this.dias, required this.refrigeracao});

  factory Item.fromJson(Map<String, dynamic> j) {
    // tolera chaves com acento / valores booleanos antigos
    final ref = j['refrigeracao'] ?? j['refrigeração'] ?? j['refrige'];
    return Item(
      nome: (j['nome'] ?? '').toString(),
      dias: int.tryParse(j['dias'].toString()) ?? 0,
      refrigeracao: Refrigeracao.fromAny(ref),
    );
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'dias': dias,
        'refrigeracao': refrigeracao.asString,
      };

  Item copyWith({String? nome, int? dias, Refrigeracao? refrigeracao}) => Item(
        nome: nome ?? this.nome,
        dias: dias ?? this.dias,
        refrigeracao: refrigeracao ?? this.refrigeracao,
      );
}
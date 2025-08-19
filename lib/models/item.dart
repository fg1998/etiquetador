class Item {
  String nome;
  int dias;
  bool refrigeracao;

  Item({required this.nome, required this.dias, required this.refrigeracao});

  factory Item.fromJson(Map<String, dynamic> j) {
    // tolera chaves com acento
    final ref = j['refrigeracao'] ?? j['refrigeração'] ?? j['refrige'];
    return Item(
      nome: (j['nome'] ?? '').toString(),
      dias: int.tryParse(j['dias'].toString()) ?? 0,
      refrigeracao: ref is bool ? ref : (ref.toString() == 'true'),
    );
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'dias': dias,
        'refrigeracao': refrigeracao,
      };

  Item copyWith({String? nome, int? dias, bool? refrigeracao}) => Item(
        nome: nome ?? this.nome,
        dias: dias ?? this.dias,
        refrigeracao: refrigeracao ?? this.refrigeracao,
      );
}

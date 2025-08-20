import 'package:flutter/material.dart';
import '../models/item.dart';

class ProductCard extends StatelessWidget {
  final Item item;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onPrint;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDuplicate,
    required this.onPrint,
    required this.onDelete,
  });

  String _refrigLinha(Item it) {
    switch (it.refrigeracao) {
      case Refrigeracao.refrigerado:
        return 'Necessita refrigeração';
      case Refrigeracao.congelado:
        return 'Necessita congelamento';
      case Refrigeracao.ambiente:
      default:
        return 'Temperatura ambiente';
    }
  }

  Color _refrigCor(Item it) {
    return it.refrigeracao == Refrigeracao.ambiente
        ? Colors.grey[700]!
        : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do produto
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nome,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.dias} dias',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                    ),
                    Text(
                      _refrigLinha(item),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            color: _refrigCor(item),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),

            // Ações
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 1,
                    runSpacing: 8,
                    children: [
                      IconButton(
                        tooltip: "Editar",
                        onPressed: onEdit,
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: Colors.blueAccent,
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      IconButton(
                        tooltip: "Duplicar",
                        onPressed: onDuplicate,
                        icon: const Icon(
                          Icons.control_point_duplicate_rounded,
                          color: Colors.blueAccent,
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      IconButton(
                        tooltip: "Imprimir",
                        onPressed: onPrint,
                        icon: const Icon(
                          Icons.local_print_shop_rounded,
                          color: Colors.blueAccent,
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remover',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

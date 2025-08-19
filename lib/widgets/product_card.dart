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

  @override
  Widget build(BuildContext context) {
    final label =
        '${item.nome}  •  ${item.dias} dias  •  ${item.refrigeracao ? "com refrigeração" : "sem refrigeração"}';

    // Em telas bem estreitas, encurta os rótulos dos botões
    final isNarrow = MediaQuery.of(context).size.width < 360;
    final lblEditar = isNarrow ? 'Editar' : 'Editar';
    final lblDuplicar = isNarrow ? 'Duplicar' : 'Duplicar';
    final lblImprimir = isNarrow ? 'Imprimir' : 'Imprimir';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome do produto
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
                    if (item.refrigeracao)
                      Text(
                        'Necessita refrigeração',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w500),
                      ),
                  ],
                ),

                const SizedBox(height: 1)
              ],
            ),

            // ====== AÇÕES ======
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A Wrap agora está dentro de um Expanded para poder quebrar linha
                Expanded(
                  child: Wrap(
                    spacing: 1,
                    runSpacing: 8, // espaço entre linhas quando quebrar
                    children: [
                      IconButton(
                        tooltip: "Editar",
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded,
                            color: Colors.blueAccent),
                        constraints:
                            const BoxConstraints(), // não força tamanho
                        padding: EdgeInsets.zero, // compacto
                      ),
                      IconButton(
                        tooltip: "Duplicar",
                        onPressed: onDuplicate,
                        icon: const Icon(Icons.control_point_duplicate_rounded,
                            color: Colors.blueAccent),
                        constraints:
                            const BoxConstraints(), // não força tamanho
                        padding: EdgeInsets.zero, // compacto
                      ),
                      IconButton(
                        tooltip: "Imprimir",
                        onPressed: onPrint,
                        icon: const Icon(Icons.local_print_shop_rounded,
                            color: Colors.blueAccent),
                        constraints:
                            const BoxConstraints(), // não força tamanho
                        padding: EdgeInsets.zero, // compacto
                      ),
                    ],
                  ),
                ),

                // Lixeira compacta à direita
                IconButton(
                  tooltip: 'Remover',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent),
                  constraints: const BoxConstraints(), // não força tamanho
                  padding: EdgeInsets.zero, // compacto
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ChipIcon(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: primary.withOpacity(.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // não expande
          children: [
            Icon(icon, size: 18, color: primary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: primary)),
          ],
        ),
      ),
    );
  }
}

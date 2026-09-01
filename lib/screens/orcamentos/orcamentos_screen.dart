import 'package:flutter/material.dart';

class OrcamentosScreen extends StatefulWidget {
  const OrcamentosScreen({super.key});

  @override
  State<OrcamentosScreen> createState() => _OrcamentosScreenState();
}

class _OrcamentosScreenState extends State<OrcamentosScreen> {
  final List<_Orcamento> _orcamentos = <_Orcamento>[];

  Future<void> _criarOrcamento() async {
    final nomeController = TextEditingController();
    final valorController = TextEditingController();

    final orcamento = await showDialog<_Orcamento>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Novo orçamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: nomeController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Cliente ou evento'),
            ),
            TextField(
              controller: valorController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Valor',
                prefixText: 'R\$ ',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final nome = nomeController.text.trim();
              if (nome.isEmpty) return;
              final valor =
                  double.tryParse(
                    valorController.text.trim().replaceAll(',', '.'),
                  ) ??
                  0;
              Navigator.pop(
                dialogContext,
                _Orcamento(nome: nome, valor: valor, data: DateTime.now()),
              );
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    nomeController.dispose();
    valorController.dispose();
    if (orcamento != null && mounted) {
      setState(() => _orcamentos.insert(0, orcamento));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orçamentos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, '/orcamentos/orcamento_form_screen'),
        icon: const Icon(Icons.add),
        label: const Text('Novo orçamento'),
      ),
      body: _orcamentos.isEmpty
          ? const Center(child: Text('Nenhum orçamento cadastrado.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _orcamentos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _orcamentos[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.receipt_long),
                    ),
                    title: Text(item.nome),
                    subtitle: Text('Criado em ${_dataFormatada(item.data)}'),
                    trailing: Text(
                      'R\$ ${item.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _dataFormatada(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
}

class _Orcamento {
  const _Orcamento({
    required this.nome,
    required this.valor,
    required this.data,
  });

  final String nome;
  final double valor;
  final DateTime data;
}

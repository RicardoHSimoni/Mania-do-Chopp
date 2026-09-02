import 'package:flutter/material.dart';

import '../../models/orcamento.dart';
import '../../services/orcamento_service.dart';

class OrcamentosScreen extends StatefulWidget {
  const OrcamentosScreen({super.key});

  @override
  State<OrcamentosScreen> createState() => _OrcamentosScreenState();
}

class _OrcamentosScreenState extends State<OrcamentosScreen> {
  late OrcamentoService _orcamentoService;

  @override
  void initState() {
    super.initState();
    _orcamentoService = OrcamentoService();
  }

  Future<void> _excluirOrcamento(
    BuildContext context,
    String orcamentoId,
  ) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: const Text('Deseja realmente excluir este orçamento?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmacao == true && mounted) {
      try {
        await _orcamentoService.excluirOrcamento(orcamentoId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Orçamento excluído com sucesso')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
        }
      }
    }
  }

  void _exibirDetalhes(BuildContext context, Orcamento orcamento) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Detalhes do Orçamento',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (orcamento.cliente != null) ...[
                      _construirDetalhe('Cliente', orcamento.cliente!.nome),
                      _construirDetalhe('Email', orcamento.cliente!.email),
                      _construirDetalhe(
                        'Telefone',
                        orcamento.cliente!.telefone,
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'Produtos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...orcamento.produtos.asMap().entries.map((entry) {
                      final produto = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    produto.nome,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'R\$ ${produto.preco.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const Divider(height: 24),
                    _construirDetalhe(
                      'Total',
                      'R\$ ${orcamento.valorTotal.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(
                                context,
                                '/orcamentos/orcamento_update_screen',
                                arguments: orcamento,
                              );
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Editar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _excluirOrcamento(context, orcamento.id!);
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Excluir'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _construirDetalhe(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
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
      body: StreamBuilder<List<Orcamento>>(
        stream: _orcamentoService.listarOrcamentos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar orçamentos: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final orcamentos = snapshot.data ?? [];

          if (orcamentos.isEmpty) {
            return const Center(child: Text('Nenhum orçamento cadastrado.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orcamentos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final orcamento = orcamentos[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                  title: Text(
                    orcamento.cliente?.nome ?? 'Sem cliente',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${orcamento.produtos.length} produto(s)'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'R\$ ${orcamento.valorTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _exibirDetalhes(context, orcamento),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/recolha.dart';
import '../../services/recolha_service.dart';

class RecolhaDetalheScreen extends StatefulWidget {
  final Recolha recolha;

  const RecolhaDetalheScreen({super.key, required this.recolha});

  @override
  State<RecolhaDetalheScreen> createState() => _RecolhaDetalheScreenState();
}

class _RecolhaDetalheScreenState extends State<RecolhaDetalheScreen> {
  final _recolhaService = RecolhaService();
  late Recolha _recolha;
  late TextEditingController _observacaoController;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _recolha = widget.recolha;
    _observacaoController = TextEditingController(
      text: _recolha.observacao ?? '',
    );
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  Future<void> _salvar(Recolha atualizado, String mensagemSucesso) async {
    setState(() => _salvando = true);
    try {
      await _recolhaService.atualizarRecolha(atualizado);
      if (!mounted) return;
      setState(() {
        _recolha = atualizado;
        _salvando = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensagemSucesso)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao atualizar recolha: $e')));
    }
  }

  Future<void> _alternarRecolhida(bool valor) {
    final atualizado = Recolha(
      id: _recolha.id,
      pedidoId: _recolha.pedidoId,
      endereco: _recolha.endereco,
      dataRecolha: _recolha.dataRecolha,
      recolhida: valor,
      observacao: _recolha.observacao,
    );
    return _salvar(
      atualizado,
      valor ? 'Chopeira marcada como recolhida' : 'Recolha reaberta',
    );
  }

  Future<void> _reagendar() async {
    final novaData = await showDatePicker(
      context: context,
      initialDate: _recolha.dataRecolha,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (novaData == null) return;

    final atualizado = Recolha(
      id: _recolha.id,
      pedidoId: _recolha.pedidoId,
      endereco: _recolha.endereco,
      dataRecolha: novaData,
      recolhida: _recolha.recolhida,
      observacao: _recolha.observacao,
    );
    await _salvar(atualizado, 'Recolha reagendada com sucesso');
  }

  Future<void> _salvarObservacao() {
    final atualizado = Recolha(
      id: _recolha.id,
      pedidoId: _recolha.pedidoId,
      endereco: _recolha.endereco,
      dataRecolha: _recolha.dataRecolha,
      recolhida: _recolha.recolhida,
      observacao: _observacaoController.text.trim(),
    );
    return _salvar(atualizado, 'Observação salva');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da recolha')),
      body: AbsorbPointer(
        absorbing: _salvando,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Pedido'),
                    subtitle: Text(_recolha.pedidoId),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text('Endereço de recolha'),
                    subtitle: Text(_recolha.endereco),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: const Text('Data da recolha'),
                    subtitle: Text(_formatarData(_recolha.dataRecolha)),
                    trailing: TextButton(
                      onPressed: _salvando ? null : _reagendar,
                      child: const Text('Reagendar'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                title: const Text('Chopeira recolhida'),
                subtitle: Text(_recolha.recolhida ? 'Recolhida' : 'Pendente'),
                value: _recolha.recolhida,
                onChanged: _salvando ? null : _alternarRecolhida,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Observação',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _observacaoController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Adicione uma observação...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _salvando ? null : _salvarObservacao,
                        child: const Text('Salvar observação'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

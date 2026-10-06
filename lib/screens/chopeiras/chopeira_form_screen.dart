import 'package:flutter/material.dart';

import '../../models/chopeira.dart';
import '../../models/enum_chopeira.dart';
import '../../services/chopeira_service.dart';

class ChopeiraFormScreen extends StatefulWidget {
  final Chopeira? chopeira;
  final List<Chopeira> existentes;

  const ChopeiraFormScreen({
    super.key,
    this.chopeira,
    this.existentes = const [],
  });

  @override
  State<ChopeiraFormScreen> createState() => _ChopeiraFormScreenState();
}

class _ChopeiraFormScreenState extends State<ChopeiraFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final ChopeiraService _service = ChopeiraService();

  late VoltagemChopeira _voltagem;
  late ModeloChopeira _modelo;
  late StatusChopeira _status;
  bool _salvando = false;

  bool get _editando => widget.chopeira != null;

  @override
  void initState() {
    super.initState();
    final chopeira = widget.chopeira;
    _codigoController.text = chopeira?.codigo.toString() ?? '';
    _voltagem = chopeira?.voltagem ?? VoltagemChopeira.v220;
    _modelo = chopeira?.modelo ?? ModeloChopeira.normal;
    _status = chopeira?.status ?? StatusChopeira.disponivel;
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  String _label(Object valor) {
    return switch (valor) {
      VoltagemChopeira.v110 => '110 V',
      VoltagemChopeira.v220 => '220 V',
      ModeloChopeira.grande => 'Grande',
      ModeloChopeira.normal => 'Normal',
      ModeloChopeira.gelo => 'Gelo',
      StatusChopeira.disponivel => 'Disponível',
      StatusChopeira.emUso => 'Em uso',
      StatusChopeira.manutencao => 'Manutenção',
      StatusChopeira.reservada => 'Reservada',
      _ => valor.toString().split('.').last,
    };
  }

  String? _validarCodigo(String? valor) {
    final codigo = int.tryParse(valor?.trim() ?? '');
    if (codigo == null || codigo <= 0) {
      return 'Informe um código numérico maior que zero';
    }

    final duplicado = widget.existentes.any(
      (item) => item.codigo == codigo && item.id != widget.chopeira?.id,
    );
    if (duplicado) return 'Já existe uma chopeira com este código';
    return null;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    final chopeira = Chopeira(
      id: widget.chopeira?.id ?? '',
      codigo: int.parse(_codigoController.text.trim()),
      voltagem: _voltagem,
      modelo: _modelo,
      status: _status,
    );

    try {
      if (_editando) {
        await _service.atualizarChopeira(chopeira);
      } else {
        await _service.adicionarChopeira(chopeira);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao salvar chopeira: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar chopeira' : 'Nova chopeira'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _codigoController,
              autofocus: !_editando,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Código',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
              validator: _validarCodigo,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ModeloChopeira>(
              initialValue: _modelo,
              decoration: const InputDecoration(
                labelText: 'Modelo',
                border: OutlineInputBorder(),
              ),
              items: ModeloChopeira.values
                  .map(
                    (valor) => DropdownMenuItem(
                      value: valor,
                      child: Text(_label(valor)),
                    ),
                  )
                  .toList(),
              onChanged: (valor) {
                if (valor != null) setState(() => _modelo = valor);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<VoltagemChopeira>(
              initialValue: _voltagem,
              decoration: const InputDecoration(
                labelText: 'Voltagem',
                border: OutlineInputBorder(),
              ),
              items: VoltagemChopeira.values
                  .map(
                    (valor) => DropdownMenuItem(
                      value: valor,
                      child: Text(_label(valor)),
                    ),
                  )
                  .toList(),
              onChanged: (valor) {
                if (valor != null) setState(() => _voltagem = valor);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<StatusChopeira>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: StatusChopeira.values
                  .map(
                    (valor) => DropdownMenuItem(
                      value: valor,
                      child: Text(_label(valor)),
                    ),
                  )
                  .toList(),
              onChanged: (valor) {
                if (valor != null) setState(() => _status = valor);
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _salvando ? null : _salvar,
              icon: _salvando
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _editando ? 'Salvar alterações' : 'Cadastrar chopeira',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

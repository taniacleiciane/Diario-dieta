import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Horários dos lembretes (mesmos do arquivo alarmes-agua.ics):
/// das 7h às 22h, de hora em hora, sem 13h e 20h.
const List<int> horarios = [7, 8, 9, 10, 11, 12, 14, 15, 16, 17, 18, 19, 21, 22];
const int mlPorCopo = 250;

final FlutterLocalNotificationsPlugin notificacoes =
    FlutterLocalNotificationsPlugin();

const NotificationDetails detalhes = NotificationDetails(
  android: AndroidNotificationDetails(
    'lembrete_agua',
    'Lembretes de água',
    channelDescription: 'Avisa a hora de beber um copo de água',
    importance: Importance.high,
    priority: Priority.high,
  ),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
  await notificacoes.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  runApp(const AppAgua());
}

class AppAgua extends StatelessWidget {
  const AppAgua({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Água',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1E88E5),
        useMaterial3: true,
      ),
      home: const TelaInicial(),
    );
  }
}

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  bool _ativos = false;
  bool _exatos = false;
  bool _carregando = true;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      notificacoes.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  @override
  void initState() {
    super.initState();
    _atualizarEstado();
  }

  Future<void> _atualizarEstado() async {
    final pendentes = await notificacoes.pendingNotificationRequests();
    final exatos = await _android?.canScheduleExactNotifications() ?? false;
    if (!mounted) return;
    setState(() {
      _ativos = pendentes.length >= horarios.length;
      _exatos = exatos;
      _carregando = false;
    });
  }

  /// Próxima ocorrência de [hora]:00 a partir de agora.
  tz.TZDateTime _proxima(int hora) {
    final agora = tz.TZDateTime.now(tz.local);
    var data = tz.TZDateTime(tz.local, agora.year, agora.month, agora.day, hora);
    if (!data.isAfter(agora)) data = data.add(const Duration(days: 1));
    return data;
  }

  Future<void> _ativar() async {
    setState(() => _carregando = true);
    final permitido = await _android?.requestNotificationsPermission() ?? true;
    if (!permitido) {
      _aviso('Sem permissão de notificação. Libere em Configurações > Apps.');
      await _atualizarEstado();
      return;
    }
    final exatos = await _android?.canScheduleExactNotifications() ?? false;
    final modo = exatos
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await notificacoes.cancelAll();
    for (final hora in horarios) {
      await notificacoes.zonedSchedule(
        id: hora,
        title: '💧 Hora da água',
        body: 'Beba 1 copo ($mlPorCopo mL)',
        scheduledDate: _proxima(hora),
        notificationDetails: detalhes,
        androidScheduleMode: modo,
        matchDateTimeComponents: DateTimeComponents.time, // repete todo dia
      );
    }
    _aviso('Lembretes ativados: ${horarios.length} por dia.');
    await _atualizarEstado();
  }

  Future<void> _desativar() async {
    await notificacoes.cancelAll();
    _aviso('Lembretes desativados.');
    await _atualizarEstado();
  }

  Future<void> _pedirHorarioExato() async {
    await _android?.requestExactAlarmsPermission();
    await _atualizarEstado();
    if (_exatos && _ativos) await _ativar(); // reagenda no modo exato
  }

  Future<void> _testar() async {
    await _android?.requestNotificationsPermission();
    await notificacoes.show(
      id: 999,
      title: '💧 Teste',
      body: 'Se você está vendo isto, as notificações funcionam!',
      notificationDetails: detalhes,
    );
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  String _fmt(int h) => '${h.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final totalMl = horarios.length * mlPorCopo;

    return Scaffold(
      appBar: AppBar(title: const Text('Lembrete de Água')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: _ativos ? cores.primaryContainer : cores.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          _ativos ? Icons.notifications_active : Icons.notifications_off,
                          size: 48,
                          color: cores.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _ativos ? 'Lembretes ativos' : 'Lembretes desligados',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text('${horarios.length} copos de $mlPorCopo mL · '
                            '${(totalMl / 1000).toStringAsFixed(1)} L por dia'),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _ativos ? _desativar : _ativar,
                          icon: Icon(_ativos ? Icons.stop : Icons.play_arrow),
                          label: Text(_ativos ? 'Desativar' : 'Ativar lembretes'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_ativos && !_exatos)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text('Avisos podem atrasar alguns minutos'),
                      subtitle: const Text('Toque para permitir horário exato.'),
                      onTap: _pedirHorarioExato,
                    ),
                  ),
                const SizedBox(height: 8),
                Text('Horários', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final h in horarios) Chip(label: Text(_fmt(h))),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _testar,
                  icon: const Icon(Icons.notifications),
                  label: const Text('Enviar notificação de teste'),
                ),
              ],
            ),
    );
  }
}

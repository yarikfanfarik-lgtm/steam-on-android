import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const SteamOnAndroidApp());

class SteamOnAndroidApp extends StatelessWidget {
  const SteamOnAndroidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Steam on Android',
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: const HomePage(),
    );
  }
}

class Game {
  const Game(this.name, this.id, this.description);
  final String name;
  final int id;
  final String description;
}

const games = <Game>[
  Game('Portal 2', 620, 'Головоломка от Valve'),
  Game('Terraria', 105600, 'Песочница и приключение'),
  Game('Stardew Valley', 413150, 'Ферма и RPG'),
  Game('Hades', 1145360, 'Экшен-рогалик'),
  Game('Hollow Knight', 367520, 'Метроидвания'),
  Game('Celeste', 504230, 'Платформер'),
  Game('Cuphead', 268910, 'Сложный run-and-gun'),
  Game('Undertale', 391540, 'RPG'),
  Game('Vampire Survivors', 1794680, 'Аркадный roguelite'),
  Game('Dead Cells', 588650, 'Roguelite action'),
  Game('Factorio', 427520, 'Автоматизация и строительство'),
  Game('RimWorld', 294100, 'Колония и стратегия'),
];

Future<void> openWeb(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loggedIn = false;
  Game? selectedGame;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101216),
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedGame == null ? 0 : 1,
              onDestinationSelected: (index) {
                if (index == 0) setState(() => selectedGame = null);
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.home), label: Text('Главная')),
                NavigationRailDestination(icon: Icon(Icons.videogame_asset), label: Text('Игры')),
                NavigationRailDestination(icon: Icon(Icons.gamepad), label: Text('Управление')),
              ],
            ),
            Expanded(child: selectedGame == null ? _home() : GamePage(game: selectedGame!)),
          ],
        ),
      ),
    );
  }

  Widget _home() {
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('Steam on Android'),
          actions: [
            IconButton(
              tooltip: 'Настройка управления',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ControlSettingsPage())),
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    const CircleAvatar(radius: 28, child: Icon(Icons.person)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(loggedIn ? 'Steam подключён' : 'Steam аккаунт', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(loggedIn ? 'Сессия подтверждена в браузере' : 'Вход выполняется через официальный сайт Steam'),
                    ])),
                    FilledButton.icon(
                      onPressed: () async {
                        await openWeb('https://store.steampowered.com/login/');
                        if (mounted) setState(() => loggedIn = true);
                      },
                      icon: const Icon(Icons.login),
                      label: Text(loggedIn ? 'Открыть Steam' : 'Войти'),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 18),
              Text('Игры', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text('Поддержка зависит от игры и Android-устройства. Список ниже — удобные пресеты для тестирования совместимости.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 14),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 330, mainAxisExtent: 170, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: games.length,
            itemBuilder: (_, index) => _gameCard(games[index]),
          ),
        ),
      ],
    );
  }

  Widget _gameCard(Game game) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => selectedGame = game),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.videogame_asset, size: 32),
            const Spacer(),
            Text(game.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(game.description),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.open_in_new, size: 16),
              const SizedBox(width: 6),
              Text('Открыть страницу Steam', style: Theme.of(context).textTheme.labelMedium),
            ]),
          ]),
        ),
      ),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key, required this.game});
  final Game game;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  bool controls = true;
  bool editing = false;
  double opacity = 0.68;
  double scale = 1;
  Offset wasd = const Offset(40, 150);
  Offset mouse = const Offset(0, 0);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
        child: Container(
          color: const Color(0xFF050608),
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.desktop_windows, size: 64),
            const SizedBox(height: 14),
            Text(widget.game.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Игровой runtime ещё не подключён'),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => openWeb('https://store.steampowered.com/app/${widget.game.id}/'),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Открыть игру в Steam'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _info(),
              icon: const Icon(Icons.info_outline),
              label: const Text('Как будет работать запуск'),
            ),
          ])),
        ),
      ),
      if (controls) _buildControls(),
      Positioned(top: 10, right: 10, child: Row(children: [
        IconButton.filledTonal(onPressed: () => setState(() => editing = !editing), icon: Icon(editing ? Icons.check : Icons.edit)),
        IconButton.filledTonal(onPressed: () => setState(() => controls = !controls), icon: Icon(controls ? Icons.visibility : Icons.visibility_off)),
      ])),
    ]);
  }

  Widget _buildControls() {
    final buttonSize = 52 * scale;
    return Stack(children: [
      Positioned(
        left: wasd.dx,
        bottom: 36 + wasd.dy,
        child: _draggable(
          Offset.zero,
          Container(
            width: buttonSize * 3,
            height: buttonSize * 2.1,
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: opacity), borderRadius: BorderRadius.circular(18)),
            child: Column(children: [
              _keyRow([null, 'W', null], buttonSize),
              _keyRow(['A', 'S', 'D'], buttonSize),
            ]),
          ),
        ),
      ),
      Positioned(right: 22, bottom: 30, child: Row(children: [
        _mouseButton('ЛКМ', buttonSize, true),
        const SizedBox(width: 10),
        _mouseButton('ПКМ', buttonSize, false),
      ])),
      Positioned(right: 18, top: 90, child: Column(children: [
        _smallKey('Esc', buttonSize),
        _smallKey('E', buttonSize),
        _smallKey('Space', buttonSize),
      ])),
      if (editing)
        Positioned(left: 16, top: 12, child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: .78), borderRadius: BorderRadius.circular(12)),
          child: Padding(padding: const EdgeInsets.all(10), child: Text('Режим редактирования: перетаскивай WASD и кнопки мыши')),
        )),
    ]);
  }

  Widget _keyRow(List<String?> keys, double size) => Row(mainAxisSize: MainAxisSize.min, children: keys.map((key) => key == null ? SizedBox(width: size, height: size) : _key(key, size)).toList());

  Widget _key(String label, double size) => Padding(padding: const EdgeInsets.all(2), child: _draggable(Offset.zero, Container(width: size - 4, height: size - 4, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white.withValues(alpha: opacity), borderRadius: BorderRadius.circular(12)), child: Text(label, style: TextStyle(color: Colors.black, fontSize: math.max(12, size * .27), fontWeight: FontWeight.bold)))));

  Widget _smallKey(String label, double size) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _key(label, size * .86));

  Widget _mouseButton(String label, double size, bool left) => GestureDetector(
    onLongPress: editing ? () {} : null,
    child: Container(width: size * 1.25, height: size, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.black.withValues(alpha: opacity), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24)), child: Text(label)),
  );

  Widget _draggable(Offset offset, Widget child) {
    if (!editing) return child;
    return GestureDetector(
      onPanUpdate: (details) => setState(() => wasd += details.delta),
      child: child,
    );
  }

  void _info() {
    showDialog<void>(context: context, builder: (_) => AlertDialog(
      title: const Text('Архитектура запуска'),
      content: const Text('После подключения compatibility runtime приложение сможет хранить Windows-контейнеры, запускать Steam-клиент и передавать ему сенсорные события как мышь/клавиатуру. Сейчас этот экран — безопасная UI-оболочка, а не эмулятор Windows.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Понятно'))],
    ));
  }
}

class ControlSettingsPage extends StatefulWidget {
  const ControlSettingsPage({super.key});

  @override
  State<ControlSettingsPage> createState() => _ControlSettingsPageState();
}

class _ControlSettingsPageState extends State<ControlSettingsPage> {
  double opacity = .68;
  double size = 52;
  bool mouseButtons = true;
  bool wasd = true;
  bool extra = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройка управления')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Размер кнопок: ${size.round()} px'),
        Slider(min: 32, max: 96, value: size, onChanged: (v) => setState(() => size = v)),
        Text('Прозрачность: ${(opacity * 100).round()}%'),
        Slider(min: .15, max: 1, value: opacity, onChanged: (v) => setState(() => opacity = v)),
        SwitchListTile(title: const Text('WASD'), value: wasd, onChanged: (v) => setState(() => wasd = v)),
        SwitchListTile(title: const Text('ЛКМ / ПКМ'), value: mouseButtons, onChanged: (v) => setState(() => mouseButtons = v)),
        SwitchListTile(title: const Text('Space / Shift / Ctrl / E / Esc'), value: extra, onChanged: (v) => setState(() => extra = v)),
        const SizedBox(height: 12),
        const Text('Положение отдельных элементов меняется непосредственно на игровом экране в режиме ✎. Настройки сохраняются на время работы приложения.'),
      ]),
    );
  }
}

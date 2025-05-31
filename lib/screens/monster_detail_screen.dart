import 'package:flutter/material.dart';
import '../data/monsters_data.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';

// Colores personalizados
const parchmentBackground = Color(0xFFF4E4BC);
const parchmentDark = Color(0xFFE4D5B7);
const parchmentBorder = Color(0xFFBE8B42);
const textColor = Color(0xFF4A3728);
const healthGreen = Color(0xFF2E7D32);
const healthOrange = Color(0xFFD84315);
const healthRed = Color(0xFFC62828);

class CircularMenuItem extends StatelessWidget {
  final int value;
  final VoidCallback onTap;
  final double angle;
  final double distance;

  const CircularMenuItem({
    super.key,
    required this.value,
    required this.onTap,
    required this.angle,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final x = math.cos(angle) * distance;
    final y = math.sin(angle) * distance;

    return Transform.translate(
      offset: Offset(x, y),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.red[700],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class D20Button extends StatelessWidget {
  final int value;
  final ValueChanged<int> onValueSelected;

  const D20Button({
    super.key,
    required this.value,
    required this.onValueSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 160,
      decoration: BoxDecoration(
        color: parchmentDark.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: parchmentBorder, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 40,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: parchmentBorder, width: 1),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: value,
                dropdownColor: parchmentDark,
                icon: const Icon(Icons.arrow_drop_down, color: textColor, size: 20),
                isDense: true,
                isExpanded: true,
                alignment: AlignmentDirectional.center,
                items: List.generate(100, (index) => index + 1)
                    .map((number) => DropdownMenuItem(
                          value: number,
                          alignment: AlignmentDirectional.center,
                          child: Text(
                            number.toString(),
                            style: const TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    onValueSelected(newValue);
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: ListWheelScrollView(
              itemExtent: 40,
              diameterRatio: 1.5,
              useMagnifier: true,
              magnification: 1.5,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) => onValueSelected(index + 1),
              controller: FixedExtentScrollController(initialItem: value - 1),
              children: List.generate(
                100,
                (index) => Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == index + 1 ? parchmentBorder.withOpacity(0.3) : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    (index + 1).toString(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: value == index + 1 ? 18 : 16,
                      fontWeight: value == index + 1 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class D20Painter extends CustomPainter {
  final int value;

  D20Painter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red[700] ?? Colors.red
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final path = Path();
    for (var i = 0; i < 20; i++) {
      final angle = (i * 2 * math.pi / 20) - math.pi / 2;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: value.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MonsterDetailScreen extends StatefulWidget {
  const MonsterDetailScreen({super.key});

  @override
  State<MonsterDetailScreen> createState() => _MonsterDetailScreenState();
}

class _MonsterDetailScreenState extends State<MonsterDetailScreen> {
  late List<MonsterData> monsters;
  late PageController _pageController;
  Map<int, int> diceValues = {};
  Map<int, int> currentHPs = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    monsters = monstersData;

    for (int i = 0; i < monsters.length; i++) {
      diceValues[i] = 1;
      currentHPs[i] = monsters[i].monster.hitPoints;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _modifyHP(bool increase, int monsterIndex) {
    setState(() {
      final monster = monsters[monsterIndex].monster;
      final previousHP = currentHPs[monsterIndex] ?? monster.hitPoints;
      final diceValue = diceValues[monsterIndex] ?? 1;

      if (increase) {
        currentHPs[monsterIndex] = (previousHP + diceValue).clamp(0, monster.hitPoints);
      } else {
        final damage = diceValue - monster.armorClass;
        if (damage > 0) {
          currentHPs[monsterIndex] = (previousHP - damage).clamp(0, monster.hitPoints);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Golpe exitoso: $diceValue vs AC ${monster.armorClass}\n'
                'Daño realizado: $damage',
                style: const TextStyle(fontSize: 16),
              ),
              backgroundColor: healthRed,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ataque fallido: $diceValue vs AC ${monster.armorClass}',
                style: const TextStyle(fontSize: 16),
              ),
              backgroundColor: Colors.grey[700],
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
      
      if (previousHP > 0 && currentHPs[monsterIndex] == 0) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: parchmentDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: parchmentBorder, width: 2),
              ),
              title: Text(
                '¡${monster.name} Ha Muerto!',
                style: const TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: const Icon(
                Icons.block,
                color: textColor,
                size: 64,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      currentHPs[monsterIndex] = monster.hitPoints;
                      diceValues[monsterIndex] = 1;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Reiniciar',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    });
  }

  Widget _buildStatBlock(String label, int value) {
    return Card(
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 24,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '(${monsters[0].monster.getModifier(value) >= 0 ? '+' : ''}${monsters[0].monster.getModifier(value)})',
              style: const TextStyle(
                fontSize: 16,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonsterPage(int index) {
    final monsterData = monsters[index];
    final monster = monsterData.monster;
    final currentHP = currentHPs[index] ?? monster.hitPoints;
    final diceValue = diceValues[index] ?? 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text(
                    monster.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: currentHP / monster.hitPoints,
                          backgroundColor: parchmentBackground,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            currentHP < monster.hitPoints * 0.25 ? healthRed : 
                            currentHP < monster.hitPoints * 0.5 ? healthOrange : 
                            healthGreen,
                          ),
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$currentHP/${monster.hitPoints}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        monsterData.imagePath,
                        height: 260,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 260,
                            color: parchmentDark,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: textColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'D100: ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            D20Button(
                              value: diceValue,
                              onValueSelected: (value) {
                                setState(() {
                                  diceValues[index] = value;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(
                          color: parchmentBorder,
                          thickness: 1,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              onPressed: () => _modifyHP(false, index),
                              icon: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF8C8C8C),
                                      Color(0xFF636363),
                                      Color(0xFF4A4A4A),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF2E2E2E),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                    const BoxShadow(
                                      color: Colors.white24,
                                      offset: Offset(-1, -1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                              iconSize: 40,
                            ),
                            const SizedBox(width: 24,height: 24,),
                            IconButton(
                              onPressed: () => _modifyHP(true, index),
                              icon: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF8C8C8C),
                                      Color(0xFF636363),
                                      Color(0xFF4A4A4A),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF2E2E2E),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                    const BoxShadow(
                                      color: Colors.white24,
                                      offset: Offset(-1, -1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                              iconSize: 40,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text(
                'Clase de Armadura',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Text(
                monster.armorClass.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text(
                'Puntos de Vida',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: LinearProgressIndicator(
                value: currentHP / monster.hitPoints,
                backgroundColor: parchmentBackground,
                valueColor: AlwaysStoppedAnimation<Color>(
                  currentHP < monster.hitPoints * 0.25 ? healthRed : 
                  currentHP < monster.hitPoints * 0.5 ? healthOrange : 
                  healthGreen,
                ),
              ),
              trailing: Text(
                '$currentHP/${monster.hitPoints}',
                style: const TextStyle(
                  fontSize: 18,
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _buildStatBlock('FUERZA', monster.strength),
              _buildStatBlock('DESTREZA', monster.dexterity),
              _buildStatBlock('CONSTITUCIÓN', monster.constitution),
              _buildStatBlock('INTELIGENCIA', monster.intelligence),
              _buildStatBlock('SABIDURÍA', monster.wisdom),
              _buildStatBlock('CARISMA', monster.charisma),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Características',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.height, color: textColor),
                      const SizedBox(width: 8),
                      Text(
                        'Tamaño: ${monster.size}',
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.category, color: textColor),
                      const SizedBox(width: 8),
                      Text(
                        'Tipo: ${monster.type}',
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.balance, color: textColor),
                      const SizedBox(width: 8),
                      Text(
                        'Alineamiento: ${monster.alignment}',
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: parchmentDark,
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: textColor),
              SizedBox(width: 8),
              Text(
                'Acerca de',
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'DM Companion Bosses',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Versión 1.0.0',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Una aplicación para ayudar a los Dungeon Masters a gestionar los monstruos y jefes en sus partidas de D&D.',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Licencia',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Dungeons & Dragons es una marca registrada de Wizards of the Coast LLC.\n\n'
                  'Esta aplicación es un proyecto fan-made y no está afiliada oficialmente con Wizards of the Coast.\n\n'
                  'Las estadísticas de los monstruos están basadas en el SRD (System Reference Document) bajo la Open Game License v1.0a.',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Desarrollador',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vibe coding por Javert Galicia',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
                InkWell(
                  onTap: () => _launchURL('https://jgalicia.com'),
                  child: Text(
                    'Para mayor info: https://jgalicia.com',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Asistente de Desarrollo',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Desarrollado con la asistencia de Claude 3.5 Sonnet\nUn modelo de lenguaje de Anthropic\nEjecutado en Cursor IDE',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: parchmentBorder, width: 2),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cerrar',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "DM Companion Bosses",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: textColor),
            onPressed: () => _showAboutDialog(context),
            tooltip: 'Acerca de',
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: parchmentDark,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: monsters.length,
          itemBuilder: (context, index) {
            final monster = monsters[index].monster;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: parchmentBackground,
                child: Text(
                  monster.name[0],
                  style: const TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                monster.name,
                style: const TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monster.type,
                    style: const TextStyle(
                      color: textColor,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.favorite, size: 14, color: healthRed),
                      const SizedBox(width: 4),
                      Text(
                        monster.hitPoints.toString(),
                        style: const TextStyle(
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.shield, size: 14, color: textColor),
                      const SizedBox(width: 4),
                      Text(
                        monster.armorClass.toString(),
                        style: const TextStyle(
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              isThreeLine: true,
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/pergamino.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: PageView.builder(
          controller: _pageController,
          itemBuilder: (context, index) {
            final realIndex = index % monsters.length;
            return _buildMonsterPage(realIndex);
          },
          onPageChanged: (index) {
            setState(() {
              if (index > monsters.length * 100 || index < -monsters.length * 100) {
                _pageController.jumpToPage(index % monsters.length);
              }
            });
          },
        ),
      ),
    );
  }
}

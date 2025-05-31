class Monster {
  final String name;
  final int armorClass;
  final int hitPoints;
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;
  final int charisma;
  final String size;
  final String type;
  final String alignment;

  Monster({
    required this.name,
    required this.armorClass,
    required this.hitPoints,
    required this.strength,
    required this.dexterity,
    required this.constitution,
    required this.intelligence,
    required this.wisdom,
    required this.charisma,
    required this.size,
    required this.type,
    required this.alignment,
  });

  int getModifier(int stat) {
    return (stat - 10) ~/ 2;
  }
}

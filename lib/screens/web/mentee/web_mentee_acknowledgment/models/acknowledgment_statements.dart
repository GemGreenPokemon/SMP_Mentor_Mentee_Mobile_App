class AcknowledgmentStatement {
  final String text;
  final String icon;
  
  const AcknowledgmentStatement({
    required this.text,
    this.icon = '✓',
  });
}

class AcknowledgmentStatements {
  static const List<AcknowledgmentStatement> checklistItems = [
    AcknowledgmentStatement(
      text: 'Understand program expectations',
    ),
    AcknowledgmentStatement(
      text: 'Acknowledge orientation completion',
    ),
    AcknowledgmentStatement(
      text: 'Confirm WCONLINE registration',
    ),
    AcknowledgmentStatement(
      text: 'Accept program guidelines',
    ),
  ];

  static const List<String> agreementStatements = [
    'I acknowledge that I have watched and attended the Mentee Orientation and understand how to achieve and maintain "Active Status" in the program each semester.',
    'I understand that if I end my program membership or take a brief leave, I must submit the Mentee Leave form.',
    'I will register for the Success Mentor Program in WCONLINE using the steps presented in Orientation and will use the SMP WCONLINE portal to book and edit appointments with my mentor(s).',
    'I also acknowledge that SMP mentors are fellow students—just as they respect my time and boundaries, I will respect theirs—and that they follow FERPA guidelines and are mandated reporters (for more information, see UC Merced\'s FERPA page).',
  ];
}
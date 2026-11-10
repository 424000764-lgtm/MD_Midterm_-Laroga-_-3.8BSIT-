const List<String> myAnswers = [
  '# SCENARIO 1: normal flow',
  '1', 'Dart Basics', '1', '2', '20',
  '1', 'Flutter Workshop', '3', '1', '35.50',
  '2', 'Ana Cruz', '2',
  '2', 'Ben Reyes', '1',
  '3', 'MEM-001', 'RES-001', '5',
  '5',
  '# SCENARIO 2: lending rules, return, report',
  '3', 'MEM-002', 'RES-002', '2',
  '3', 'MEM-001', 'RES-002', '1',
  '4', 'TXN-001',
  '9',
  '# SCENARIO 3: invalid input',
  'abc', '15', '',
  '1', '', 'Python Course',
  'x', '9', '2',
  '0', 'ten', '5',
  '-5', 'free', '15',
  '3', 'MEM-999',
  '3', 'MEM-001', 'RES-999',
  '3', 'MEM-001', 'RES-001', '45', '3',
  '4', 'TXN-999',
  '8',
  '0',
];

mixin Auditable {
  DateTime? _createdAt;

  void markCreated() {
    _createdAt = DateTime.now();
  }

  String get createdStamp {
    final DateTime? t = _createdAt;
    if (t == null) {
      return 'N/A';
    }
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}';
  }
}

enum MemberTier {
  standard('Standard', 0.0, 2),
  premium('Premium', 0.20, 4);

  final String label;
  final double discount;
  final int loanLimit;

  const MemberTier(this.label, this.discount, this.loanLimit);

  String get discountText => '${(discount * 100).toStringAsFixed(0)}%';
}

class IdGenerator {
  static final Map<String, int> _counters = {};

  static String next(String prefix) {
    final int number = (_counters[prefix] ?? 0) + 1;
    _counters[prefix] = number;
    return '$prefix-${number.toString().padLeft(3, '0')}';
  }
}

class FeeBreakdown {
  final double gross;
  final double discount;

  const FeeBreakdown(this.gross, this.discount);

  double get net => gross - discount;
}

FeeBreakdown calculateFee(double dailyRate, int days, MemberTier tier) {
  final double gross = dailyRate * days;
  return FeeBreakdown(gross, gross * tier.discount);
}

abstract class CenterEntity with Auditable {
  final String _id;

  CenterEntity(this._id) {
    markCreated();
  }

  String get id => _id;

  String get kind;

  String headline();

  Map<String, String> detailRows();
}

class Resource extends CenterEntity {
  String _title;
  final String _category;
  final int _totalCopies;
  int _availableCopies;
  double _dailyRate;

  Resource({
    required String title,
    required String category,
    required int copies,
    required double dailyRate,
  })  : _title = title,
        _category = category,
        _totalCopies = copies,
        _availableCopies = copies,
        _dailyRate = dailyRate,
        super(IdGenerator.next('RES'));

  String get title => _title;
  String get category => _category;
  int get totalCopies => _totalCopies;
  int get availableCopies => _availableCopies;
  double get dailyRate => _dailyRate;

  set title(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('Title cannot be empty.');
    }
    _title = value.trim();
  }

  set dailyRate(double value) {
    if (value < 0) {
      throw ArgumentError('Rate cannot be negative.');
    }
    _dailyRate = value;
  }

  bool takeCopy() {
    if (_availableCopies == 0) {
      return false;
    }
    _availableCopies--;
    return true;
  }

  void restoreCopy() {
    if (_availableCopies < _totalCopies) {
      _availableCopies++;
    }
  }

  @override
  String get kind => 'Resource';

  @override
  String headline() => '$_title ($_category)';

  @override
  Map<String, String> detailRows() => {
        'Resource ID': id,
        'Title': _title,
        'Category': _category,
        'In stock': '$_availableCopies of $_totalCopies',
        'Daily rate': peso(_dailyRate),
        'Added': createdStamp,
      };
}

class Member extends CenterEntity {
  String _name;
  final MemberTier _tier;
  int _activeLoans = 0;

  Member(String name, MemberTier tier)
      : _name = name,
        _tier = tier,
        super(IdGenerator.next('MEM'));

  String get name => _name;
  MemberTier get tier => _tier;
  int get activeLoans => _activeLoans;
  int get loanLimit => _tier.loanLimit;
  bool get canBorrow => _activeLoans < _tier.loanLimit;

  set name(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('Name cannot be empty.');
    }
    _name = value.trim();
  }

  void openLoan() {
    _activeLoans++;
  }

  void closeLoan() {
    if (_activeLoans > 0) {
      _activeLoans--;
    }
  }

  @override
  String get kind => 'Member';

  @override
  String headline() => '$_name - ${_tier.label} tier';

  @override
  Map<String, String> detailRows() => {
        'Member ID': id,
        'Name': _name,
        'Tier': '${_tier.label} (${_tier.discountText} discount)',
        'Active loans': '$_activeLoans of ${_tier.loanLimit}',
        'Enrolled': createdStamp,
      };
}

class LoanRecord extends CenterEntity {
  final String _memberId;
  final String _resourceId;
  final int _days;
  final FeeBreakdown _fee;
  bool _closed = false;

  LoanRecord({
    required String memberId,
    required String resourceId,
    required int days,
    required FeeBreakdown fee,
  })  : _memberId = memberId,
        _resourceId = resourceId,
        _days = days,
        _fee = fee,
        super(IdGenerator.next('TXN'));

  String get memberId => _memberId;
  String get resourceId => _resourceId;
  int get days => _days;
  FeeBreakdown get fee => _fee;
  bool get isClosed => _closed;
  String get statusText => _closed ? 'RETURNED' : 'ACTIVE';

  void close() {
    _closed = true;
  }

  @override
  String get kind => 'Loan';

  @override
  String headline() => '$_memberId -> $_resourceId for $_days day(s)';

  @override
  Map<String, String> detailRows() => {
        'Loan ID': id,
        'Member': _memberId,
        'Resource': _resourceId,
        'Duration': '$_days day(s)',
        'Amount due': peso(_fee.net),
        'Status': statusText,
        'Issued': createdStamp,
      };
}

class CenterRepository {
  final Map<String, Resource> _resources = {};
  final Map<String, Member> _members = {};
  final List<LoanRecord> _loans = [];

  bool get hasResources => _resources.isNotEmpty;
  bool get hasMembers => _members.isNotEmpty;
  bool get hasOpenLoans => _loans.any((LoanRecord l) => !l.isClosed);

  void saveResource(Resource r) => _resources[r.id] = r;
  void saveMember(Member m) => _members[m.id] = m;
  void saveLoan(LoanRecord l) => _loans.add(l);

  Resource? findResource(String rawId) => _resources[_clean(rawId)];
  Member? findMember(String rawId) => _members[_clean(rawId)];

  LoanRecord? findOpenLoan(String rawId) {
    final String wanted = _clean(rawId);
    for (final LoanRecord loan in _loans) {
      if (loan.id == wanted && !loan.isClosed) {
        return loan;
      }
    }
    return null;
  }

  List<Resource> get resources => _resources.values.toList();
  List<Member> get members => _members.values.toList();
  List<LoanRecord> get loans => List.of(_loans);

  List<CenterEntity> get everything => [
        ..._resources.values,
        ..._members.values,
        ..._loans,
      ];

  int get openLoanCount => _loans.where((LoanRecord l) => !l.isClosed).length;

  double get totalRevenue =>
      _loans.fold<double>(0.0, (double sum, LoanRecord l) => sum + l.fee.net);

  Map<String, int> get categoryCounts {
    final Map<String, int> counts = {};
    for (final Resource r in _resources.values) {
      counts[r.category] = (counts[r.category] ?? 0) + 1;
    }
    return counts;
  }

  static String _clean(String raw) => raw.trim().toUpperCase();
}

class LoanOutcome {
  final LoanRecord? loan;
  final String message;

  const LoanOutcome.accepted(LoanRecord this.loan, this.message);
  const LoanOutcome.refused(this.message) : loan = null;

  bool get success => loan != null;
}

class LendingDesk {
  final CenterRepository _repo;

  LendingDesk(this._repo);

  LoanOutcome checkOut(Member member, Resource resource, int days) {
    if (!member.canBorrow) {
      return LoanOutcome.refused('${member.name} reached the '
          '${member.tier.label} limit of ${member.loanLimit} active loans.');
    }
    if (!resource.takeCopy()) {
      return LoanOutcome.refused('"${resource.title}" is out of stock.');
    }
    final LoanRecord loan = LoanRecord(
      memberId: member.id,
      resourceId: resource.id,
      days: days,
      fee: calculateFee(resource.dailyRate, days, member.tier),
    );
    _repo.saveLoan(loan);
    member.openLoan();
    return LoanOutcome.accepted(loan, 'Loan approved.');
  }

  LoanOutcome checkIn(LoanRecord loan) {
    loan.close();
    _repo.findResource(loan.resourceId)?.restoreCopy();
    _repo.findMember(loan.memberId)?.closeLoan();
    return LoanOutcome.accepted(loan, 'Return recorded.');
  }
}

String peso(double amount) => 'PHP ${amount.toStringAsFixed(2)}';

int maxOf(int a, int b) => a > b ? a : b;

String renderTable(List<String> headers, List<List<String>> rows) {
  final List<int> widths = [for (final String h in headers) h.length];
  for (final List<String> row in rows) {
    for (int i = 0; i < row.length; i++) {
      widths[i] = maxOf(widths[i], row[i].length);
    }
  }

  String rule() => '+${widths.map((int w) => '-' * (w + 2)).join('+')}+';
  String line(List<String> cells) {
    final List<String> parts = [];
    for (int i = 0; i < cells.length; i++) {
      parts.add(' ${cells[i].padRight(widths[i])} ');
    }
    return '|${parts.join('|')}|';
  }

  final StringBuffer out = StringBuffer()
    ..writeln(rule())
    ..writeln(line(headers))
    ..writeln(rule());
  for (final List<String> row in rows) {
    out.writeln(line(row));
  }
  out.write(rule());
  return out.toString();
}

String renderCard(String title, Map<String, String> fields) {
  int keyWidth = 0;
  for (final String key in fields.keys) {
    keyWidth = maxOf(keyWidth, key.length);
  }
  final List<String> body = [
    for (final MapEntry<String, String> e in fields.entries)
      '${e.key.padRight(keyWidth)} : ${e.value}',
  ];

  int inner = title.length;
  for (final String text in body) {
    inner = maxOf(inner, text.length);
  }
  inner += 2;

  final int left = (inner - title.length) ~/ 2;
  final int right = inner - title.length - left;
  final String heavy = '+${'=' * inner}+';
  final StringBuffer out = StringBuffer()
    ..writeln(heavy)
    ..writeln('|${' ' * left}$title${' ' * right}|')
    ..writeln(heavy);
  for (final String text in body) {
    out.writeln('| ${text.padRight(inner - 2)} |');
  }
  out.write(heavy);
  return out.toString();
}

void printHeading(String text) {
  print('\n>> $text');
  print('-' * (text.length + 3));
}

void ok(String message) => print('  [OK] $message');
void warn(String message) => print('  [!]  $message');
void note(String message) => print('  [i]  $message');

class InputExhausted implements Exception {}

class ConsoleReader {
  final List<String> _answers;
  int _cursor = 0;

  ConsoleReader(this._answers);

  String ask(String prompt) {
    while (_cursor < _answers.length && _answers[_cursor].startsWith('#')) {
      print('\n############ ${_answers[_cursor].substring(1).trim()} ############');
      _cursor++;
    }
    if (_cursor >= _answers.length) {
      throw InputExhausted();
    }
    final String answer = _answers[_cursor++].trim();
    print('  > $prompt${answer.isEmpty ? '<empty>' : answer}');
    return answer;
  }

  String askText(String prompt) {
    while (true) {
      final String answer = ask(prompt);
      if (answer.isNotEmpty) {
        return answer;
      }
      warn('This field cannot be left empty.');
    }
  }

  int askInt(String prompt, {required int min, required int max}) {
    while (true) {
      final String answer = ask(prompt);
      try {
        final int value = int.parse(answer);
        if (value >= min && value <= max) {
          return value;
        }
        warn('Enter a number between $min and $max.');
      } on FormatException {
        warn('"$answer" is not a whole number.');
      }
    }
  }

  double askAmount(String prompt) {
    while (true) {
      final String answer = ask(prompt);
      try {
        final double value = double.parse(answer);
        if (!value.isNaN && !value.isInfinite && value >= 0) {
          return value;
        }
        warn('Amount must be 0 or more.');
      } on FormatException {
        warn('"$answer" is not a valid amount (example: 25 or 12.50).');
      }
    }
  }
}

class CenterApp {
  static const List<String> _categories = [
    'Book',
    'Course',
    'Workshop',
    'Equipment',
  ];

  final CenterRepository _repo = CenterRepository();
  late final LendingDesk _desk = LendingDesk(_repo);
  final ConsoleReader _in;

  CenterApp(this._in);

  void run() {
    _printTitle();
    bool running = true;

    try {
      while (running) {
        _printMenu();
        final String choice = _in.ask('Select an option (0-9): ');

        if (choice.isEmpty) {
          warn('No option entered. Please choose a number from 0 to 9.');
          continue;
        }

        try {
          switch (choice) {
            case '1':
              _addResource();
            case '2':
              _enrollMember();
            case '3':
              _checkOut();
            case '4':
              _checkIn();
            case '5':
              _showResources();
            case '6':
              _showMembers();
            case '7':
              _showLoans();
            case '8':
              _showEverything();
            case '9':
              _showReport();
            case '0':
              running = false;
            default:
              warn('"$choice" is not on the menu. Choose 0 to 9.');
          }
        } on InputExhausted {
          rethrow;
        } catch (e) {
          warn('Unexpected problem: $e');
          note('Returning to the main menu.');
        }
      }
    } on InputExhausted {
      print('\n[Answers finished - exiting.]');
    }

    print('\nThank you for using the Community Learning Center system.');
    print('Goodbye!\n');
  }

  void _printTitle() {
    print(renderCard('COMMUNITY LEARNING CENTER', {
      'System': 'Resource & Member Management',
      'Currency': 'Philippine peso (PHP)',
    }));
  }

  void _printMenu() {
    print(renderTable(['Key', 'Action'], [
      ['1', 'Add learning resource'],
      ['2', 'Enroll member'],
      ['3', 'Check out a resource'],
      ['4', 'Check in (return)'],
      ['5', 'List resources'],
      ['6', 'List members'],
      ['7', 'List loans'],
      ['8', 'All records'],
      ['9', 'Center report'],
      ['0', 'Exit'],
    ]));
  }

  void _addResource() {
    printHeading('Add Learning Resource');
    final String title = _in.askText('Title: ');

    for (int i = 0; i < _categories.length; i++) {
      print('      ${i + 1}) ${_categories[i]}');
    }
    final int pick =
        _in.askInt('Category: ', min: 1, max: _categories.length);
    final int copies = _in.askInt('Copies (1-100): ', min: 1, max: 100);
    final double rate = _in.askAmount('Rate per day (PHP): ');

    final Resource resource = Resource(
      title: title,
      category: _categories[pick - 1],
      copies: copies,
      dailyRate: rate,
    );
    _repo.saveResource(resource);
    ok('Resource saved.');
    print(renderCard('NEW RESOURCE', resource.detailRows()));
  }

  void _enrollMember() {
    printHeading('Enroll Member');
    final String name = _in.askText('Full name: ');

    for (int i = 0; i < MemberTier.values.length; i++) {
      final MemberTier t = MemberTier.values[i];
      print('      ${i + 1}) ${t.label} - ${t.discountText} discount, '
          'up to ${t.loanLimit} loans');
    }
    final int pick =
        _in.askInt('Tier: ', min: 1, max: MemberTier.values.length);

    final Member member = Member(name, MemberTier.values[pick - 1]);
    _repo.saveMember(member);
    ok('Member enrolled.');
    print(renderCard('NEW MEMBER', member.detailRows()));
  }

  void _checkOut() {
    printHeading('Check Out a Resource');
    if (!_repo.hasMembers || !_repo.hasResources) {
      warn('Enroll a member and add a resource before checking out.');
      return;
    }

    _printMemberTable();
    final Member? member =
        _repo.findMember(_in.askText('Member ID (e.g., MEM-001): '));
    if (member == null) {
      warn('No such member. Check-out cancelled.');
      return;
    }

    _printResourceTable();
    final Resource? resource =
        _repo.findResource(_in.askText('Resource ID (e.g., RES-001): '));
    if (resource == null) {
      warn('No such resource. Check-out cancelled.');
      return;
    }

    final int days = _in.askInt('Days to borrow (1-30): ', min: 1, max: 30);

    final LoanOutcome outcome = _desk.checkOut(member, resource, days);
    final LoanRecord? loan = outcome.loan;
    if (loan == null) {
      warn('${outcome.message} Check-out not completed.');
      return;
    }

    ok(outcome.message);
    print(renderCard('BORROW RECEIPT', {
      'Receipt no.': loan.id,
      'Member': '${member.name} (${member.tier.label})',
      'Resource': resource.title,
      'Rate': '${peso(resource.dailyRate)} x $days day(s)',
      'Subtotal': peso(loan.fee.gross),
      'Discount': '- ${peso(loan.fee.discount)} (${member.tier.discountText})',
      'AMOUNT DUE': peso(loan.fee.net),
      'Issued': loan.createdStamp,
    }));
  }

  void _checkIn() {
    printHeading('Check In a Resource');
    if (!_repo.hasOpenLoans) {
      note('There are no active loans to return.');
      return;
    }

    _printLoanTable();
    final LoanRecord? loan =
        _repo.findOpenLoan(_in.askText('Loan ID to return (e.g., TXN-001): '));
    if (loan == null) {
      warn('No active loan has that ID.');
      return;
    }

    final LoanOutcome outcome = _desk.checkIn(loan);
    ok(outcome.message);
    print(renderCard('RETURN SLIP', loan.detailRows()));
  }

  void _showResources() {
    printHeading('Learning Resources');
    _printResourceTable();
  }

  void _showMembers() {
    printHeading('Members');
    _printMemberTable();
  }

  void _showLoans() {
    printHeading('Loans');
    _printLoanTable();
  }

  void _showEverything() {
    printHeading('All Records');
    final List<CenterEntity> items = _repo.everything;
    if (items.isEmpty) {
      note('Nothing has been recorded yet.');
      return;
    }
    print(renderTable(
      ['Type', 'ID', 'Description', 'Created'],
      [
        for (final CenterEntity e in items)
          [e.kind, e.id, e.headline(), e.createdStamp],
      ],
    ));
    print('${items.length} record(s) in total.');
  }

  void _showReport() {
    printHeading('Center Report');
    print(renderCard('SUMMARY', {
      'Resources': '${_repo.resources.length}',
      'Members': '${_repo.members.length}',
      'Loans': '${_repo.loans.length} (${_repo.openLoanCount} active)',
      'Revenue': peso(_repo.totalRevenue),
    }));

    final Map<String, int> counts = _repo.categoryCounts;
    if (counts.isEmpty) {
      note('No categories yet - add a resource first.');
      return;
    }
    print('\nResources by category:');
    print(renderTable(
      ['Category', 'Count', 'Chart'],
      [
        for (final MapEntry<String, int> e in counts.entries)
          [e.key, '${e.value}', '#' * e.value],
      ],
    ));
  }

  void _printResourceTable() {
    final List<Resource> items = _repo.resources;
    if (items.isEmpty) {
      note('No resources on file.');
      return;
    }
    print(renderTable(
      ['ID', 'Title', 'Category', 'Stock', 'Rate/day'],
      [
        for (final Resource r in items)
          [
            r.id,
            r.title,
            r.category,
            '${r.availableCopies}/${r.totalCopies}',
            peso(r.dailyRate),
          ],
      ],
    ));
  }

  void _printMemberTable() {
    final List<Member> items = _repo.members;
    if (items.isEmpty) {
      note('No members on file.');
      return;
    }
    print(renderTable(
      ['ID', 'Name', 'Tier', 'Discount', 'Loans'],
      [
        for (final Member m in items)
          [
            m.id,
            m.name,
            m.tier.label,
            m.tier.discountText,
            '${m.activeLoans}/${m.loanLimit}',
          ],
      ],
    ));
  }

  void _printLoanTable() {
    final List<LoanRecord> items = _repo.loans;
    if (items.isEmpty) {
      note('No loans recorded.');
      return;
    }
    print(renderTable(
      ['ID', 'Member', 'Resource', 'Days', 'Amount due', 'Status'],
      [
        for (final LoanRecord l in items)
          [
            l.id,
            l.memberId,
            l.resourceId,
            '${l.days}',
            peso(l.fee.net),
            l.statusText,
          ],
      ],
    ));
  }
}

void main() {
  CenterApp(ConsoleReader(myAnswers)).run();
}

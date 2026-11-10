# Community Learning Center Management System

**Name:** _Your Full Name_
**Section:** _Your Section_
**Course:** Mobile Development - Midterm Laboratory Examination (Weeks 7-10, CO3)

A console application written in Dart that manages learning resources, members, and borrowing transactions for a community learning center.

## Application Features

- **Add learning resource** - title, category (Book, Course, Workshop, Equipment), number of copies, daily rate
- **Enroll member** - Standard (no discount, max 2 loans) or Premium (20% discount, max 4 loans)
- **Check out a resource** - validates stock and loan limit, computes the fee (`rate x days - tier discount`), prints a borrow receipt
- **Check in (return)** - restores stock and the member's loan count, prints a return slip
- **List resources / members / loans** - bordered tables
- **All records** - one table of every record, printed through the shared parent type
- **Center report** - totals, revenue, and a resources-by-category chart
- **Input validation** - invalid menu choices, empty input, text where numbers are expected, out-of-range numbers, unknown IDs; the program never crashes

## Programming Concepts Used

| Concept | Where |
|---|---|
| Abstract class | `CenterEntity` |
| Subclasses with own implementations | `Resource`, `Member`, `LoanRecord` (`headline()`, `detailRows()`, `kind`) |
| Mixin | `Auditable` (creation timestamp) |
| Enum | `MemberTier` (label, discount, loan limit) |
| Encapsulation | private `_fields`, getters, validating setters |
| List and Map | `CenterRepository` (Maps for resources and members, List for loans); `categoryCounts` Map |
| Polymorphism | "All records" and the report loop over `List<CenterEntity>` |
| User-defined functions | `calculateFee`, `peso`, `renderTable`, `renderCard`, ... |
| Control flow | `switch` menu, `while` loop, `if/else`, `for` |
| Error handling | `try / on FormatException / catch`, `InputExhausted` |

## How to Run

This program reads from the keyboard, so it needs the Dart SDK (it will not work in DartPad, which has no keyboard input).

1. Install the Dart SDK.
2. Open a terminal in the folder that contains `main.dart`.
3. Run `dart run main.dart` (or `dart main.dart`).
4. Type a menu number and press Enter. Choose `0` to exit.

## Suggested Test Scenarios

1. **Normal flow** - add two resources, enroll two members, check out a resource, list resources.
2. **Lending rules** - check out the last copy of a resource, try to check it out again (refused), return a loan, show the report.
3. **Invalid input** - type `abc`, `15` or nothing at the menu; leave the title empty; type text or out-of-range numbers for category, copies, rate and days; use unknown IDs such as `MEM-999`.

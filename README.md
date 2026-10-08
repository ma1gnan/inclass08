# In-Class 08 / Fall Festival Roster
Deborah / CSC4360 / pathway: ~Desktop/Maignan_Deborah_InClass08/local_storage_lab

## Environment
- Flutter: 3.47.2
- Dart: 3.13.2
- Device: sdk gphone16k arm64 emulator
- Android: 17 (API 37)
- Architecture: android-arm64
- Emulator ID: emulator-5554

## Storage notes

* **Schema and initialization:** The app uses the supplied `DatabaseHelper` to initialize `MyDatabase.db` before the UI loads database records. The database contains one table, `my_table`, with `_id INTEGER PRIMARY KEY`, `name TEXT NOT NULL`, and `age INTEGER NOT NULL`. The database is opened/created by `init()` and the table is created in `_onCreate()` when needed.
* **Input policy, IDs, CRUD source locations:** Guest names must be trimmed and nonempty. Ages must be whole numbers from 0 through 130 inclusive, using `int.tryParse()`. SQLite generates the guest ID; the UI displays and uses that integer ID for Edit and Delete. Database CRUD is kept in `lib/database_helper.dart`; the interaction, validation, loading states, and rendering are handled in `lib/main.dart`. Insert returns the generated ID, while update and delete use the selected ID and report affected rows.
* **Memory example / preference example / SQLite example:** A value stored only in a Flutter widget's state, such as the current form text or selected edit ID, is in-memory state and can disappear when the app stops. A key-value preference would store a simple setting such as a theme choice. SQLite is used here for structured festival guest records because the records have separate fields (`_id`, `name`, and `age`) and need CRUD queries. The saved guest records remained after stopping and reopening the app, demonstrating local database persistence.


## Actual test

| Test                  | Action/input                                                   | Expected                                                        | Observed                                                                        | Result |
| --------------------- | -------------------------------------------------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------------------- | ------ |
| T1 — Add guest        | Added Jane Doe, age 24                                     | Guest is saved with a database-generated ID and count becomes 1 | Jane was saved as ID 1; count became 1                                          | Pass   |
| T2 — Edit guest       | Edited ID 1, changing age 24 → 25                              | Same ID remains and age changes to 25                           | ID 1 remained; age became 25; feedback: “Updated guest ID 1.”                   | Pass   |
| T3 — Add second guest | Added a second guest                                           | Second guest receives a different ID and count becomes 2        | Second guest was added successfully; count became 2                             | Pass   |
| T4 — Cancel deletion  | Opened delete confirmation and selected Cancel                 | No record is deleted                                            | Both guests remained and count stayed 2                                         | Pass   |
| T5 — Delete guest     | Confirmed deletion of the second guest                         | Selected guest is deleted; other guest remains                  | Second guest disappeared; Jane remained as ID 1, age 25; count became 1         | Pass   |
| T6 — Invalid input    | Tested blank name, blank age, non-number, decimal, -1, and 131 | Invalid input is rejected and does not create a row             | All intended validation messages appeared; invalid attempts did not add records | Pass   |
| T6 — Boundary values  | Tested ages 0 and 130                                          | Both boundary values are accepted                               | Both values were accepted and saved                                             | Pass   |
| Persistence           | Stopped and relaunched the app                                 | Previously saved records reappear with the same IDs and values  | The same saved guests and IDs appeared after reopening                          | Pass   |
| Final analysis        | Ran `flutter analyze`                                          | No analyzer errors                                              | `No issues found! (ran in 1.3s)`                                                | Pass   |


## Short reflections

### 1. Why persistence matters

The most important result was seeing the same guest records and IDs after stopping and reopening the app. This showed me that the guest data was actually stored in SQLite instead of existing only in the Flutter screen's memory. The database is appropriate because the app needs structured records with an ID, name, and age and needs to perform CRUD operations on those records. Flutter's SQLite documentation describes SQLite as a local database option for storing and querying structured data.

### 2. Why IDs matter

Using the database-generated integer ID made Edit and Delete more reliable. The app did not depend on a guest's name or position in the list to identify a record. For example, Maya remained ID 1 after her age changed from 24 to 25. The delete test also removed the selected guest while leaving Maya unchanged. This helped me understand why database operations should target a specific primary-key ID.

### 3. Why validation matters

The validation tests showed that preventing invalid input before the database write is important. Blank names, blank ages, non-numbers, decimals, -1, and 131 were rejected. Ages 0 and 130 were accepted because they are the inclusive boundaries of the required range. This means the database is only receiving values that satisfy the app's input policy.

### 4. What I learned about errors and UI state

The CRUD operations are asynchronous, so the screen needs loading/busy and error states instead of assuming every database operation succeeds immediately. The lab also showed why an empty list should only be displayed after a successful database query. A loading state, an empty result, and a database error represent different situations and should not be presented as if they mean the same thing.


## Attribution

* **Flutter SQLite documentation:** Used the official Flutter “Persist data with SQLite” cookbook as a reference for SQLite database setup and CRUD operations. [Flutter SQLite documentation](https://docs.flutter.dev/cookbook/persistence/sqlite?utm_source=claude.com)
* **sqflite package:** Used the `sqflite` Flutter package for SQLite database operations, including insert, query, update, and delete. [sqflite package on pub.dev](https://pub.dev/packages/sqflite?utm_source=claude.com)
* **Database helper:** Used the `DatabaseHelper` provided for this lab and adapted it to the application as instructed.
* **Flutter framework:** The application was developed using Flutter and Dart.
* **AI assistance:** Used Claude for troubleshooting, and guidance while completing the application. The application prediction, code and test observations were reviewed and verified by me.

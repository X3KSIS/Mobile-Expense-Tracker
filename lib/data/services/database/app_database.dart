import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Columns every synced table shares (see the Supabase migration).
mixin SyncColumns on Table {
  /// When the user made the change. The later edit wins on sync.
  DateTimeColumn get modifiedAt => dateTime()();

  /// Deleted rows are kept, marked, until the deletion has synced.
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  /// Changed here and not yet sent to the server.
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
}

@DataClassName('CategoryRow')
class Categories extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  IntColumn get color => integer()();

  /// `expense` or `income`.
  TextColumn get type => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WalletRow')
class Wallets extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// `cash`, `mobileMoney` or `bank`.
  TextColumn get kind => text()();
  RealColumn get openingBalance => real().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransferRow')
class Transfers extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get fromWalletId => text()();
  TextColumn get toWalletId => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionRow')
class Transactions extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get categoryName => text()();
  TextColumn get categoryIcon => text()();
  IntColumn get categoryColor => integer()();
  RealColumn get amount => real()();

  /// `expense` or `income`.
  TextColumn get type => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get walletId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BudgetRow')
class Budgets extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get categoryName => text()();
  TextColumn get categoryIcon => text()();
  IntColumn get categoryColor => integer()();
  RealColumn get limitAmount => real()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DetectedPaymentRow')
class DetectedPayments extends Table with SyncColumns {
  TextColumn get id => text()();

  /// The parsed `MoneyMessage` as JSON.
  TextColumn get message => text()();
  DateTimeColumn get receivedAt => dateTime()();
  TextColumn get sender => text().nullable()();

  /// `pending`, `added` or `dismissed`.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AccountLinkRow')
class AccountLinks extends Table with SyncColumns {
  /// The wallet id.
  TextColumn get id => text()();
  TextColumn get providerName => text()();
  TextColumn get accountRef => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The signed-in user's profile and settings: one row at most.
@DataClassName('ProfileRow')
class Profiles extends Table {
  TextColumn get userId => text()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get phone => text().nullable()();
  IntColumn get payday => integer().withDefault(const Constant(1))();

  /// `system`, `light` or `dark`.
  TextColumn get theme => text().withDefault(const Constant('system'))();

  /// Budgets at or above this percentage of their limit show a warning.
  IntColumn get budgetAlertPercent =>
      integer().withDefault(const Constant(80))();

  /// The wallet Add transaction picks first; null means the first wallet.
  TextColumn get defaultWalletId => text().nullable()();

  /// Whether Home shows the spending habit card.
  BoolColumn get showHabits => boolean().withDefault(const Constant(true))();

  /// Where the photo is stored on the server, or null.
  TextColumn get avatarPath => text().nullable()();

  /// The photo itself, kept here so it shows offline.
  BlobColumn get avatarBytes => blob().nullable()();

  /// The photo changed here and has not been uploaded yet.
  BoolColumn get avatarDirty => boolean().withDefault(const Constant(false))();

  /// Whether Home hides money amounts until shown.
  BoolColumn get hideAmounts => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {userId};
}

/// The server time of the newest row pulled, per table.
@DataClassName('SyncCursorRow')
class SyncCursors extends Table {
  TextColumn get tableName_ => text().named('table_name')();
  DateTimeColumn get pulledUpTo => dateTime()();

  @override
  Set<Column> get primaryKey => {tableName_};
}

/// The on-device SQLite database. It holds only the signed-in user's
/// data and is the source of truth for the UI; `SyncService` keeps it in
/// step with Supabase.
@DriftDatabase(
  tables: [
    Categories,
    Wallets,
    Transfers,
    Transactions,
    Budgets,
    DetectedPayments,
    AccountLinks,
    Profiles,
    SyncCursors,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'expense_tracker'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(profiles, profiles.budgetAlertPercent);
        await m.addColumn(profiles, profiles.defaultWalletId);
        await m.addColumn(profiles, profiles.showHabits);
        await m.addColumn(profiles, profiles.hideAmounts);
      }
      if (from < 3) {
        await m.addColumn(profiles, profiles.avatarPath);
        await m.addColumn(profiles, profiles.avatarBytes);
        await m.addColumn(profiles, profiles.avatarDirty);
      }
    },
  );

  /// Profile id used before anyone signs in (or when the app runs without
  /// a server). Its data moves to the first account that signs in.
  static const String localUserId = 'local';

  /// Tables whose rows sync one by one (everything but the profile and
  /// the sync bookkeeping).
  List<TableInfo> get syncedTables => [
    categories,
    wallets,
    transfers,
    transactions,
    budgets,
    detectedPayments,
    accountLinks,
  ];

  /// Removes everything, e.g. when the user signs out.
  Future<void> clearAll() => transaction(() async {
    for (final table in allTables) {
      await delete(table).go();
    }
  });

  /// Makes this database [userId]'s. Data from another account is
  /// removed; data kept before anyone signed in is handed to [userId] and
  /// sent up on the next sync. Creates the profile row when missing; its
  /// old date lets the server's copy win on the first sync.
  Future<ProfileRow> openAccount({
    required String userId,
    required String email,
    required String name,
    required DateTime createdAt,
  }) => transaction(() async {
    final current = await select(profiles).getSingleOrNull();
    if (current != null && current.userId != userId) {
      if (current.userId == localUserId) {
        await markAllUnsynced();
        await (update(profiles)..where((p) => p.userId.equals(localUserId)))
            .write(ProfilesCompanion(userId: Value(userId)));
      } else {
        await clearAll();
      }
    }
    final existing = await (select(
      profiles,
    )..where((p) => p.userId.equals(userId))).getSingleOrNull();
    if (existing == null) {
      await into(profiles).insert(
        ProfilesCompanion.insert(
          userId: userId,
          email: Value(email),
          name: Value(name),
          createdAt: createdAt,
          modifiedAt: DateTime.utc(2000),
          dirty: const Value(false),
        ),
      );
    } else {
      final adopted = current?.userId == localUserId;
      await (update(profiles)..where((p) => p.userId.equals(userId))).write(
        ProfilesCompanion(
          email: Value(email),
          name: adopted || existing.name.isEmpty
              ? Value(name)
              : const Value.absent(),
          createdAt: Value(createdAt),
        ),
      );
    }
    return (select(
      profiles,
    )..where((p) => p.userId.equals(userId))).getSingle();
  });

  /// Whether anything changed here has not reached the server yet.
  Future<bool> hasUnsyncedChanges() async {
    for (final table in [...syncedTables, profiles]) {
      final rows = await customSelect(
        'SELECT 1 FROM ${table.actualTableName} WHERE dirty = 1 LIMIT 1',
        readsFrom: {table},
      ).get();
      if (rows.isNotEmpty) return true;
    }
    return false;
  }

  /// Marks everything the user recorded (not the built-in defaults, which
  /// are dated 2000) as unsent, so data kept before the first sign-in
  /// goes up to the new account.
  Future<void> markAllUnsynced() => transaction(() async {
    for (final table in syncedTables) {
      await customUpdate(
        "UPDATE ${table.actualTableName} SET dirty = 1 "
        "WHERE modified_at > '2001'",
        updates: {table},
      );
    }
  });
}

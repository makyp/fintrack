/// The three kinds of movement the app records.
///
/// Lives in its own file so the category entity can depend on it without
/// importing the whole transaction entity (which in turn depends on
/// categories).
enum TransactionType { expense, income, transfer }

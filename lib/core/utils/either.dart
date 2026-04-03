/// Simple Either type for functional error handling.
/// Left = failure, Right = success.
class Either<L, R> {
  final L? _left;
  final R? _right;
  final bool _isRight;

  const Either._left(this._left)
      : _right = null,
        _isRight = false;

  const Either._right(this._right)
      : _left = null,
        _isRight = true;

  static Either<L, R> left<L, R>(L value) => Either._left(value);
  static Either<L, R> right<L, R>(R value) => Either._right(value);

  bool get isLeft => !_isRight;
  bool get isRight => _isRight;

  L get leftValue => _left as L;
  R get rightValue => _right as R;

  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) {
    if (_isRight) return onRight(_right as R);
    return onLeft(_left as L);
  }

  Either<L, T> map<T>(T Function(R value) f) {
    if (_isRight) return Either.right(f(_right as R));
    return Either.left(_left as L);
  }
}

typedef EitherFailure<R> = Either<dynamic, R>;

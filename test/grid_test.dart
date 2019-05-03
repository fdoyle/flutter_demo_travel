

import 'package:grid_experiment_1/Grid.dart';

void main() {
  GridArray array = GridArray([], [
    Fraction(),
    Fraction(),
    Fraction(),
    Fraction(),
    Fraction()
  ], Auto());
  print(array.toString());
  assert(array.isCellOccupied(0, 0));
  assert(!array.isCellOccupied(0,1));
}
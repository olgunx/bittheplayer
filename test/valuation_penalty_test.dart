import 'package:flutter_test/flutter_test.dart';

num calculateTeamValue(List<String> wonFootballers, Map<String, int> realValues, Map<String, String> footballerPositions) {
  num sum = 0;
  int strikerCount = 0;
  int midfielderCount = 0;
  int defenderCount = 0;
  for (var f in wonFootballers) {
    final val = realValues[f] ?? 50;
    final pos = footballerPositions[f] ?? 'Striker';
    
    if (pos == 'Striker') {
      strikerCount++;
      if (strikerCount > 1) {
        sum += val * 0.5;
      } else {
        sum += val;
      }
    } else if (pos == 'Center Mid' || pos == 'Winger') {
      midfielderCount++;
      if (midfielderCount > 2) {
        sum += val * 0.5;
      } else {
        sum += val;
      }
    } else if (pos == 'Center Back' || pos == 'Full Back') {
      defenderCount++;
      if (defenderCount > 2) {
        sum += val * 0.5;
      } else {
        sum += val;
      }
    } else {
      sum += val;
    }
  }
  return sum;
}

void main() {
  group('Valuation Positional Penalty Tests', () {
    test('Within limit: 1 Striker, 2 Midfielders, 2 Defenders', () {
      final footballers = ['Haaland', 'Bellingham', 'Messi', 'Van Dijk', 'Hakimi'];
      final realValues = {
        'Haaland': 90,
        'Bellingham': 80,
        'Messi': 80,
        'Van Dijk': 70,
        'Hakimi': 70,
      };
      final positions = {
        'Haaland': 'Striker',
        'Bellingham': 'Center Mid',
        'Messi': 'Winger',
        'Van Dijk': 'Center Back',
        'Hakimi': 'Full Back',
      };
      
      final total = calculateTeamValue(footballers, realValues, positions);
      expect(total, 90 + 80 + 80 + 70 + 70); // 390
    });

    test('Exceeding midfielders: 3 Midfielders (last one is discounted)', () {
      final footballers = ['Bellingham', 'Messi', 'Salah'];
      final realValues = {
        'Bellingham': 100,
        'Messi': 90,
        'Salah': 80,
      };
      final positions = {
        'Bellingham': 'Center Mid',
        'Messi': 'Winger',
        'Salah': 'Winger',
      };
      
      final total = calculateTeamValue(footballers, realValues, positions);
      // Bellingham (100) + Messi (90) + Salah (80 * 0.5 = 40)
      expect(total, 230);
    });

    test('Exceeding strikers: 2 Strikers (second one is discounted)', () {
      final footballers = ['Haaland', 'Mbappe'];
      final realValues = {
        'Haaland': 90,
        'Mbappe': 100,
      };
      final positions = {
        'Haaland': 'Striker',
        'Mbappe': 'Striker',
      };
      
      final total = calculateTeamValue(footballers, realValues, positions);
      // Haaland (90) + Mbappe (100 * 0.5 = 50)
      expect(total, 140);
    });

    test('Exceeding defenders: 3 Defenders (third one is discounted)', () {
      final footballers = ['Van Dijk', 'Hakimi', 'Dias'];
      final realValues = {
        'Van Dijk': 90,
        'Hakimi': 80,
        'Dias': 80,
      };
      final positions = {
        'Van Dijk': 'Center Back',
        'Hakimi': 'Full Back',
        'Dias': 'Center Back',
      };
      
      final total = calculateTeamValue(footballers, realValues, positions);
      // Van Dijk (90) + Hakimi (80) + Dias (80 * 0.5 = 40)
      expect(total, 210);
    });
  });
}

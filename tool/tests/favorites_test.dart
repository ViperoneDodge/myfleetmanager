import 'package:flutter_test/flutter_test.dart';
import 'package:myfleetmanager/models.dart';

void main() {
  final mine = Vehicle(id: 'a', name: 'Panda');
  final g1 = Vehicle(id: 'b', name: 'Furgone', fleetId: 'G1');
  final g2 = Vehicle(id: 'c', name: 'Trattore', fleetId: 'G1');
  final other = Vehicle(id: 'd', name: 'Moto', fleetId: 'G2');

  test('stella su un singolo veicolo', () {
    final f = Favorites();
    f.toggle(mine);
    expect(f.isFavorite(mine), true);
    expect(f.isFavorite(g1), false);
    f.toggle(mine);
    expect(f.isFavorite(mine), false);
  });

  test('gruppo intero, con un veicolo tolto a mano', () {
    final f = Favorites();
    f.toggleGroup('G1', [g1, g2]);
    expect(f.isFavorite(g1), true);
    expect(f.isFavorite(g2), true);
    expect(f.isFavorite(other), false);
    f.toggle(g2);
    expect(f.isFavorite(g2), false);
    expect(f.isFavorite(g1), true);
    f.toggle(g2);
    expect(f.isFavorite(g2), true);
    f.toggle(g2);
    f.toggleGroup('G1', [g1, g2]);
    expect(f.isFavorite(g1), false);
    f.toggleGroup('G1', [g1, g2]);
    expect(f.isFavorite(g2), true);
  });

  test('salvati e riletti, veicolo spostato di gruppo', () {
    final f = Favorites(on: true, view: HomeView.both)
      ..toggle(mine)
      ..toggleGroup('G2', [other]);
    final r = Favorites.fromJson(f.toJson());
    expect(r.on, true);
    expect(r.view, HomeView.both);
    expect(r.isFavorite(mine), true);
    expect(r.isFavorite(other), true);
    r.renamed('a', 'a2');
    expect(r.isFavorite(Vehicle(id: 'a2')), true);
    expect(Favorites.fromJson(null).on, false);
    final data = UserData.fromJson(UserData(favorites: r).toJson());
    expect(data.favorites.view, HomeView.both);
  });
}

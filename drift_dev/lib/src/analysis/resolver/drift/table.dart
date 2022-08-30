import '../../results/element.dart';
import '../../results/table.dart';
import '../intermediate_state.dart';
import '../resolver.dart';

class DriftTableResolver extends LocalElementResolver<DiscoveredDriftTable> {
  DriftTableResolver(super.discovered, super.resolver);

  @override
  Future<DriftTable> resolve() async {
    // todo: Report declaration
    return DriftTable(discovered.ownId, null);
  }
}

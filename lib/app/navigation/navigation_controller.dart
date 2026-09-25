import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_destination.dart';

final navigationControllerProvider =
    NotifierProvider<NavigationController, AppDestinationId>(
      NavigationController.new,
    );

class NavigationController extends Notifier<AppDestinationId> {
  @override
  AppDestinationId build() => AppDestinationId.home;

  void goTo(AppDestinationId destination) {
    state = destination;
  }

  void goToBottomIndex(int index) {
    final bottomDests = AppDestination.bottomNavDestinations;
    if (index >= 0 && index < bottomDests.length) {
      state = bottomDests[index].id;
    }
  }
}

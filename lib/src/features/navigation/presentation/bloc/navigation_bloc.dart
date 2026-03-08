import 'dart:async';

class NavigationBloc {
  NavigationBloc() : _controller = StreamController<int>.broadcast();

  final StreamController<int> _controller;
  int _currentIndex = 0;

  Stream<int> get stream => _controller.stream;
  int get currentIndex => _currentIndex;

  void changeTab(int index) {
    if (_currentIndex == index) {
      return;
    }

    _currentIndex = index;
    _controller.add(index);
  }

  void dispose() {
    _controller.close();
  }
}

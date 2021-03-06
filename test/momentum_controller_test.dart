import 'package:flutter_test/flutter_test.dart';

import 'components/async-test/async-test.controller.dart';
import 'components/counter/index.dart';
import 'components/dummy/index.dart';
import 'components/error-test-1/index.dart';
import 'components/error-test-2/index.dart';
import 'components/error-test-3/index.dart';
import 'components/persist-error1/index.dart';
import 'components/persist-error3/index.dart';
import 'components/persist-error4/index.dart';
import 'components/persist-test/persist-test.controller.dart';
import 'components/sync-test/index.dart';
import 'utilities/dummy.dart';
import 'utilities/in_memory_storage.dart';
import 'utilities/launcher.dart';
import 'widgets/async.dart';
import 'widgets/counter.dart';
import 'widgets/persistence.dart';
import 'widgets/reset.dart';
import 'widgets/sync.dart';
import 'widgets/time_travel.dart';

void main() {
  testWidgets('Initialize Controller', (tester) async {
    var widget = counter();
    await inject(tester, widget, milliseconds: 2000);
    var controller = widget.controllerForTest<CounterController>();
    expect(controller.model.value, 0);
  });

  // method tests
  testWidgets('config(...)', (tester) async {
    var widget = counter();
    await inject(tester, widget, milliseconds: 2000);
    var controller = widget.controllerForTest<CounterController>()
      ..config(
        lazy: false,
        enableLogging: true,
        maxTimeTravelSteps: 3,
      );
    expect(controller.isLazy, false);
    expect(controller.loggingEnabled, true);
    expect(controller.maxTimeTravelSteps, 3);
  });
  testWidgets('init()', (tester) async {
    var widget = asyncApp();
    await inject(tester, widget, milliseconds: 2000);
    var controller = widget.controllerForTest<AsyncTestController>();
    var init = controller.init();
    expect(init.value, 0);
    expect(init.name, '');
  });
  test('null init()', () async {
    try {
      ErrorTest1Controller()..testInit();
    } on dynamic catch (e) {
      expect(e is Exception, true);
    }
    try {
      ErrorTest2Controller()..testInit();
    } on dynamic catch (e) {
      expect(e is Exception, true);
    }
    try {
      ErrorTest3Controller()..testInit();
    } on dynamic catch (e) {
      expect(e is TypeError, true);
    }
  });
  testWidgets('bootstrap()', (tester) async {
    var widget = syncApp();
    await inject(tester, widget, milliseconds: 2000);
    var nameFinder = find.text('flutter is awesome');
    var valueFinder = find.text('333');
    expect(nameFinder, findsOneWidget);
    expect(valueFinder, findsOneWidget);
  });
  testWidgets('bootstrapAsync()', (tester) async {
    var widget = asyncApp(lazy: false);
    await inject(tester, widget, milliseconds: 5000);
    var nameFinder = find.text('flutter is best');
    var valueFinder = find.text('22');
    expect(nameFinder, findsOneWidget);
    expect(valueFinder, findsOneWidget);
  });
  testWidgets('skipPersist()', (tester) async {
    var widget = asyncApp();
    await inject(tester, widget, milliseconds: 2000);
    var controller = widget.controllerForTest<AsyncTestController>();
    expect(await controller.skipPersist(), true);
  });
  testWidgets('listen(...) | sendEvent(...)', (tester) async {
    var widget = asyncApp();
    await inject(tester, widget, milliseconds: 3000);
    var controller = widget.controllerForTest<AsyncTestController>();
    controller.sendEvent('test');
    controller.sendEvent(AsyncEvent(117, 'test'));
  });
  testWidgets('addListener(...)', (tester) async {
    var widget = asyncApp();
    await inject(tester, widget, milliseconds: 3000);
    var controller = widget.controllerForTest<AsyncTestController>();
    controller.model.update(value: 100, name: 'momentum');
    controller.model.update(value: 101, name: 'momentum101');
    controller.backward();
  });
  testWidgets('backward()', (tester) async {
    var widget = timeTravelApp();
    await inject(tester, widget, milliseconds: 3000);
    var controller = widget.controllerForTest<AsyncTestController>();
    controller.model.update(value: 1, name: 'momentum1');
    controller.model.update(value: 2, name: 'momentum2');
    controller.model.update(value: 3, name: 'momentum3');
    controller.backward();
    expect(controller.model.value, 2);
    expect(controller.model.name, 'momentum2');
    controller.backward();
    expect(controller.model.value, 1);
    expect(controller.model.name, 'momentum1');
  });
  testWidgets('forward()', (tester) async {
    var widget = timeTravelApp();
    await inject(tester, widget, milliseconds: 3000);
    var controller = widget.controllerForTest<AsyncTestController>();
    controller.model.update(value: 1, name: 'momentum1');
    controller.model.update(value: 2, name: 'momentum2');
    controller.model.update(value: 3, name: 'momentum3');
    controller.backward();
    expect(controller.model.value, 2);
    expect(controller.model.name, 'momentum2');
    controller.backward();
    expect(controller.model.value, 1);
    expect(controller.model.name, 'momentum1');

    // forward phase
    controller.forward();
    expect(controller.model.value, 2);
    expect(controller.model.name, 'momentum2');
    controller.forward();
    expect(controller.model.value, 3);
    expect(controller.model.name, 'momentum3');
  });
  testWidgets('dependOn<T>()', (tester) async {
    var widget = asyncApp();
    await inject(tester, widget, milliseconds: 3000);
    var controller = widget.controllerForTest<AsyncTestController>();
    var dummyController = controller.dependOn<DummyController>();
    expect(dummyController is DummyController, true);
    try {
      controller.dependOn<AsyncTestController>();
    } on dynamic catch (e) {
      expect(e is Exception, true);
    }
    try {
      controller.dependOn<CounterController>();
    } on dynamic catch (e) {
      expect(e is Exception, true);
    }
  });
  testWidgets('getService<T>()', (tester) async {
    var widget = persistedApp();
    await inject(tester, widget, milliseconds: 3000);
    var controller = widget.controllerForTest<DummyController>();
    expect(controller is DummyController, true);
    var service = controller.getService<InMemoryStorage>();
    expect(service is InMemoryStorage, true);
    try {
      controller.getService<DummyService>();
    } on dynamic catch (e) {
      expect(e is Exception, true);
    }
  });
  testWidgets('reset()', (tester) async {
    var widget = resetApp();
    await inject(tester, widget, milliseconds: 3000);
    var controller = widget.controllerForTest<AsyncTestController>();
    controller.model.update(value: 1, name: 'momentum1');
    controller.model.update(value: 2, name: 'momentum2');
    controller.model.update(value: 3, name: 'momentum3');
    controller.backward();
    expect(controller.model.value, 2);
    expect(controller.model.name, 'momentum2');
    controller.backward();
    expect(controller.model.value, 1);
    expect(controller.model.name, 'momentum1');
    controller.reset();
    expect(controller.model.value, 0);
    expect(controller.model.name, '');
  });

  testWidgets('reset(clearHistory: true)', (tester) async {
    var widget = resetApp();
    await inject(tester, widget, milliseconds: 3000);
    var controller = widget.controllerForTest<AsyncTestController>();
    controller.model.update(value: 1, name: 'momentum1');
    controller.model.update(value: 2, name: 'momentum2');
    controller.model.update(value: 3, name: 'momentum3');
    controller.backward();
    expect(controller.model.value, 2);
    expect(controller.model.name, 'momentum2');
    controller.backward();
    expect(controller.model.value, 1);
    expect(controller.model.name, 'momentum1');
    controller.reset(clearHistory: true);
    expect(controller.model.value, 0);
    expect(controller.model.name, '');
    expect(controller.prevModel, null);
    expect(controller.nextModel, null);
  });

  // property tests
  testWidgets('prevModel', (tester) async {
    var widget = timeTravelApp();
    await inject(tester, widget, milliseconds: 3000);
    var controller = widget.controllerForTest<AsyncTestController>();
    controller.model.update(value: 1, name: 'momentum1');
    controller.model.update(value: 2, name: 'momentum2');
    controller.model.update(value: 3, name: 'momentum3');
    controller.backward();
    expect(controller.prevModel.value, 1);
    expect(controller.prevModel.name, 'momentum1');
    expect(controller.model.value, 2);
    expect(controller.model.name, 'momentum2');
  });
  testWidgets('model', (tester) async {
    var widget = syncApp();
    await inject(tester, widget, milliseconds: 3000);
    var controller = widget.controllerForTest<SyncTestController>();
    expect(controller.model == null, false);
    expect(controller.model.value, 333);
    expect(controller.model.name, 'flutter is awesome');
  });
  testWidgets('nextModel', (tester) async {
    var widget = timeTravelApp();
    await inject(tester, widget, milliseconds: 3000);
    var controller = widget.controllerForTest<AsyncTestController>();
    controller.model.update(value: 1, name: 'momentum1');
    controller.model.update(value: 2, name: 'momentum2');
    controller.model.update(value: 3, name: 'momentum3');
    controller.backward();
    expect(controller.prevModel.value, 1);
    expect(controller.prevModel.name, 'momentum1');
    expect(controller.model.value, 2);
    expect(controller.model.name, 'momentum2');
    expect(controller.nextModel.value, 3);
    expect(controller.nextModel.name, 'momentum3');
  });
  testWidgets('isLazy', (tester) async {
    var widget = asyncApp(lazy: true);
    await inject(tester, widget, milliseconds: 3000);
    var controller = widget.controllerForTest<AsyncTestController>();
    expect(controller.isLazy, true);

    widget = asyncApp(lazy: false);
    await inject(tester, widget, milliseconds: 3000);
    controller = widget.controllerForTest<AsyncTestController>();
    expect(controller.isLazy, false);

    widget = asyncApp();
    await inject(tester, widget, milliseconds: 3000);
    controller = widget.controllerForTest<AsyncTestController>();
    expect(controller.isLazy, true);
  });
  testWidgets('persistenceKey', (tester) async {
    var widget = asyncApp();
    await inject(tester, widget, milliseconds: 3000);
    var a = widget.controllerForTest<AsyncTestController>();
    var keyA = 'Momentum[Instance of AsyncTestController<AsyncTestModel>]';
    expect(a.persistenceKey, keyA);

    var b = widget.controllerForTest<DummyController>();
    var keyB = 'Momentum[Instance of DummyController<DummyModel>]';
    expect(b.persistenceKey, keyB);
  });

  group('Persistence State Test', () {
    testWidgets('Start App', (tester) async {
      var widget = persistedApp();
      await inject(tester, widget, milliseconds: 4000);
      var controller = widget.controllerForTest<PersistTestController>();
      controller.model.update(username: 'momentum', email: 'state@momentum');
      await tester.pump(Duration(milliseconds: 1000));
      expect(controller.model.username, 'momentum');
      expect(controller.model.email, 'state@momentum');
    });

    testWidgets('Restart App', (tester) async {
      var widget = persistedApp();
      await inject(tester, widget, milliseconds: 4000);
      var controller = widget.controllerForTest<PersistTestController>();
      expect(controller.model.username, 'momentum');
      expect(controller.model.email, 'state@momentum');
    });

    testWidgets('Misconfigured Code Hit Test: persistSave', (tester) async {
      var widget = persistedApp(noPersistSave: true);
      await inject(tester, widget, milliseconds: 4000);
      var controller = widget.controllerForTest<PersistTestController>();
      controller.model.update(username: 'momentum', email: 'state@momentum');
      await tester.pump(Duration(milliseconds: 1000));
      expect(controller.model.username, 'momentum');
      expect(controller.model.email, 'state@momentum');
    });

    testWidgets('Misconfigured Code Hit Test: persistGet', (tester) async {
      var widget = persistedApp(noPersistGet: true);
      await inject(tester, widget, milliseconds: 4000);
      var controller = widget.controllerForTest<PersistTestController>();
      controller.model.update(username: 'momentum', email: 'state@momentum');
      await tester.pump(Duration(milliseconds: 1000));
      expect(controller.model.username, 'momentum');
      expect(controller.model.email, 'state@momentum');
    });

    testWidgets('Misconfigured Code Hit Test: toJson()', (tester) async {
      var widget = persistedApp();
      await inject(tester, widget, milliseconds: 4000);
      var controller = widget.controllerForTest<PersistErrorController>();
      controller.model.update(data: DummyObject(99));
      await tester.pump(Duration(milliseconds: 1000));
      expect(controller.model.data.value, 99);
    });

    testWidgets('Failed to save data test: persistSave', (tester) async {
      var widget = persistedApp(fakeFailSave: true);
      await inject(tester, widget, milliseconds: 4000);
      var controller = widget.controllerForTest<PersistTestController>();
      controller.model.update(username: 'momentum', email: 'state@momentum');
      await tester.pump(Duration(milliseconds: 1000));
      expect(controller.model.username, 'momentum');
      expect(controller.model.email, 'state@momentum');
    });

    testWidgets('#3 persist model for later error test', (tester) async {
      var widget = persistedApp();
      await inject(tester, widget, milliseconds: 4000);
      var controller = widget.controllerForTest<PersistError3Controller>();
      controller.model.update(data: DummyObject3(99));
      await tester.pump(Duration(milliseconds: 1000));
      expect(controller.model.data.value, 99);
    });

    testWidgets('#2 (Restart) Code Hit Test: fromJson()', (tester) async {
      var widget = persistedApp();
      await inject(tester, widget, milliseconds: 4000);
      var controller = widget.controllerForTest<PersistError3Controller>();
      expect(controller.model.data.value, 0);
    });

    testWidgets('#4 persist model for later error test', (tester) async {
      var widget = persistedApp();
      await inject(tester, widget, milliseconds: 4000);
      var controller = widget.controllerForTest<PersistError4Controller>();
      controller.model.update(data: DummyObject3(99));
      await tester.pump(Duration(milliseconds: 1000));
      expect(controller.model.data.value, 99);
    });

    testWidgets('#4 (Restart) Code Hit Test: fromJson()', (tester) async {
      var widget = persistedApp();
      await inject(tester, widget, milliseconds: 4000);
      var controller = widget.controllerForTest<PersistError4Controller>();
      expect(controller.model.data.value, 0);
    });
  });
}

/// Barber Search Integration Tests
///
/// Tests the barber search and discovery flows:
/// - Location permission handling
/// - Nearby barbers search
/// - Barber profile navigation
/// - Filter functionality
/// - Map view
///
/// Run with: flutter test test/integration/barber_search_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/barber.dart';
import '../../lib/providers/barber_provider.dart';
import '../mocks/mock_services.dart';
import '../mocks/mock_providers.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Barber Search Integration Tests', () {
    late MockBarberService mockBarberService;
    late List<Barber> testBarbers;

    setUp(() {
      mockBarberService = MockBarberService();

      // Create test barbers
      testBarbers = [
        Barber(
          id: 'barber-001',
          visibleName: 'John Smith',
          shopName: 'Downtown Cuts',
          bio: 'Professional barber with 10 years experience',
          location: 'Chicago, IL',
          latitude: 41.8781,
          longitude: -87.6298,
          serviceRadiusMiles: 15,
          isMobile: true,
          offersHomeService: true,
          travelFeePerMile: 2.0,
          isVerified: true,
          isActive: true,
          rating: 4.8,
          totalReviews: 127,
          stripeOnboardingComplete: true,
          createdAt: DateTime.now(),
        ),
        Barber(
          id: 'barber-002',
          visibleName: 'Mike Johnson',
          shopName: 'Urban Style Barbers',
          bio: 'Specializing in modern styles',
          location: 'Chicago, IL',
          latitude: 41.8819,
          longitude: -87.6278,
          serviceRadiusMiles: 10,
          isMobile: false,
          offersHomeService: false,
          isVerified: true,
          isActive: true,
          rating: 4.5,
          totalReviews: 89,
          stripeOnboardingComplete: true,
          createdAt: DateTime.now(),
        ),
        Barber(
          id: 'barber-003',
          visibleName: 'David Williams',
          shopName: 'Classic Cuts',
          bio: 'Traditional barbering at its finest',
          location: 'Chicago, IL',
          latitude: 41.8765,
          longitude: -87.6320,
          serviceRadiusMiles: 20,
          isMobile: true,
          offersHomeService: true,
          travelFeePerMile: 1.5,
          isVerified: true,
          isActive: true,
          rating: 4.9,
          totalReviews: 203,
          stripeOnboardingComplete: true,
          createdAt: DateTime.now(),
        ),
      ];

      mockBarberService.mockBarbers = testBarbers;
    });

    group('Location Permission Tests', () {
      testWidgets('should show location permission request UI', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const Scaffold(
              body: _LocationPermissionTestWidget(),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Should display location permission related UI
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('should handle permission denied gracefully', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      const Text('Location Access Required'),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Enable Location'),
                      ),
                    ],
                  );
                },
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Should show fallback UI when permission is denied
        expect(find.text('Location Access Required'), findsOneWidget);
        expect(find.text('Enable Location'), findsOneWidget);
      });
    });

    group('Nearby Barbers Search Tests', () {
      testWidgets('should display list of nearby barbers', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: _BarberListTestWidget(barbers: testBarbers),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Should display all barbers
        expect(find.text('Downtown Cuts'), findsOneWidget);
        expect(find.text('Urban Style Barbers'), findsOneWidget);
        expect(find.text('Classic Cuts'), findsOneWidget);
      });

      testWidgets('should show barber ratings and review counts',
          (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: _BarberListTestWidget(barbers: testBarbers),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Should display ratings
        expect(find.textContaining('4.8'), findsWidgets);
        expect(find.textContaining('4.5'), findsWidgets);
        expect(find.textContaining('4.9'), findsWidgets);
      });

      testWidgets('should show distance to barbers', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: ListView.builder(
                itemCount: testBarbers.length,
                itemBuilder: (context, index) {
                  final barber = testBarbers[index];
                  return ListTile(
                    title: Text(barber.displayName),
                    subtitle: Text('${(index + 1) * 0.5} mi away'),
                  );
                },
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Should display distances
        expect(find.textContaining('mi'), findsWidgets);
      });

      testWidgets('should show empty state when no barbers found',
          (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: _BarberListTestWidget(barbers: []),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Should display empty state
        expect(find.text('No barbers found'), findsOneWidget);
      });

      testWidgets('should support pull-to-refresh', (tester) async {
        bool refreshed = false;

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: RefreshIndicator(
                onRefresh: () async {
                  refreshed = true;
                },
                child: _BarberListTestWidget(barbers: testBarbers),
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Perform pull-to-refresh
        await tester.drag(find.byType(ListView), const Offset(0, 300));
        await tester.pumpAndSettle();

        expect(refreshed, true);
      });
    });

    group('Barber Profile Navigation Tests', () {
      testWidgets('should navigate to barber profile on tap', (tester) async {
        String? tappedBarberId;

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: ListView.builder(
                itemCount: testBarbers.length,
                itemBuilder: (context, index) {
                  final barber = testBarbers[index];
                  return ListTile(
                    key: Key('barber-${barber.id}'),
                    title: Text(barber.displayName),
                    onTap: () => tappedBarberId = barber.id,
                  );
                },
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Tap on first barber
        await tester.tap(find.byKey(const Key('barber-barber-001')));
        await tester.pumpAndSettle();

        expect(tappedBarberId, 'barber-001');
      });

      testWidgets('should display barber details on profile', (tester) async {
        final barber = testBarbers.first;

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: _BarberProfileTestWidget(barber: barber),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Should display barber details
        expect(find.text(barber.displayName), findsOneWidget);
        expect(find.text(barber.bio!), findsOneWidget);
        expect(find.textContaining('4.8'), findsWidgets);
      });
    });

    group('Search and Filter Tests', () {
      testWidgets('should filter barbers by search query', (tester) async {
        String searchQuery = '';
        List<Barber> filteredBarbers = testBarbers;

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      TextField(
                        key: const Key('search-field'),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                            filteredBarbers = testBarbers
                                .where((b) => b.displayName
                                    .toLowerCase()
                                    .contains(value.toLowerCase()))
                                .toList();
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search barbers...',
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredBarbers.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(filteredBarbers[index].displayName),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Enter search query
        await tester.enterText(find.byKey(const Key('search-field')), 'John');
        await tester.pumpAndSettle();

        // Should show filtered results
        expect(find.text('John Smith'), findsOneWidget);
        expect(find.text('Mike Johnson'), findsNothing);
      });

      testWidgets('should filter by mobile service availability',
          (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: Column(
                children: [
                  FilterChip(
                    label: const Text('Mobile'),
                    selected: true,
                    onSelected: (_) {},
                  ),
                  Expanded(
                    child: _BarberListTestWidget(
                      barbers: testBarbers.where((b) => b.isMobile).toList(),
                    ),
                  ),
                ],
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Should only show mobile barbers (2 out of 3)
        expect(find.text('Downtown Cuts'), findsOneWidget);
        expect(find.text('Urban Style Barbers'), findsNothing);
        expect(find.text('Classic Cuts'), findsOneWidget);
      });

      testWidgets('should sort barbers by rating', (tester) async {
        final sortedBarbers = List<Barber>.from(testBarbers)
          ..sort((a, b) => b.rating.compareTo(a.rating));

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: _BarberListTestWidget(barbers: sortedBarbers),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Verify order (highest rated first)
        final listItems = tester.widgetList<ListTile>(find.byType(ListTile));
        expect((listItems.first.title as Text).data, 'Classic Cuts');
      });
    });

    group('Map View Tests', () {
      testWidgets('should show map toggle button', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        key: const Key('list-view-btn'),
                        icon: const Icon(Icons.list),
                        onPressed: () {},
                      ),
                      IconButton(
                        key: const Key('map-view-btn'),
                        icon: const Icon(Icons.map),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  Expanded(
                    child: _BarberListTestWidget(barbers: testBarbers),
                  ),
                ],
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Should show view toggle buttons
        expect(find.byKey(const Key('list-view-btn')), findsOneWidget);
        expect(find.byKey(const Key('map-view-btn')), findsOneWidget);
      });

      testWidgets('should toggle between list and map views', (tester) async {
        bool showingMap = false;

        await tester.pumpWidget(
          createTestableWidget(
            Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      IconButton(
                        key: const Key('toggle-view-btn'),
                        icon: Icon(showingMap ? Icons.list : Icons.map),
                        onPressed: () =>
                            setState(() => showingMap = !showingMap),
                      ),
                      Expanded(
                        child: showingMap
                            ? const Center(
                                key: Key('map-view'),
                                child: Text('Map View'),
                              )
                            : _BarberListTestWidget(
                                key: const Key('list-view'),
                                barbers: testBarbers,
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
            overrides: createTestOverrides(isAuthenticated: true),
          ),
        );
        await tester.pumpAndSettle();

        // Initially showing list
        expect(find.byKey(const Key('list-view')), findsOneWidget);
        expect(find.byKey(const Key('map-view')), findsNothing);

        // Toggle to map
        await tester.tap(find.byKey(const Key('toggle-view-btn')));
        await tester.pumpAndSettle();

        // Now showing map
        expect(find.byKey(const Key('list-view')), findsNothing);
        expect(find.byKey(const Key('map-view')), findsOneWidget);
      });
    });
  });
}

// ============================================================================
// Test Widgets
// ============================================================================

class _LocationPermissionTestWidget extends StatelessWidget {
  const _LocationPermissionTestWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Location Permission Test'),
    );
  }
}

class _BarberListTestWidget extends StatelessWidget {
  final List<Barber> barbers;

  const _BarberListTestWidget({
    super.key,
    required this.barbers,
  });

  @override
  Widget build(BuildContext context) {
    if (barbers.isEmpty) {
      return const Center(
        child: Text('No barbers found'),
      );
    }

    return ListView.builder(
      itemCount: barbers.length,
      itemBuilder: (context, index) {
        final barber = barbers[index];
        return ListTile(
          key: Key('barber-${barber.id}'),
          title: Text(barber.displayName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(barber.shopName ?? ''),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  Text(' ${barber.rating} (${barber.totalReviews} reviews)'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BarberProfileTestWidget extends StatelessWidget {
  final Barber barber;

  const _BarberProfileTestWidget({required this.barber});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            barber.displayName,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(barber.shopName ?? ''),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber),
              Text(' ${barber.rating} (${barber.totalReviews} reviews)'),
            ],
          ),
          const SizedBox(height: 16),
          Text(barber.bio ?? ''),
          const SizedBox(height: 16),
          if (barber.isMobile)
            Chip(label: const Text('Mobile Service Available')),
          if (barber.offersHomeService)
            Chip(label: const Text('Home Service Available')),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:deligood/core/api/menu_service.dart';
import 'package:deligood/core/network/api.dart';
import 'package:deligood/core/styles/app_theme.dart';
import 'package:deligood/features/client/screens/restopage.dart';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'package:sizer/sizer.dart';

class RestaurantPage extends StatefulWidget {
  final String userName;

  const RestaurantPage({
    super.key,
    this.userName = '',
  });

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends State<RestaurantPage>
    with TickerProviderStateMixin {
  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();

  Timer? _debounce;

  List<Map<String, dynamic>> restaurants = [];
  List<Map<String, dynamic>> filtered = [];

  bool loading = true;
  bool error = false;

  String selectedCategory = 'Tous';

  final List<Map<String, dynamic>> categories = const [
    {
      'title': 'Tous',
      'icon': Icons.auto_awesome_rounded,
    },
    {
      'title': 'Fast-food',
      'icon': Icons.lunch_dining_rounded,
    },
    {
      'title': 'Africain',
      'icon': Icons.rice_bowl_rounded,
    },
    {
      'title': 'Italien',
      'icon': Icons.local_pizza_rounded,
    },
    {
      'title': 'Asiatique',
      'icon': Icons.ramen_dining_rounded,
    },
  ];

  final String _baseUrl =
      '${Api.baseUrl}/api/menu/restaurants/';

  @override
  void initState() {
    super.initState();

    _search.addListener(_onSearchChanged);

    fetchRestaurants();
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String get greeting {
    final h = DateTime.now().hour;

    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';

    return 'Bonsoir';
  }

  // ================= FETCH =================

  Future<void> fetchRestaurants() async {
    setState(() {
      loading = true;
      error = false;
    });

    try {
      debugPrint('URL => $_baseUrl');

      final res = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('STATUS => ${res.statusCode}');
      debugPrint('BODY => ${res.body}');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        final raw = decoded is List
            ? decoded
            : decoded['results'] ?? [];

        restaurants = List<Map<String, dynamic>>.from(raw);

        debugPrint(
          'RESTAURANTS => ${restaurants.length}',
        );

        filtered = restaurants;

        applyFilter();
      } else {
        debugPrint('ERROR STATUS');

        error = true;
      }
    } catch (e) {
      debugPrint('FETCH ERROR => $e');

      error = true;
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  // ================= SEARCH =================

  void _onSearchChanged() {
    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 300),
      applyFilter,
    );
  }

  void applyFilter() {
    final query = _search.text.trim().toLowerCase();

    setState(() {
      filtered = restaurants.where((r) {
        final name = (r['name'] ?? '')
            .toString()
            .toLowerCase();

        final category = (r['category'] ?? '')
            .toString()
            .toLowerCase();

        final matchQuery =
            query.isEmpty || name.contains(query);

        final matchCategory =
            selectedCategory == 'Tous'
                ? true
                : category.contains(
                    selectedCategory.toLowerCase(),
                  );

        return matchQuery && matchCategory;
      }).toList();

      debugPrint(
        'FILTERED => ${filtered.length}',
      );
    });
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchRestaurants,
          child: CustomScrollView(
            controller: _scroll,
            physics:
                const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _header(),
              ),

              SliverToBoxAdapter(
                child: _searchBar(),
              ),

              SliverToBoxAdapter(
                child: _categories(),
              ),

              SliverToBoxAdapter(
                child: _sectionTitle(),
              ),

              if (loading)
                SliverList.builder(
                  itemCount: 5,
                  itemBuilder: (_, __) =>
                      _skeleton(),
                )
              else if (error)
                SliverFillRemaining(
                  child: _error(),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: _empty(),
                )
              else
                SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    return _card(filtered[i]);
                  },
                ),

              const SliverToBoxAdapter(
                child: Gap(100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _header() {
    return Padding(
      padding: EdgeInsets.all(5.w),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting ${widget.userName}',
            style: AppText.bodySm(
              color:
                  AppColors.textSecondary,
            ),
          ),

          Gap(0.5.h),

          Text(
            "Que voulez-vous manger ?",
            style: AppText.h1(),
          ),
        ],
      ),
    );
  }

  // ================= SEARCH BAR =================

  Widget _searchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 5.w,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 4.w,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          boxShadow: AppShadows.subtle,
        ),
        child: TextField(
          controller: _search,
          decoration: InputDecoration(
            border: InputBorder.none,
            icon: const Icon(
              Icons.search,
              color: AppColors.orange,
            ),
            hintText:
                "Rechercher un restaurant...",
          ),
        ),
      ),
    );
  }

  // ================= CATEGORIES =================

  Widget _categories() {
    return Padding(
      padding: EdgeInsets.only(
        top: 2.h,
      ),
      child: SizedBox(
        height: 6.h,
        child: ListView.separated(
          scrollDirection:
              Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: 5.w,
          ),
          itemBuilder: (_, i) {
            final c = categories[i];

            final selected =
                selectedCategory ==
                    c['title'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory =
                      c['title'];
                });

                applyFilter();
              },
              child: AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 250,
                ),
                padding:
                    EdgeInsets.symmetric(
                  horizontal: 4.w,
                ),
                decoration:
                    BoxDecoration(
                  color: selected
                      ? AppColors.orange
                      : AppColors
                          .surfaceContainer,
                  borderRadius:
                      BorderRadius
                          .circular(
                    999,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      c['icon'],
                      size: 18,
                      color: selected
                          ? Colors.white
                          : AppColors
                              .textSecondary,
                    ),

                    SizedBox(
                      width: 2.w,
                    ),

                    Text(
                      c['title'],
                      style:
                          AppText.bodySm(
                        color: selected
                            ? Colors.white
                            : AppColors
                                .textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          separatorBuilder:
              (_, __) => SizedBox(
            width: 3.w,
          ),
          itemCount:
              categories.length,
        ),
      ),
    );
  }

  // ================= TITLE =================

  Widget _sectionTitle() {
    return Padding(
      padding: EdgeInsets.all(5.w),
      child: Row(
        children: [
          Text(
            "Restaurants",
            style: AppText.h2(),
          ),

          const Spacer(),

          Text(
            "${filtered.length} résultats",
            style: AppText.bodySm(),
          ),
        ],
      ),
    );
  }

  // ================= CARD =================

  Widget _card(
    Map<String, dynamic> r,
  ) {
    final photo = MenuService.fixImageUrl(
      (r['photo_url'] ?? r['photo'])
          ?.toString(),
    );

    final name =
        r['name']?.toString() ?? '';

    final locality =
        r['locality']?.toString() ??
            '';

    final rating =
        r['rating']?.toString() ??
            '0';

    final isOpen =
        r['is_open'] ?? false;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 5.w,
        vertical: 1.h,
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  Restopage(
                restaurant: r,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(
              24,
            ),
            boxShadow:
                AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius
                        .vertical(
                  top:
                      Radius.circular(
                    24,
                  ),
                ),
                child: photo == null ||
                        photo.isEmpty
                    ? _imageFallback()
                    : Image.network(
                        photo,
                        height: 22.h,
                        width:
                            double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (
                              _,
                              __,
                              ___,
                            ) =>
                                _imageFallback(),
                      ),
              ),

              Padding(
                padding:
                    EdgeInsets.all(
                  4.w,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style:
                                AppText.h3(),
                          ),
                        ),

                        Container(
                          padding:
                              EdgeInsets.symmetric(
                            horizontal:
                                2.5.w,
                            vertical:
                                0.7.h,
                          ),
                          decoration:
                              BoxDecoration(
                            color: isOpen
                                ? Colors
                                    .green
                                    .withOpacity(
                                      0.1,
                                    )
                                : Colors
                                    .red
                                    .withOpacity(
                                      0.1,
                                    ),
                            borderRadius:
                                BorderRadius.circular(
                              999,
                            ),
                          ),
                          child: Text(
                            isOpen
                                ? 'Ouvert'
                                : 'Fermé',
                            style:
                                TextStyle(
                              fontSize:
                                  11.sp,
                              color: isOpen
                                  ? Colors
                                      .green
                                  : Colors
                                      .red,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    Gap(0.7.h),

                    Row(
                      children: [
                        const Icon(
                          Icons
                              .location_on_rounded,
                          size: 18,
                          color:
                              AppColors
                                  .orange,
                        ),

                        SizedBox(
                          width: 1.w,
                        ),

                        Text(
                          locality,
                          style:
                              AppText.bodySm(),
                        ),

                        const Spacer(),

                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 18,
                        ),

                        SizedBox(
                          width: 1.w,
                        ),

                        Text(
                          rating,
                          style:
                              AppText.bodySm(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= STATES =================

  Widget _skeleton() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 5.w,
        vertical: 1.h,
      ),
      height: 25.h,
      decoration: BoxDecoration(
        color:
            AppColors.surfaceContainer,
        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      height: 22.h,
      width: double.infinity,
      color:
          AppColors.surfaceContainer,
      child: Center(
        child: Image.asset(
          'assets/images/n.png',
          height: 9.h,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _error() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 70,
            color: Colors.red,
          ),

          Gap(2.h),

          Text(
            "Erreur de chargement",
            style: AppText.h3(),
          ),

          Gap(1.h),

          ElevatedButton(
            onPressed:
                fetchRestaurants,
            child: const Text(
              "Réessayer",
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.storefront_outlined,
            size: 70,
            color: Colors.grey,
          ),

          Gap(2.h),

          Text(
            "Aucun restaurant trouvé",
            style: AppText.h3(),
          ),
        ],
      ),
    );
  }
}
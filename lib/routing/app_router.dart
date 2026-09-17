import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// পরে স্ক্রিনগুলো ইমপোর্ট করা হবে
// import '../features/auth/presentation/screens/login_screen.dart';
// import '../features/home/presentation/screens/home_feed_screen.dart';
// ইত্যাদি...

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }
    if (isLoggedIn && isAuthRoute) {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Home Feed - Coming Soon')),
      ),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Login Screen - Coming Soon')),
      ),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Register Screen - Coming Soon')),
      ),
    ),
    // পরে আরও রুট যোগ করা হবে
  ],
);

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/home/presentation/screens/home_feed_screen.dart';
import '../features/story/presentation/screens/story_reader_screen.dart';
import '../features/story/presentation/screens/create_story_screen.dart';
import '../features/story/presentation/screens/edit_story_screen.dart';
import '../features/novel/presentation/screens/create_novel_screen.dart';
import '../features/novel/presentation/screens/novel_details_screen.dart';
import '../features/novel/presentation/screens/add_episode_screen.dart';
import '../features/novel/presentation/screens/edit_episode_screen.dart';
import '../features/novel/presentation/screens/episode_reader_screen.dart';
import '../features/profile/presentation/screens/user_profile_screen.dart';
import '../features/profile/presentation/screens/my_works_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';

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
      builder: (context, state) => const HomeFeedScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/story/:id',
      name: 'story-reader',
      builder: (context, state) {
        final storyId = state.pathParameters['id']!;
        return StoryReaderScreen(storyId: storyId);
      },
    ),
    GoRoute(
      path: '/create-story',
      name: 'create-story',
      builder: (context, state) => const CreateStoryScreen(),
    ),
    GoRoute(
      path: '/edit-story/:id',
      name: 'edit-story',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return EditStoryScreen(storyId: id);
      },
    ),
    GoRoute(
      path: '/create-novel',
      name: 'create-novel',
      builder: (context, state) => const CreateNovelScreen(),
    ),
    GoRoute(
      path: '/novel/:id',
      name: 'novel-details',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return NovelDetailsScreen(novelId: id);
      },
    ),
    GoRoute(
      path: '/add-episode/:novelId',
      name: 'add-episode',
      builder: (context, state) {
        final novelId = state.pathParameters['novelId']!;
        return AddEpisodeScreen(novelId: novelId);
      },
    ),
    GoRoute(
      path: '/edit-episode/:id',
      name: 'edit-episode',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return EditEpisodeScreen(episodeId: id);
      },
    ),
    GoRoute(
      path: '/episode/:id',
      name: 'episode-reader',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return EpisodeReaderScreen(episodeId: id);
      },
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const UserProfileScreen(),
    ),
    GoRoute(
      path: '/my-works',
      name: 'my-works',
      builder: (context, state) => const MyWorksScreen(),
    ),
    GoRoute(
      path: '/search',
      name: 'search',
      builder: (context, state) => const SearchScreen(),
    ),
  ],
);

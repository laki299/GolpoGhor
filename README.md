# গল্পঘর (GolpoGhor)

বাংলা গল্প ও উপন্যাস প্রকাশ ও পড়ার প্ল্যাটফর্ম।

## Features

- এক অ্যাকাউন্ট = Reader + Writer
- Standalone Story + Serial Novel (Episode based)
- Facebook-like Feed + Book-like Reading Experience
- Reaction (একাধিক), Comment + Reply
- Bookmark, Search (Partial Match)
- Follow System (Follower / Following count)
- Dark Mode
- Image support (সর্বোচ্চ ১টি per content, যেকোনো অবস্থানে)
- Draft (খসড়া সেভ ও প্রকাশ)
- Offline Download + Offline Reading
- Reading Progress (% + progress bar)
- Profile Edit, My Works, Saved Stories

## Tech Stack

- Flutter
- Supabase (Auth + Database + Storage)
- Riverpod
- go_router
- shared_preferences (Offline)
- google_fonts
- cached_network_image
- image_picker

## Getting Started

1. Flutter SDK ইনস্টল করুন
2. প্রজেক্ট ক্লোন করুন
3. `flutter pub get`
4. Supabase URL ও Anon Key `lib/core/constants/supabase_constants.dart` এ আছে
5. `flutter run`

## Folder Structure

lib/
├── core/
│   ├── constants/
│   ├── models/
│   ├── services/
│   └── theme/
├── features/
│   ├── auth/
│   ├── home/
│   ├── story/
│   ├── novel/
│   ├── profile/
│   ├── search/
│   ├── social/
│   └── offline/
└── routing/

## Database Tables

- profiles
- stories
- novels
- episodes
- comments
- reactions
- follows
- bookmarks
- reading_progress

## Storage

- Bucket: `story-images` (Public read, Authenticated upload)

## Main Routes

| Route | Screen |
|-------|--------|
| `/` | Home Feed |
| `/login` | Login |
| `/register` | Register |
| `/story/:id` | Story Reader |
| `/create-story` | Create Story |
| `/edit-story/:id` | Edit Story |
| `/drafts` | Drafts |
| `/novel/:id` | Novel Details |
| `/episode/:id` | Episode Reader |
| `/create-novel` | Create Novel |
| `/add-episode/:novelId` | Add Episode |
| `/profile` | Profile |
| `/my-works` | My Works |
| `/saved` | Saved Stories |
| `/offline` | Offline Downloads |
| `/search` | Search |

## Notes

- Video সম্পূর্ণ নিষিদ্ধ
- Comment-এ শুধু Text + Emoji
- Episode Number automatic
- Image automatic compress হয়
- Offline content অ্যাপের ভিতরেই পড়া যায় (JSON local save)
- Notification ও Admin Panel পরবর্তী ধাপে

## License

Private / Personal project.

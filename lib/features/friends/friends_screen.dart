import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:journal_app/core/auth/user_service.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  UserProfile? _searchResult;
  bool _isSearching = false;
  String? _error;

  void _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResult = null;
      _error = null;
    });

    try {
      final user = await ref.read(userServiceProvider).searchByDisplayId(query);
      if (mounted) {
        setState(() {
          _searchResult = user;
          if (user == null) _error = 'Kullanıcı bulunamadı.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Arama hatası: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _handleAddFriend(UserProfile friend) async {
    try {
      await ref.read(userServiceProvider).addFriend(friend.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${friend.displayName} eklendi!')),
        );
        setState(() => _searchResult = null);
        _searchController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myProfileAsync = ref.watch(
      StreamProvider((ref) => ref.read(userServiceProvider).myProfileStream),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Arkadaşlar'), centerTitle: true),
      body: myProfileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('Profil bulunamadı. Lütfen giriş yapın.'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal ID Card
                _buildMyIdCard(profile),
                const SizedBox(height: 32),

                // Search Section
                Text(
                  'Arkadaş Ekle',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildSearchBar(),

                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),

                if (_searchResult != null)
                  _buildSearchResultCard(_searchResult!, profile),

                const SizedBox(height: 32),

                // Friends List Section
                Text(
                  'Arkadaşlarım',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (profile.friends.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Henüz arkadaşın yok. ID ile arayıp ekleyebilirsin!',
                      ),
                    ),
                  )
                else
                  _buildFriendsList(profile.friends),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
      ),
    );
  }

  Widget _buildMyIdCard(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            backgroundImage: profile.photoUrl != null
                ? NetworkImage(profile.photoUrl!)
                : null,
            child: profile.photoUrl == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ID: ${profile.displayId}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: profile.displayId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ID kopyalandı!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Örn: J-1234',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onSubmitted: (_) => _handleSearch(),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _handleSearch,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.all(16),
          ),
          child: const Icon(Icons.arrow_forward),
        ),
      ],
    );
  }

  Widget _buildSearchResultCard(UserProfile user, UserProfile currentMe) {
    final isAlreadyFriend = currentMe.friends.contains(user.uid);
    final isMe = user.uid == currentMe.uid;

    return Card(
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.photoUrl != null
              ? NetworkImage(user.photoUrl!)
              : null,
          child: user.photoUrl == null ? const Icon(Icons.person) : null,
        ),
        title: Text(user.displayName),
        subtitle: Text(user.displayId),
        trailing: isMe
            ? const Text('(Sen)')
            : isAlreadyFriend
            ? const Icon(Icons.check_circle, color: Colors.green)
            : IconButton(
                icon: const Icon(Icons.person_add_alt_1),
                color: Theme.of(context).colorScheme.primary,
                onPressed: () => _handleAddFriend(user),
              ),
      ),
    );
  }

  Widget _buildFriendsList(List<String> friendUids) {
    // Ideally use a FutureProvider to fetch multiple profiles
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: friendUids.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        // Fetching profile in-list (Not most efficient but works for now)
        // A better way: UserProfileProvider
        return _FriendListTile(uid: friendUids[index]);
      },
    );
  }
}

class _FriendListTile extends ConsumerWidget {
  final String uid;
  const _FriendListTile({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real app, you'd want to cache this or use a more efficient stream
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final friend = UserProfile.fromMap(data);

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: friend.photoUrl != null
                  ? NetworkImage(friend.photoUrl!)
                  : null,
              child: friend.photoUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Text(friend.displayName),
            subtitle: Text(friend.displayId),
          ),
        );
      },
    );
  }
}

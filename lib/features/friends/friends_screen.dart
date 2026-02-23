import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/auth/user_service.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arkadaşlar'), centerTitle: true),
      body: const FriendsView(),
    );
  }
}

class FriendsView extends ConsumerStatefulWidget {
  const FriendsView({super.key});

  @override
  ConsumerState<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends ConsumerState<FriendsView> {
  final TextEditingController _searchController = TextEditingController();
  UserProfile? _searchResult;
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _error = 'Lütfen bir kullanıcı adı girin.');
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResult = null;
      _error = null;
    });

    try {
      final user = await ref.read(userServiceProvider).searchByUsername(query);
      if (mounted) {
        setState(() {
          _searchResult = user;
          if (user == null) _error = 'Kullanıcı bulunamadı.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Arama hatası: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _handleSendRequest(UserProfile user) async {
    try {
      await ref.read(userServiceProvider).sendFriendRequest(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${user.displayName} kullanıcısına istek gönderildi.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleAcceptRequest(String uid, String name) async {
    try {
      await ref.read(userServiceProvider).acceptFriendRequest(uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name ile artık arkadaşsınız.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('İstek kabul edilemedi: $e')));
      }
    }
  }

  void _handleRejectRequest(String uid) async {
    try {
      await ref.read(userServiceProvider).rejectFriendRequest(uid);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('İstek reddedildi.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('İstek reddedilemedi: $e')));
      }
    }
  }

  void _handleCancelRequest(String uid) async {
    try {
      await ref.read(userServiceProvider).cancelFriendRequest(uid);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('İstek iptal edildi.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('İstek iptal edilemedi: $e')));
      }
    }
  }

  void _handleRemoveFriend(String uid, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arkadaşı Çıkar'),
        content: Text('$name listenizden çıkarılacak. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(userServiceProvider).removeFriend(uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name arkadaşlardan çıkarıldı.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Arkadaş çıkarılamadı: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFirebaseAvailable = ref.watch(firebaseAvailableProvider);
    final myProfileAsync = ref.watch(myProfileProvider);

    if (!isFirebaseAvailable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Firebase bağlantısı kurulamadı.\nSosyal özellikler şu an devre dışı.\nLütfen internet bağlantınızı kontrol edip uygulamayı yeniden başlatın.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              if (Navigator.canPop(context))
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Geri Dön'),
                ),
            ],
          ),
        ),
      );
    }

    return myProfileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Center(
            child: Text('Profil bulunamadı. Lütfen giriş yapın.'),
          );
        }

        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildMyIdCard(profile),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStatsSummary(profile),
              ),
              const SizedBox(height: 8),
              const TabBar(
                tabs: [
                  Tab(text: 'Ekle'),
                  Tab(text: 'İstekler'),
                  Tab(text: 'Arkadaşlar'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildAddTab(profile),
                    _buildRequestsTab(profile),
                    _buildFriendsTab(profile),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Hata: $e')),
    );
  }

  Widget _buildStatsSummary(UserProfile profile) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildCountChip('Arkadaş', profile.friends.length, Icons.people),
        _buildCountChip(
          'Gelen',
          profile.receivedFriendRequests.length,
          Icons.inbox,
        ),
        _buildCountChip(
          'Gönderilen',
          profile.sentFriendRequests.length,
          Icons.outbox,
        ),
      ],
    );
  }

  Widget _buildCountChip(String label, int count, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text('$label: $count'),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildAddTab(UserProfile profile) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Arkadaş Ekle', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _buildSearchBar(),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_searchResult != null)
          _buildSearchResultCard(_searchResult!, profile),
      ],
    );
  }

  Widget _buildRequestsTab(UserProfile profile) {
    final hasReceived = profile.receivedFriendRequests.isNotEmpty;
    final hasSent = profile.sentFriendRequests.isNotEmpty;

    if (!hasReceived && !hasSent) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Bekleyen istek yok.'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (hasReceived) ...[
          Text(
            'Gelen İstekler (${profile.receivedFriendRequests.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildRequestsList(profile.receivedFriendRequests),
        ],
        if (hasReceived && hasSent) const SizedBox(height: 20),
        if (hasSent) ...[
          Text(
            'Gönderilen İstekler (${profile.sentFriendRequests.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildSentRequestsList(profile.sentFriendRequests),
        ],
      ],
    );
  }

  Widget _buildFriendsTab(UserProfile profile) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTeamsShortcutCard(),
        const SizedBox(height: 16),
        if (profile.friends.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Henüz arkadaşın yok. Ekle sekmesinden kullanıcı adı ile arama yapabilirsin.',
              textAlign: TextAlign.center,
            ),
          )
        else ...[
          Text(
            'Arkadaşlarım (${profile.friends.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildFriendsList(profile.friends),
        ],
      ],
    );
  }

  Widget _buildTeamsShortcutCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.groups_rounded),
        title: const Text('Takımlarım'),
        subtitle: const Text('Arkadaşlar bölümünün altında takım yönetimi'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push('/teams'),
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
                  '@${profile.username ?? '-'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: profile.username ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kullanıcı adı kopyalandı.'),
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
              hintText: 'Kullanıcı adı ile arkadaş ara...',
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
    final isMe = user.uid == currentMe.uid;
    final isReceived = currentMe.receivedFriendRequests.contains(user.uid);
    final isSent = currentMe.sentFriendRequests.contains(user.uid);
    final isFriend = currentMe.friends.contains(user.uid);

    Widget trailing;

    if (isMe) {
      trailing = const Chip(label: Text('Sen'));
    } else if (isFriend) {
      trailing = const Chip(
        avatar: Icon(Icons.check_circle, color: Colors.green, size: 16),
        label: Text('Arkadaşsınız'),
      );
    } else if (isReceived) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => _handleAcceptRequest(user.uid, user.displayName),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => _handleRejectRequest(user.uid),
          ),
        ],
      );
    } else if (isSent) {
      trailing = OutlinedButton(
        onPressed: () => _handleCancelRequest(user.uid),
        child: const Text('İptal Et'),
      );
    } else {
      trailing = FilledButton.icon(
        icon: const Icon(Icons.person_add, size: 18),
        label: const Text('Ekle'),
        onPressed: () => _handleSendRequest(user),
      );
    }

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
        subtitle: Text('@${user.username ?? '-'}'),
        trailing: trailing,
      ),
    );
  }

  Widget _buildRequestsList(List<String> requestUids) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requestUids.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _FriendRequestListTile(
          uid: requestUids[index],
          onAccept: (uid, name) => _handleAcceptRequest(uid, name),
          onReject: (uid) => _handleRejectRequest(uid),
        );
      },
    );
  }

  Widget _buildSentRequestsList(List<String> requestUids) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requestUids.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _SentRequestListTile(
          uid: requestUids[index],
          onCancel: (uid) => _handleCancelRequest(uid),
        );
      },
    );
  }

  Widget _buildFriendsList(List<String> friendUids) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: friendUids.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _FriendListTile(
          uid: friendUids[index],
          onRemove: (uid, name) => _handleRemoveFriend(uid, name),
        );
      },
    );
  }
}

class _FriendRequestListTile extends StatelessWidget {
  final String uid;
  final Function(String, String) onAccept;
  final Function(String) onReject;

  const _FriendRequestListTile({
    required this.uid,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.data == null ||
            !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox.shrink();

        final user = UserProfile.fromMap(data);

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Text(user.displayName),
            subtitle: Text('@${user.username ?? '-'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => onAccept(user.uid, user.displayName),
                  tooltip: 'Kabul Et',
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => onReject(user.uid),
                  tooltip: 'Reddet',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SentRequestListTile extends StatelessWidget {
  const _SentRequestListTile({required this.uid, required this.onCancel});

  final String uid;
  final Function(String uid) onCancel;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.data == null ||
            !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox.shrink();

        final user = UserProfile.fromMap(data);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Text(user.displayName),
            subtitle: Text('@${user.username ?? '-'}'),
            trailing: OutlinedButton(
              onPressed: () => onCancel(user.uid),
              child: const Text('İptal Et'),
            ),
          ),
        );
      },
    );
  }
}

class _FriendListTile extends ConsumerWidget {
  final String uid;
  final Function(String, String) onRemove;

  const _FriendListTile({required this.uid, required this.onRemove});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = ref.watch(firebaseAvailableProvider);
    if (!isAvailable) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.data == null ||
            !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox.shrink();

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
            subtitle: Text('@${friend.username ?? "-"}'),
            trailing: IconButton(
              icon: const Icon(Icons.person_remove, color: Colors.red),
              onPressed: () => onRemove(friend.uid, friend.displayName),
              tooltip: 'Arkadaşı Çıkar',
            ),
          ),
        );
      },
    );
  }
}

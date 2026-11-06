import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _favoriteController =
      TextEditingController();

  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final user = context.read<UserProvider>().user;

    if (user != null &&
        _nameController.text.isEmpty &&
        _emailController.text.isEmpty) {
      _nameController.text = user.name;
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final message = await context.read<UserProvider>().saveProfile(
          name: _nameController.text,
          email: _emailController.text,
        );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Profil berhasil disimpan.'),
        backgroundColor:
            message == null ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _addFavorite() async {
    final value = _favoriteController.text.trim();

    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nama favorit terlebih dahulu.'),
        ),
      );
      return;
    }

    final provider = context.read<UserProvider>();

    final alreadyExists = provider.favorites.any(
      (item) => item.toLowerCase() == value.toLowerCase(),
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item favorit sudah ada.'),
        ),
      );
      return;
    }

    await provider.addFavorite(value);

    _favoriteController.clear();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Favorit berhasil ditambahkan.'),
      ),
    );
  }

 Future<void> _logout() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus profil?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Ya'),
          ),
        ],
      );
    },
  );

  if (!mounted) return;

  if (confirm == true) {
    await context.read<UserProvider>().logout();

    if (!mounted) return;

    _nameController.clear();
    _emailController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil berhasil dihapus.'),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 45,
                child: Icon(
                  Icons.person,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Informasi Profil',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama wajib diisi.';
                      }

                      if (RegExp(r'<[^>]*>|[<>]').hasMatch(value)) {
                        return 'Nama mengandung karakter berbahaya.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email wajib diisi.';
                      }

                      final pattern = RegExp(
                        r'^[\w.+-]+@[\w-]+\.[\w.-]+$',
                      );

                      if (!pattern.hasMatch(value.trim())) {
                        return 'Format email tidak valid.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveProfile,
                      icon: const Icon(Icons.save),
                      label: Text(
                        _isSaving ? 'Menyimpan...' : 'Simpan Profil',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Divider(),

            const Text(
              'Daftar Favorit',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _favoriteController,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Membaca',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addFavorite(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addFavorite,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (provider.favorites.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Belum ada daftar favorit.'),
              )
            else
              ...provider.favorites.map(
                (item) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.favorite),
                      title: Text(item),
                      trailing: IconButton(
                        tooltip: 'Hapus favorit',
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          context
                              .read<UserProvider>()
                              .removeFavorite(item);
                        },
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Hapus Profil'),
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'Catatan keamanan: Password tidak disimpan di SharedPreferences. '
              'Data yang disimpan pada praktikum ini hanya berupa informasi '
              'profil dan preferensi non-sensitif.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kerangka_markir.dart';
import '../widgets/markir_widgets.dart';

/// Model data lokal untuk profil pengguna.
class DataProfilPengguna {
  const DataProfilPengguna({
    required this.nama,
    required this.tanggalLahir,
    required this.jenisKelamin,
    required this.noTelepon,
    required this.email,
    required this.platNomor,
    required this.domisili,
  });

  final String nama;
  final DateTime tanggalLahir;
  final String jenisKelamin;
  final String noTelepon;
  final String email;
  final String platNomor;
  final String domisili;

  DataProfilPengguna copyWith({
    String? nama,
    DateTime? tanggalLahir,
    String? jenisKelamin,
    String? noTelepon,
    String? email,
    String? platNomor,
    String? domisili,
  }) {
    return DataProfilPengguna(
      nama: nama ?? this.nama,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      noTelepon: noTelepon ?? this.noTelepon,
      email: email ?? this.email,
      platNomor: platNomor ?? this.platNomor,
      domisili: domisili ?? this.domisili,
    );
  }
}

/// Halaman Pengaturan & Ringkasan Profil Pengguna (Tab ke-3 pada ShellScreen).
class ProfilScreen extends StatefulWidget {
  const ProfilScreen({
    super.key,
    this.onNamaBerubah,
  });

  final ValueChanged<String>? onNamaBerubah;

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  DataProfilPengguna _data = DataProfilPengguna(
    nama: 'Pengguna Markir.In',
    tanggalLahir: DateTime(2005, 5, 11),
    jenisKelamin: 'Perempuan',
    noTelepon: '081234567890',
    email: 'markirin@gmail.com',
    platNomor: 'L 1234 AB',
    domisili: 'Surabaya',
  );

  bool _notifikasiAktif = true;
  String _bahasaTerpilih = 'Bahasa Indonesia';

  @override
  void initState() {
    super.initState();
    _muatDataAwal();
  }

  Future<void> _muatDataAwal() async {
    try {
      final hasil = await AuthService().ambilProfil();
      if (!mounted) return;

      final nama = (hasil['nama'] ?? '').toString().trim();
      final email = (hasil['email'] ?? '').toString().trim();
      final telepon =
          (hasil['no_hp'] ?? hasil['telepon'] ?? hasil['nomor_telepon'] ?? '')
              .toString()
              .trim();
      final plat = (hasil['plat_nomor'] ?? '').toString().trim();
      final domisili = (hasil['domisili'] ?? '').toString().trim();

      setState(() {
        _data = _data.copyWith(
          nama: nama.isNotEmpty ? nama : null,
          email: email.isNotEmpty ? email : null,
          noTelepon: telepon.isNotEmpty ? telepon : null,
          platNomor: plat.isNotEmpty ? plat : null,
          domisili: domisili.isNotEmpty ? domisili : null,
        );
      });
    } catch (_) {
      // Tetap gunakan data dummy bawaan jika layanan Supabase belum aktif.
    }
  }

  String _ambilInisial(String nama) {
    final bagian = nama.trim().split(RegExp(r'\s+'));
    if (bagian.isEmpty || bagian.first.isEmpty) return 'M';
    if (bagian.length == 1) return bagian.first[0].toUpperCase();
    return '${bagian[0][0]}${bagian[1][0]}'.toUpperCase();
  }

  Future<void> _bukaHalamanAkun() async {
    final hasil = await Navigator.of(context).push<DataProfilPengguna>(
      MaterialPageRoute(
        builder: (_) => AkunScreen(dataAwal: _data),
      ),
    );

    if (hasil != null && mounted) {
      setState(() => _data = hasil);
      widget.onNamaBerubah?.call(hasil.nama);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perubahan data profil berhasil disimpan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _bukaDialogBahasa() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.permukaan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Pilihan Bahasa',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Bahasa Indonesia', 'English'].map((bahasa) {
            final aktif = _bahasaTerpilih == bahasa;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                aktif
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: AppColors.primer,
              ),
              title: Text(bahasa),
              onTap: () {
                setState(() => _bahasaTerpilih = bahasa);
                Navigator.of(ctx).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _bukaDialogKeamanan() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.permukaan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Keamanan Akun',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email terhubung: ${_data.email}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Status autentikasi menggunakan sesi lokal sementara. Fitur ubah kata sandi akan aktif setelah layanan Supabase terhubung.',
              style: TextStyle(fontSize: 13, color: AppColors.slate500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _bukaDialogBantuan() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.permukaan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Pusat Bantuan Markir.In',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Pemesanan Slot',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              'Pilih lokasi parkir di Beranda, tentukan slot tersedia, lalu selesaikan pembayaran QRIS.',
              style: TextStyle(fontSize: 13, color: AppColors.slate500),
            ),
            SizedBox(height: 10),
            Text(
              '2. Check-in & Check-out',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              'Buka menu Riwayat > tab Aktif untuk memindai kode QR saat masuk dan keluar area parkir.',
              style: TextStyle(fontSize: 13, color: AppColors.slate500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _konfirmasiLogout() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.permukaan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Keluar Akun',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari sesi akun Markir.In saat ini?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.merah),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text(
              'Keluar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Pengaturan',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primer,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Kelola informasi profil dan preferensi akun Anda.',
                style: TextStyle(fontSize: 14, color: AppColors.slate500),
              ),
              const SizedBox(height: 18),

              // Kartu Ringkasan Profil Pengguna
              KartuPutih(
                padding: const EdgeInsets.all(20),
                radius: 20,
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: AppColors.primerSoft,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _ambilInisial(_data.nama),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _data.nama,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primer,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_data.email} • ${_data.platNomor}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _bukaHalamanAkun,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Ubah Profil'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Kartu Daftar Menu Pengaturan
              KartuPutih(
                padding: const EdgeInsets.symmetric(vertical: 8),
                radius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.permukaanAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'AKUN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.primer,
                        ),
                      ),
                    ),
                    _ItemMenuSettings(
                      ikon: Icons.account_circle_outlined,
                      judul: 'Pengaturan Akun',
                      subjudul: 'Lihat dan ubah data profil pengguna',
                      onTap: _bukaHalamanAkun,
                    ),
                    const Divider(indent: 56, endIndent: 16),
                    _ItemMenuSettings(
                      ikon: Icons.history_rounded,
                      judul: 'Aktivitasku',
                      subjudul: 'Lihat riwayat pemesanan parkir',
                      onTap: () => tabAktif.value = 1,
                    ),
                    const Divider(indent: 56, endIndent: 16),
                    _ItemMenuSettings(
                      ikon: Icons.help_outline_rounded,
                      judul: 'Pusat Bantuan',
                      subjudul: 'Panduan penggunaan Markir.In',
                      onTap: _bukaDialogBantuan,
                    ),
                    const Divider(indent: 56, endIndent: 16),
                    _ItemMenuSettings(
                      ikon: Icons.translate_rounded,
                      judul: 'Pilihan Bahasa',
                      subjudul: _bahasaTerpilih,
                      onTap: _bukaDialogBahasa,
                    ),
                    const Divider(indent: 56, endIndent: 16),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 2,
                      ),
                      leading: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.primer,
                      ),
                      title: const Text(
                        'Notifikasi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primer,
                        ),
                      ),
                      subtitle: const Text(
                        'Pengingat check-in dan status slot',
                        style: TextStyle(fontSize: 12, color: AppColors.slate500),
                      ),
                      trailing: Switch(
                        value: _notifikasiAktif,
                        onChanged: (val) =>
                            setState(() => _notifikasiAktif = val),
                      ),
                    ),
                    const Divider(indent: 56, endIndent: 16),
                    _ItemMenuSettings(
                      ikon: Icons.shield_outlined,
                      judul: 'Keamanan Akun',
                      subjudul: 'Informasi perlindungan akun',
                      onTap: _bukaDialogKeamanan,
                    ),
                    const Divider(indent: 56, endIndent: 16),
                    _ItemMenuSettings(
                      ikon: Icons.logout_rounded,
                      judul: 'Keluar Akun',
                      subjudul: 'Keluar dari sesi aplikasi saat ini',
                      warna: AppColors.merah,
                      onTap: _konfirmasiLogout,
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
}

class _ItemMenuSettings extends StatelessWidget {
  const _ItemMenuSettings({
    required this.ikon,
    required this.judul,
    required this.subjudul,
    required this.onTap,
    this.warna = AppColors.primer,
  });

  final IconData ikon;
  final String judul;
  final String subjudul;
  final VoidCallback onTap;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(ikon, color: warna),
      title: Text(
        judul,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: warna,
        ),
      ),
      subtitle: Text(
        subjudul,
        style: const TextStyle(fontSize: 12, color: AppColors.slate500),
      ),
      trailing: Icon(
        Icons.arrow_forward_rounded,
        size: 20,
        color: warna,
      ),
    );
  }
}

/// Halaman Detail & Ubah Profil Pengguna.
class AkunScreen extends StatefulWidget {
  const AkunScreen({super.key, required this.dataAwal});

  final DataProfilPengguna dataAwal;

  @override
  State<AkunScreen> createState() => _AkunScreenState();
}

class _AkunScreenState extends State<AkunScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _teleponController;
  late final TextEditingController _platController;

  late DateTime _tanggalLahir;
  late String _jenisKelamin;
  late String _domisili;

  static const List<String> _daftarDomisili = [
    'Surabaya',
    'Sidoarjo',
    'Gresik',
    'Malang',
    'Jakarta',
    'Bandung',
    'Semarang',
    'Yogyakarta',
  ];

  static const List<String> _namaBulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.dataAwal.nama);
    _teleponController = TextEditingController(text: widget.dataAwal.noTelepon);
    _platController = TextEditingController(text: widget.dataAwal.platNomor);
    _tanggalLahir = widget.dataAwal.tanggalLahir;
    _jenisKelamin = widget.dataAwal.jenisKelamin;
    _domisili = _daftarDomisili.contains(widget.dataAwal.domisili)
        ? widget.dataAwal.domisili
        : _daftarDomisili.first;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _platController.dispose();
    super.dispose();
  }

  String _formatTanggal(DateTime tgl) {
    return '${tgl.day} ${_namaBulan[tgl.month - 1]} ${tgl.year}';
  }

  Future<void> _pilihTanggalLahir() async {
    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggalLahir,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (hasil != null) {
      setState(() => _tanggalLahir = hasil);
    }
  }

  void _pilihDomisili() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.permukaan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Pilih Domisili',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: SizedBox(
          width: 320,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _daftarDomisili.length,
            itemBuilder: (_, i) {
              final kota = _daftarDomisili[i];
              final terpilih = kota == _domisili;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  terpilih
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: AppColors.primer,
                ),
                title: Text(kota),
                onTap: () {
                  setState(() => _domisili = kota);
                  Navigator.of(ctx).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _simpanPerubahan() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final hasil = widget.dataAwal.copyWith(
      nama: _namaController.text.trim(),
      tanggalLahir: _tanggalLahir,
      jenisKelamin: _jenisKelamin,
      noTelepon: _teleponController.text.trim(),
      platNomor: _platController.text.trim().toUpperCase(),
      domisili: _domisili,
    );

    Navigator.of(context).pop(hasil);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const NavbarAtas(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Kembali ke Pengaturan'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Profil Akun',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Lihat dan perbarui informasi profil pengguna Anda.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.slate500,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Avatar Lingkaran Besar di Tengah
                      Center(
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: const BoxDecoration(
                            color: AppColors.primerSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            size: 44,
                            color: AppColors.primer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      KartuPutih(
                        padding: const EdgeInsets.all(24),
                        radius: 20,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _LabelForm('Nama Lengkap'),
                              TextFormField(
                                controller: _namaController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'Masukkan nama lengkap',
                                ),
                                validator: (val) {
                                  final teks = (val ?? '').trim();
                                  if (teks.isEmpty) {
                                    return 'Nama lengkap tidak boleh kosong';
                                  }
                                  if (teks.length < 3) {
                                    return 'Nama lengkap minimal 3 karakter';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              const _LabelForm('Tanggal Lahir'),
                              InkWell(
                                onTap: _pilihTanggalLahir,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 13,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.permukaan,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: AppColors.slate200),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatTanggal(_tanggalLahir),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.primer,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: AppColors.primer,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              const _LabelForm('Jenis Kelamin'),
                              Row(
                                children: [
                                  Expanded(
                                    child: _PilihanRadioKartu(
                                      label: 'Perempuan',
                                      terpilih: _jenisKelamin == 'Perempuan',
                                      onTap: () => setState(
                                        () => _jenisKelamin = 'Perempuan',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _PilihanRadioKartu(
                                      label: 'Laki-Laki',
                                      terpilih: _jenisKelamin == 'Laki-Laki',
                                      onTap: () => setState(
                                        () => _jenisKelamin = 'Laki-Laki',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              const _LabelForm('No Telepon'),
                              TextFormField(
                                controller: _teleponController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'Contoh: 081234567890',
                                ),
                                validator: (val) {
                                  final teks = (val ?? '').trim();
                                  if (teks.isEmpty) {
                                    return 'Nomor telepon tidak boleh kosong';
                                  }
                                  if (!teks.startsWith('08') &&
                                      !teks.startsWith('62')) {
                                    return 'Nomor telepon harus diawali 08 atau 62';
                                  }
                                  if (teks.length < 10 || teks.length > 15) {
                                    return 'Nomor telepon harus 10–15 digit';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              const _LabelForm('Email'),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 13,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.latar,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.garis),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      widget.dataAwal.email,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.primer,
                                      ),
                                    ),
                                    const Text(
                                      'Identitas Akun',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.slate500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              const _LabelForm('Plat Nomor Mobil'),
                              TextFormField(
                                controller: _platController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  hintText: 'Contoh: L 1234 AB',
                                ),
                                validator: (val) {
                                  if ((val ?? '').trim().isEmpty) {
                                    return 'Plat nomor kendaraan tidak boleh kosong';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              const _LabelForm('Domisili'),
                              InkWell(
                                onTap: _pilihDomisili,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 13,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.permukaan,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: AppColors.slate200),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _domisili,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.primer,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: AppColors.primer,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Batal'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _simpanPerubahan,
                                      child: const Text('Simpan Perubahan'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelForm extends StatelessWidget {
  const _LabelForm(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        teks,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primer,
        ),
      ),
    );
  }
}

class _PilihanRadioKartu extends StatelessWidget {
  const _PilihanRadioKartu({
    required this.label,
    required this.terpilih,
    required this.onTap,
  });

  final String label;
  final bool terpilih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: terpilih ? AppColors.primerSoft : AppColors.permukaan,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: terpilih ? AppColors.primer : AppColors.slate200,
            width: terpilih ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              terpilih
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: terpilih ? AppColors.primer : AppColors.slate500,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: terpilih ? FontWeight.w600 : FontWeight.w400,
                color: terpilih ? AppColors.primer : AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class UploadsPage extends StatefulWidget {
  const UploadsPage({super.key});
  @override
  State<UploadsPage> createState() => _UploadsPageState();
}

class _UploadsPageState extends State<UploadsPage> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // We fetch regNo once and reuse it for both tabs.
  late final Future<String?> _regNoFuture = _loadRegNo();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<String?> _loadRegNo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data == null) return null;

    // Accept common keys in case you named it differently
    final regNo = (data['regNo'] ?? data['registrationNumber'] ?? data['reg_no'])?.toString();
    if (regNo == null || regNo.trim().isEmpty) return null;
    return regNo.trim();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      body: Column(
        children: [
          _GradientHeader(
            title: 'Uploads',
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _PillTabs(
                  controller: _tab,
                  tabs: const [
                    _PillTabSpec('Challan', Icons.receipt_long_rounded),
                    _PillTabSpec('ID Card', Icons.photo_camera_rounded),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<String?>(
              future: _regNoFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // If regNo missing, show a hard warning.
                final regNo = snap.data;

                if (regNo == null) {
                  return _MissingRegNoPanel(
                    onRetry: () => setState(() {}),
                  );
                }

                return TabBarView(
                  controller: _tab,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    ChallanUploadForm(regNo: regNo),
                    IdCardUploadForm(regNo: regNo),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingRegNoPanel extends StatelessWidget {
  const _MissingRegNoPanel({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cs.errorContainer.withOpacity(.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.error.withOpacity(.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 40, color: cs.error),
              const SizedBox(height: 10),
              Text(
                'Registration Number not found',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your account profile is missing Reg No. Please add it during registration (saved in Firestore users/{uid}).',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ========================= SHARED UI COMPONENTS ============================

class _GradientHeader extends StatelessWidget implements PreferredSizeWidget {
  const _GradientHeader({
    required this.title,
    this.bottom,
  });

  final String title;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(100 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: scheme.onPrimary,
                        ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}

class _PillTabs extends StatelessWidget {
  const _PillTabs({required this.controller, required this.tabs});
  final TabController controller;
  final List<_PillTabSpec> tabs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: TabBar(
        controller: controller,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        indicator: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        splashBorderRadius: BorderRadius.circular(14),
        labelColor: scheme.onPrimary,
        unselectedLabelColor: scheme.onSurface.withOpacity(.8),
        tabs: [
          for (final t in tabs)
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(t.icon, size: 18), const SizedBox(width: 8), Text(t.label)],
              ),
            ),
        ],
      ),
    );
  }
}

class _PillTabSpec {
  final String label;
  final IconData icon;
  const _PillTabSpec(this.label, this.icon);
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    this.subtitle,
    this.leadingIcon,
    required this.child,
    this.edgePadding = const EdgeInsets.all(16),
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget child;
  final EdgeInsets edgePadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final titleRow = Row(
      children: [
        if (leadingIcon != null)
          Container(
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(leadingIcon, color: cs.onPrimaryContainer, size: 20),
          ),
        if (leadingIcon != null) const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                ),
            ],
          ),
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [cs.surface.withOpacity(.85), cs.surfaceVariant.withOpacity(.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(.06)),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            spreadRadius: -8,
            offset: const Offset(0, 14),
            color: Colors.black.withOpacity(.25),
          )
        ],
      ),
      child: Padding(
        padding: edgePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleRow,
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
    this.bottomNote,
    this.preview,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;
  final String? bottomNote;
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
        color: cs.surface,
      ),
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: cs.primary),
          const SizedBox(height: 10),
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.upload_rounded),
            label: Text(buttonLabel),
          ),
          if (bottomNote != null) ...[
            const SizedBox(height: 8),
            Text(bottomNote!, style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
          ],
          if (preview != null) ...[
            const SizedBox(height: 14),
            preview!,
          ],
        ],
      ),
    );
  }
}

InputDecoration _filledInput(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );

void _toast(BuildContext context, String msg, {bool success = false}) {
  final cs = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: success ? cs.tertiaryContainer : cs.errorContainer,
      content: Row(
        children: [
          Icon(success ? Icons.check_circle : Icons.error,
              color: success ? cs.onTertiaryContainer : cs.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(color: success ? cs.onTertiaryContainer : cs.onErrorContainer),
            ),
          ),
        ],
      ),
    ),
  );
}

/// ============================= CHALLAN TAB =================================

class ChallanUploadForm extends StatefulWidget {
  const ChallanUploadForm({super.key, required this.regNo});
  final String regNo;

  @override
  State<ChallanUploadForm> createState() => _ChallanUploadFormState();
}

class _ChallanUploadFormState extends State<ChallanUploadForm> {
  final _formKey = GlobalKey<FormState>();

  // Auto-filled and locked
  late final TextEditingController _studentId =
      TextEditingController(text: widget.regNo);

  String? _semesterSeason; // Fall / Spring
  String? _semesterYear;   // 2024, 2025, ...

  DateTime? _paymentDate;

  Uint8List? _fileBytes;
  String? _fileName;
  String? _contentType;
  bool _uploading = false;
  double _progress = 0.0;

  static const int maxBytes = 5 * 1024 * 1024;

  String get _semesterValue => '${_semesterSeason!} ${_semesterYear!}';

  @override
  void dispose() {
    _studentId.dispose();
    super.dispose();
  }

  Future<void> _captureChallanCameraOnly() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (xfile == null) return;

    final bytes = await xfile.readAsBytes();
    if (bytes.length > maxBytes) {
      if (!mounted) return;
      _toast(context, 'Image too large. Max 5 MB.');
      return;
    }

    setState(() {
      _fileBytes = bytes;
      _fileName = xfile.name.isNotEmpty ? xfile.name : 'challan.jpg';
      _contentType =
          'image/${_fileName!.toLowerCase().endsWith('.png') ? 'png' : 'jpeg'}';
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_fileBytes == null) {
      _toast(context, 'Please capture a challan image first.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_semesterSeason == null || _semesterYear == null) {
      _toast(context, 'Please select semester and year.');
      return;
    }

    if (_paymentDate == null) {
      _toast(context, 'Please select payment date.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _toast(context, 'You are not signed in.');
      return;
    }

    final semester = _semesterValue;
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    final ext = _fileName!.split('.').last;

    final safeStudentId =
        _studentId.text.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
    final safeSemester =
        semester.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');

    final storagePath =
        'challans/${user.uid}/${ts}_${safeStudentId}_${safeSemester}.$ext';

    setState(() {
      _uploading = true;
      _progress = 0.0;
    });

    try {
      final ref = FirebaseStorage.instance.ref(storagePath);

      final metadata = SettableMetadata(
        contentType: _contentType,
        customMetadata: {
          'uid': user.uid,
          'regNo': _studentId.text.trim(),
          'semester': semester,
          'paymentDate': _paymentDate!.toIso8601String(),
          'uploadedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );

      final task = ref.putData(_fileBytes!, metadata);
      task.snapshotEvents.listen((snap) {
        if (!mounted) return;
        if (snap.totalBytes > 0) {
          setState(() => _progress = snap.bytesTransferred / snap.totalBytes);
        }
      });

      final snap = await task;

      await FirebaseFirestore.instance
          .collection('challan_submissions')
          .add({
        'uid': user.uid,
        'regNo': _studentId.text.trim(),
        'semester': semester,
        'paymentDate': Timestamp.fromDate(
          DateTime(
            _paymentDate!.year,
            _paymentDate!.month,
            _paymentDate!.day,
          ),
        ),
        'filePath': storagePath,
        'fileSize': snap.totalBytes,
        'contentType': _contentType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _toast(context, 'Challan submitted successfully.', success: true);

      setState(() {
        _fileBytes = null;
        _fileName = null;
        _contentType = null;
        _paymentDate = null;
        _semesterSeason = null;
        _semesterYear = null;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _toast(context, e.message ?? 'Upload failed.');
    } catch (_) {
      if (!mounted) return;
      _toast(context, 'Upload failed.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MM/dd/yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: AbsorbPointer(
        absorbing: _uploading,
        child: Column(
          children: [
            _SectionCard(
              title: 'Upload Fee Challan',
              leadingIcon: Icons.receipt_long_rounded,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: _UploadBox(
                    icon: Icons.image_rounded,
                    title: 'Upload Challan',
                    subtitle: 'Take a clear photo of your challan',
                    buttonLabel: 'Capture Challan',
                    onTap: _captureChallanCameraOnly,
                    preview: _fileBytes == null
                        ? null
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _fileBytes!,
                              height: 160,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            _SectionCard(
              title: 'Payment Details',
              leadingIcon: Icons.payments_rounded,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _studentId,
                      readOnly: true,
                      decoration: _filledInput('Registration No'),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: _filledInput('Semester'),
                            value: _semesterSeason,
                            items: const [
                              DropdownMenuItem(
                                  value: 'Fall', child: Text('Fall')),
                              DropdownMenuItem(
                                  value: 'Spring', child: Text('Spring')),
                            ],
                            onChanged: (v) =>
                                setState(() => _semesterSeason = v),
                            validator: (v) =>
                                v == null ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: _filledInput('Year'),
                            value: _semesterYear,
                            items: List.generate(
                              7,
                              (i) {
                                final y =
                                    (DateTime.now().year + i).toString();
                                return DropdownMenuItem(
                                  value: y,
                                  child: Text(y),
                                );
                              },
                            ),
                            onChanged: (v) =>
                                setState(() => _semesterYear = v),
                            validator: (v) =>
                                v == null ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    InputDecorator(
                      decoration:
                          _filledInput('Payment Date', hint: 'mm/dd/yyyy'),
                      child: InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: now,
                            firstDate: DateTime(now.year - 2),
                            lastDate: now,
                          );
                          if (picked != null) {
                            setState(() => _paymentDate = picked);
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_paymentDate == null
                                ? 'mm/dd/yyyy'
                                : fmt.format(_paymentDate!)),
                            const Icon(Icons.calendar_today_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    if (_uploading)
                      LinearProgressIndicator(
                          value: _progress == 0 ? null : _progress),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _uploading ? null : _submit,
                        child: const Text('Submit Challan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// ============================== ID CARD TAB =================================

class IdCardUploadForm extends StatefulWidget {
  const IdCardUploadForm({super.key, required this.regNo});
  final String regNo;

  @override
  State<IdCardUploadForm> createState() => _IdCardUploadFormState();
}

class _IdCardUploadFormState extends State<IdCardUploadForm> {
  final _formKey = GlobalKey<FormState>();

  // Auto-filled regNo
  late final TextEditingController _studentId = TextEditingController(text: widget.regNo);

  Uint8List? _imageBytes;
  String? _fileName;
  String? _contentType;
  bool _uploading = false;
  double _progress = 0.0;

  static const int maxBytes = 10 * 1024 * 1024;

  @override
  void dispose() {
    _studentId.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: source, imageQuality: 95);
    if (xfile == null) return;

    final bytes = await xfile.readAsBytes();
    if (bytes.length > maxBytes) {
      if (!mounted) return;
      _toast(context, 'Image too large. Max 10 MB.');
      return;
    }

    setState(() {
      _imageBytes = bytes;
      _fileName = xfile.name;
      _contentType = 'image/${xfile.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg'}';
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null || _contentType == null) {
      _toast(context, 'Please choose a photo first.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _toast(context, 'You are not signed in.');
      return;
    }

    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    final ext = _fileName != null && _fileName!.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final safeStudentId = _studentId.text.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');

    final storagePath = 'idcards/${user.uid}/${ts}_${safeStudentId}.$ext';

    setState(() {
      _uploading = true;
      _progress = 0.0;
    });

    try {
      final ref = FirebaseStorage.instance.ref(storagePath);
      final metadata = SettableMetadata(
        contentType: _contentType,
        customMetadata: {
          'uid': user.uid,
          'regNo': _studentId.text.trim(),
          'uploadedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );

      final task = ref.putData(_imageBytes!, metadata);
      task.snapshotEvents.listen((snap) {
        if (!mounted) return;
        if (snap.totalBytes > 0) {
          setState(() => _progress = snap.bytesTransferred / snap.totalBytes);
        }
      });

      final snap = await task;
      final fullSize = snap.totalBytes;

      await FirebaseFirestore.instance.collection('idcard_submissions').add({
        'uid': user.uid,
        'regNo': _studentId.text.trim(),
        'filePath': storagePath,
        'fileSize': fullSize,
        'contentType': _contentType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _toast(context, 'ID card photo submitted successfully.', success: true);

      setState(() {
        _imageBytes = null;
        _fileName = null;
        _contentType = null;
        // regNo stays
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _toast(context, e.message ?? 'Upload failed.');
    } catch (_) {
      if (!mounted) return;
      _toast(context, 'Upload failed.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _check(String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: AbsorbPointer(
        absorbing: _uploading,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _SectionCard(
                title: 'Registration No',
                leadingIcon: Icons.badge_rounded,
                child: TextFormField(
                  controller: _studentId,
                  readOnly: true,
                  decoration: _filledInput('Registration No', hint: ''),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Missing registration no' : null,
                ),
              ),
              const SizedBox(height: 8),
              _SectionCard(
                title: 'Photo Requirements',
                leadingIcon: Icons.rule_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _check('Recent passport-size photograph'),
                    _check('Clear, high-resolution image'),
                    _check('White or light-colored background'),
                    _check('Face clearly visible; no sunglasses/hats'),
                    _check('Professional appearance'),
                    _check('Max file size: 5 MB'),
                    _check('Format: JPG or PNG'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _SectionCard(
                title: 'Upload Your ID Photo',
                leadingIcon: Icons.photo_camera_rounded,
                child: Column(
                  children: [
                    _UploadBox(
                      icon: Icons.camera_alt_rounded,
                      title: 'Upload your ID photo',
                      subtitle: 'Choose a photo that meets the requirements above',
                      buttonLabel: 'Choose Photo',
                      bottomNote: 'JPG, PNG up to 5MB',
                      onTap: () => _pickImage(ImageSource.gallery),
                      preview: _imageBytes == null
                          ? null
                          : Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.memory(_imageBytes!, height: 180, fit: BoxFit.cover),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Camera'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Gallery'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_uploading) LinearProgressIndicator(value: _progress == 0 ? null : _progress),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _uploading ? null : _submit,
                        icon: const Icon(Icons.cloud_upload_rounded),
                        label: const Text('Submit ID Photo'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

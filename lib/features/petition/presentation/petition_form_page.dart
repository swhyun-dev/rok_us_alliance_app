// lib/features/petition/presentation/petition_form_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../data/petition_store.dart';
import '../domain/petition.dart';

class PetitionFormPage extends StatefulWidget {
  const PetitionFormPage({super.key});

  @override
  State<PetitionFormPage> createState() => _PetitionFormPageState();
}

class _PetitionFormPageState extends State<PetitionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetCountController = TextEditingController(text: '1000');

  String _category = 'security';
  DateTime _deadline = DateTime.now().add(const Duration(days: 30));
  bool _submitting = false;

  static const List<({String code, String label})> _categories = [
    (code: 'security', label: '안보'),
    (code: 'economy', label: '경제'),
    (code: 'education', label: '교육'),
    (code: 'media', label: '언론'),
    (code: 'judicial', label: '사법'),
    (code: 'other', label: '기타'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetCountController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    final target = int.tryParse(_targetCountController.text.trim()) ?? 0;
    if (target <= 0) return;

    setState(() => _submitting = true);
    try {
      final petition = Petition(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        targetCount: target,
        currentCount: 0,
        startDate: DateTime.now(),
        deadline: _deadline,
        status: 'active',
      );
      await PetitionStore.add(petition);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('청원을 등록했습니다.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('등록 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('청원 등록')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '1~80자',
              ),
              maxLength: 80,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return '제목을 입력해주세요.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: '분야'),
              items: _categories
                  .map((c) => DropdownMenuItem(
                        value: c.code,
                        child: Text(c.label),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? 'other'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              maxLines: 8,
              maxLength: 3000,
              decoration: const InputDecoration(
                labelText: '내용',
                hintText: '청원의 배경과 요청 사항을 적어주세요. (최대 3000자)',
                alignLabelWithHint: true,
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return '내용을 입력해주세요.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _targetCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '목표 서명 수',
                suffixText: '명',
              ),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n <= 0) return '1 이상의 정수를 입력해주세요.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDeadline,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: '마감일'),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_deadline.year}.${_deadline.month.toString().padLeft(2, '0')}.${_deadline.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.textSecondary, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.koreanBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '청원 등록',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

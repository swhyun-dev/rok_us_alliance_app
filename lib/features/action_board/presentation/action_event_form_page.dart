// lib/features/action_board/presentation/action_event_form_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../data/action_event_store.dart';
import '../domain/action_event.dart';

class ActionEventFormPage extends StatefulWidget {
  const ActionEventFormPage({
    super.key,
    this.initialEvent,
  });

  final ActionEvent? initialEvent;

  @override
  State<ActionEventFormPage> createState() => _ActionEventFormPageState();
}

class _ActionEventFormPageState extends State<ActionEventFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _locationNameController;
  late final TextEditingController _locationQueryController;
  late final TextEditingController _slogansController;
  late final TextEditingController _itemsController;
  late final TextEditingController _descriptionController;

  late String _status;
  late String _type;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  bool _isSaving = false;

  bool get _isEdit => widget.initialEvent != null;

  @override
  void initState() {
    super.initState();
    final event = widget.initialEvent;

    _titleController = TextEditingController(text: event?.title ?? '');
    _locationNameController =
        TextEditingController(text: event?.locationName ?? '');
    _locationQueryController =
        TextEditingController(text: event?.locationQuery ?? '');
    _slogansController =
        TextEditingController(text: event?.slogans.join(', ') ?? '');
    _itemsController =
        TextEditingController(text: event?.items.join(', ') ?? '');
    _descriptionController =
        TextEditingController(text: event?.description ?? '');

    _status = event?.status ?? '중요 공지';
    _type = event?.type ?? '집회';
    _selectedDate = event?.startAt ?? DateTime.now();
    _selectedTime = TimeOfDay(
      hour: event?.startAt.hour ?? 13,
      minute: event?.startAt.minute ?? 0,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationNameController.dispose();
    _locationQueryController.dispose();
    _slogansController.dispose();
    _itemsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked == null) return;

    setState(() {
      _selectedTime = picked;
    });
  }

  List<String> _splitCsv(String text) {
    return text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String _dateLabel() {
    return '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  String _timeLabel() {
    final h = _selectedTime.hour.toString().padLeft(2, '0');
    final m = _selectedTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  DateTime _combinedStartAt() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final startAt = _combinedStartAt();
    final slogans = _splitCsv(_slogansController.text);
    final items = _splitCsv(_itemsController.text);
    final now = DateTime.now();

    if (startAt.isBefore(now) && !_isEdit) {
      _showError('과거 일정은 등록할 수 없습니다.');
      return;
    }

    if (_locationNameController.text.trim().isEmpty) {
      _showError('위치를 입력해주세요.');
      return;
    }

    if (slogans.isEmpty) {
      _showError('슬로건을 최소 1개 이상 입력해주세요.');
      return;
    }

    if (items.isEmpty) {
      _showError('준비물을 최소 1개 이상 입력해주세요.');
      return;
    }

    final event = ActionEvent(
      id: widget.initialEvent?.id ?? 'evt-${DateTime.now().millisecondsSinceEpoch}',
      status: _status,
      title: _titleController.text.trim(),
      startAt: startAt,
      locationName: _locationNameController.text.trim(),
      locationQuery: _locationQueryController.text.trim().isEmpty
          ? _locationNameController.text.trim()
          : _locationQueryController.text.trim(),
      slogans: slogans,
      items: items,
      description: _descriptionController.text.trim(),
      type: _type,
    );

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEdit) {
        await ActionEventStore.update(event);
      } else {
        await ActionEventStore.add(event);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      _showError('저장 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '행동 공지 수정' : '행동 공지 등록'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                _SectionCard(
                  title: '기본 정보',
                  child: Column(
                    children: [
                      _LabeledField(
                        label: '제목',
                        child: TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            hintText: '예: 평택 미군기지 앞 집결 안내',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '제목을 입력해주세요.';
                            }
                            if (value.trim().length < 5) {
                              return '제목은 최소 5자 이상 입력해주세요.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _LabeledField(
                        label: '상태',
                        child: DropdownButtonFormField<String>(
                          initialValue: _status,
                          items: const [
                            DropdownMenuItem(
                              value: '중요 공지',
                              child: Text('중요 공지'),
                            ),
                            DropdownMenuItem(
                              value: '정기 일정',
                              child: Text('정기 일정'),
                            ),
                            DropdownMenuItem(
                              value: '중요 일정',
                              child: Text('중요 일정'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _status = value);
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _LabeledField(
                        label: '유형',
                        child: DropdownButtonFormField<String>(
                          initialValue: _type,
                          items: const [
                            DropdownMenuItem(value: '집회', child: Text('집회')),
                            DropdownMenuItem(value: '모임', child: Text('모임')),
                            DropdownMenuItem(
                              value: '중요 일정',
                              child: Text('중요 일정'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _type = value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: '일시 / 위치',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _InfoSelectBox(
                              label: '날짜',
                              value: _dateLabel(),
                              onTap: _pickDate,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InfoSelectBox(
                              label: '시간',
                              value: _timeLabel(),
                              onTap: _pickTime,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _LabeledField(
                        label: '위치 표시명',
                        child: TextFormField(
                          controller: _locationNameController,
                          decoration: const InputDecoration(
                            hintText: '예: 평택 미군기지(캠프 험프리스) K6 사거리',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '위치를 입력해주세요.';
                            }
                            if (value.trim().length < 2) {
                              return '위치는 최소 2자 이상 입력해주세요.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _LabeledField(
                        label: '지도 검색용 문구',
                        child: TextFormField(
                          controller: _locationQueryController,
                          decoration: const InputDecoration(
                            hintText: '비워두면 위치 표시명을 그대로 사용합니다.',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: '슬로건 / 준비물 / 설명',
                  child: Column(
                    children: [
                      _LabeledField(
                        label: '슬로건 (쉼표로 구분)',
                        child: TextFormField(
                          controller: _slogansController,
                          decoration: const InputDecoration(
                            hintText: '예: MAGA WITH ROK, WE GO TOGETHER',
                          ),
                          validator: (value) {
                            final list = _splitCsv(value ?? '');
                            if (list.isEmpty) {
                              return '슬로건을 최소 1개 이상 입력해주세요.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _LabeledField(
                        label: '준비물 (쉼표로 구분)',
                        child: TextFormField(
                          controller: _itemsController,
                          decoration: const InputDecoration(
                            hintText: '예: 반투명 우산(흰우산), 포스터',
                          ),
                          validator: (value) {
                            final list = _splitCsv(value ?? '');
                            if (list.isEmpty) {
                              return '준비물을 최소 1개 이상 입력해주세요.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _LabeledField(
                        label: '상세 설명',
                        child: TextFormField(
                          controller: _descriptionController,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            hintText: '공지 상세 내용을 입력해주세요.',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '설명을 입력해주세요.';
                            }
                            if (value.trim().length < 10) {
                              return '설명은 최소 10자 이상 입력해주세요.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(_isSaving
                        ? '저장 중...'
                        : (_isEdit ? '수정 저장' : '공지 등록')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _InfoSelectBox extends StatelessWidget {
  const _InfoSelectBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          color: AppColors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
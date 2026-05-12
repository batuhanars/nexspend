import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/family_repository.dart';
import 'family_event.dart';
import 'family_state.dart';

class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  FamilyBloc({required FamilyRepository familyRepository})
      : _repo = familyRepository,
        super(const FamilyInitial()) {
    on<FamilyGroupsLoadRequested>(_onLoadGroups);
    on<FamilyGroupCreateRequested>(_onCreateGroup);
    on<FamilyGroupDetailLoadRequested>(_onLoadGroupDetail);
    on<FamilyInviteSendRequested>(_onSendInvite);
    on<FamilyInviteAcceptRequested>(_onAcceptInvite);
    on<FamilyInviteRejectRequested>(_onRejectInvite);
    on<FamilySharedBudgetCreateRequested>(_onCreateSharedBudget);
    on<FamilySharedBudgetsLoadRequested>(_onLoadSharedBudgets);
    on<FamilyContributionsLoadRequested>(_onLoadContributions);
    on<FamilyMemberRemoveRequested>(_onRemoveMember);
    on<FamilyGroupDeleteRequested>(_onDeleteGroup);
    on<FamilySharedBudgetDeleteRequested>(_onDeleteSharedBudget);
  }

  final FamilyRepository _repo;

  Future<void> _onLoadGroups(
    FamilyGroupsLoadRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(const FamilyGroupsLoading());
    try {
      final groups = await _repo.getGroups();
      emit(FamilyGroupsLoaded(groups: groups));
    } catch (e) {
      emit(FamilyGroupsError(_parseError(e)));
    }
  }

  Future<void> _onCreateGroup(
    FamilyGroupCreateRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(const FamilyGroupCreating());
    try {
      final group = await _repo.createGroup(name: event.name, icon: event.icon);
      emit(FamilyGroupCreated(group: group));
    } catch (e) {
      emit(FamilyGroupCreateError(_parseError(e)));
    }
  }

  Future<void> _onLoadGroupDetail(
    FamilyGroupDetailLoadRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(const FamilyGroupDetailLoading());
    try {
      final group = await _repo.getGroupDetail(event.groupId);
      emit(FamilyGroupDetailLoaded(group: group));
    } catch (e) {
      emit(FamilyGroupDetailError(_parseError(e)));
    }
  }

  Future<void> _onSendInvite(
    FamilyInviteSendRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(const FamilyInviteSending());
    try {
      final invite = await _repo.sendInvite(
        groupId: event.groupId,
        email: event.email,
      );
      emit(FamilyInviteSent(invite: invite));
    } catch (e) {
      emit(FamilyInviteSendError(_parseError(e)));
    }
  }

  Future<void> _onAcceptInvite(
    FamilyInviteAcceptRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(const FamilyInviteProcessing());
    try {
      final group = await _repo.acceptInvite(event.token);
      emit(FamilyInviteAccepted(group: group));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('410') || msg.contains('süresi dolmuş')) {
        emit(const FamilyInviteExpired());
      } else {
        emit(FamilyInviteError(_parseError(e)));
      }
    }
  }

  Future<void> _onRejectInvite(
    FamilyInviteRejectRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(const FamilyInviteProcessing());
    try {
      await _repo.rejectInvite(event.token);
      emit(const FamilyInviteRejected());
    } catch (e) {
      emit(FamilyInviteError(_parseError(e)));
    }
  }

  Future<void> _onCreateSharedBudget(
    FamilySharedBudgetCreateRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(const FamilySharedBudgetCreating());
    try {
      final budget = await _repo.createSharedBudget(
        groupId: event.groupId,
        categoryId: event.categoryId,
        name: event.name,
        amount: event.amount,
        startDate: event.startDate,
      );
      emit(FamilySharedBudgetCreated(budget: budget));
    } catch (e) {
      emit(FamilySharedBudgetCreateError(_parseError(e)));
    }
  }

  Future<void> _onLoadSharedBudgets(
    FamilySharedBudgetsLoadRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(const FamilyGroupDetailLoading());
    try {
      final group = await _repo.getGroupDetail(event.groupId);
      emit(FamilyGroupDetailLoaded(group: group));
    } catch (e) {
      emit(FamilyGroupDetailError(_parseError(e)));
    }
  }

  Future<void> _onLoadContributions(
    FamilyContributionsLoadRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(const FamilyContributionsLoading());
    try {
      final report = await _repo.getContributions(
        groupId: event.groupId,
        period: event.period,
      );
      emit(FamilyContributionsLoaded(report: report));
    } catch (e) {
      emit(FamilyContributionsError(_parseError(e)));
    }
  }

  Future<void> _onRemoveMember(
    FamilyMemberRemoveRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(const FamilyMemberRemoving());
    try {
      await _repo.removeMember(
        groupId: event.groupId,
        userId: event.userId,
      );
      emit(FamilyMemberRemoved(userId: event.userId));
    } catch (e) {
      emit(FamilyMemberRemoveError(_parseError(e)));
    }
  }

  Future<void> _onDeleteGroup(
    FamilyGroupDeleteRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(const FamilyGroupDeleting());
    try {
      await _repo.deleteGroup(event.groupId);
      emit(const FamilyGroupDeleted());
    } catch (e) {
      emit(FamilyGroupDeleteError(_parseError(e)));
    }
  }

  Future<void> _onDeleteSharedBudget(
    FamilySharedBudgetDeleteRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(const FamilySharedBudgetDeleting());
    try {
      await _repo.deleteSharedBudget(
        groupId: event.groupId,
        budgetId: event.budgetId,
      );
      emit(const FamilySharedBudgetDeleted());
    } catch (e) {
      emit(FamilySharedBudgetDeleteError(_parseError(e)));
    }
  }

  String _parseError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) {
          debugPrint('Family API validation errors: $errors');
          return errors.join(', ');
        }
        final backendMsg = data['message'];
        if (backendMsg != null) {
          debugPrint('Family API hatası: $backendMsg');
          return backendMsg.toString();
        }
      }
      final status = e.response?.statusCode;
      if (status == 401) return 'Oturum süreniz dolmuş.';
      if (status == 403) return 'Bu işlem için yetkiniz yok.';
      if (status == 404) return 'Kayıt bulunamadı.';
      if (status == 410) return 'Davet süresi dolmuş.';
      if (status == 400) {
        if (e.toString().contains('sınır') || e.toString().contains('limit')) {
          return 'Grup üye sınırına ulaşıldı (max 5).';
        }
        return 'Geçersiz istek (400).';
      }
    }
    final msg = e.toString();
    if (msg.contains('SocketException')) return 'İnternet bağlantınızı kontrol edin.';
    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }
}

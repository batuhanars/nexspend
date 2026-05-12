import '../../../data/models/family_model.dart';

sealed class FamilyState {
  const FamilyState();
}

class FamilyInitial extends FamilyState {
  const FamilyInitial();
}

// --- Grup listesi ---

class FamilyGroupsLoading extends FamilyState {
  const FamilyGroupsLoading();
}

class FamilyGroupsLoaded extends FamilyState {
  const FamilyGroupsLoaded({required this.groups});
  final List<FamilyGroupModel> groups;
}

class FamilyGroupsError extends FamilyState {
  const FamilyGroupsError(this.message);
  final String message;
}

// --- Grup oluşturma ---

class FamilyGroupCreating extends FamilyState {
  const FamilyGroupCreating();
}

class FamilyGroupCreated extends FamilyState {
  const FamilyGroupCreated({required this.group});
  final FamilyGroupModel group;
}

class FamilyGroupCreateError extends FamilyState {
  const FamilyGroupCreateError(this.message);
  final String message;
}

// --- Grup detayı ---

class FamilyGroupDetailLoading extends FamilyState {
  const FamilyGroupDetailLoading();
}

class FamilyGroupDetailLoaded extends FamilyState {
  const FamilyGroupDetailLoaded({required this.group});
  final FamilyGroupModel group;
}

class FamilyGroupDetailError extends FamilyState {
  const FamilyGroupDetailError(this.message);
  final String message;
}

// --- Davet gönderme ---

class FamilyInviteSending extends FamilyState {
  const FamilyInviteSending();
}

class FamilyInviteSent extends FamilyState {
  const FamilyInviteSent({required this.invite});
  final FamilyInviteModel invite;
}

class FamilyInviteSendError extends FamilyState {
  const FamilyInviteSendError(this.message);
  final String message;
}

// --- Davet kabul / red ---

class FamilyInviteProcessing extends FamilyState {
  const FamilyInviteProcessing();
}

class FamilyInviteAccepted extends FamilyState {
  const FamilyInviteAccepted({required this.group});
  final FamilyGroupModel group;
}

class FamilyInviteRejected extends FamilyState {
  const FamilyInviteRejected();
}

class FamilyInviteExpired extends FamilyState {
  const FamilyInviteExpired();
}

class FamilyInviteError extends FamilyState {
  const FamilyInviteError(this.message);
  final String message;
}

// --- Ortak bütçe oluşturma ---

class FamilySharedBudgetCreating extends FamilyState {
  const FamilySharedBudgetCreating();
}

class FamilySharedBudgetCreated extends FamilyState {
  const FamilySharedBudgetCreated({required this.budget});
  final SharedBudgetModel budget;
}

class FamilySharedBudgetCreateError extends FamilyState {
  const FamilySharedBudgetCreateError(this.message);
  final String message;
}

// --- Katkı raporu ---

class FamilyContributionsLoading extends FamilyState {
  const FamilyContributionsLoading();
}

class FamilyContributionsLoaded extends FamilyState {
  const FamilyContributionsLoaded({required this.report});
  final ContributionReportModel report;
}

class FamilyContributionsError extends FamilyState {
  const FamilyContributionsError(this.message);
  final String message;
}

// --- Üye çıkarma ---

class FamilyMemberRemoving extends FamilyState {
  const FamilyMemberRemoving();
}

class FamilyMemberRemoved extends FamilyState {
  const FamilyMemberRemoved({required this.userId});
  final String userId;
}

class FamilyMemberRemoveError extends FamilyState {
  const FamilyMemberRemoveError(this.message);
  final String message;
}

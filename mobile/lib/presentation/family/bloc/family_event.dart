sealed class FamilyEvent {
  const FamilyEvent();
}

class FamilyGroupsLoadRequested extends FamilyEvent {
  const FamilyGroupsLoadRequested();
}

class FamilyGroupCreateRequested extends FamilyEvent {
  const FamilyGroupCreateRequested({required this.name, this.icon});
  final String name;
  final String? icon;
}

class FamilyGroupDetailLoadRequested extends FamilyEvent {
  const FamilyGroupDetailLoadRequested({required this.groupId});
  final String groupId;
}

class FamilyInviteSendRequested extends FamilyEvent {
  const FamilyInviteSendRequested({
    required this.groupId,
    required this.email,
  });
  final String groupId;
  final String email;
}

class FamilyInviteAcceptRequested extends FamilyEvent {
  const FamilyInviteAcceptRequested({required this.token});
  final String token;
}

class FamilyInviteRejectRequested extends FamilyEvent {
  const FamilyInviteRejectRequested({required this.token});
  final String token;
}

class FamilyInviteCancelRequested extends FamilyEvent {
  const FamilyInviteCancelRequested({
    required this.groupId,
    required this.token,
  });
  final String groupId;
  final String token;
}

class FamilySharedBudgetCreateRequested extends FamilyEvent {
  const FamilySharedBudgetCreateRequested({
    required this.groupId,
    required this.categoryId,
    required this.name,
    required this.amount,
    required this.startDate,
  });
  final String groupId;
  final String categoryId;
  final String name;
  final double amount;
  final String startDate;
}

class FamilySharedBudgetsLoadRequested extends FamilyEvent {
  const FamilySharedBudgetsLoadRequested({required this.groupId});
  final String groupId;
}

class FamilyContributionsLoadRequested extends FamilyEvent {
  const FamilyContributionsLoadRequested({
    required this.groupId,
    this.period,
  });
  final String groupId;
  final String? period;
}

class FamilyMemberRemoveRequested extends FamilyEvent {
  const FamilyMemberRemoveRequested({
    required this.groupId,
    required this.userId,
  });
  final String groupId;
  final String userId;
}

class FamilyGroupDeleteRequested extends FamilyEvent {
  const FamilyGroupDeleteRequested({required this.groupId});
  final String groupId;
}

class FamilySharedBudgetDeleteRequested extends FamilyEvent {
  const FamilySharedBudgetDeleteRequested({
    required this.groupId,
    required this.budgetId,
  });
  final String groupId;
  final String budgetId;
}

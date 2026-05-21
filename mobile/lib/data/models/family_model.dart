// ignore_for_file: constant_identifier_names
enum FamilyRole { OWNER, MEMBER }

enum InviteStatus { PENDING, ACCEPTED, REJECTED, EXPIRED }

class FamilyGroupModel {
  const FamilyGroupModel({
    required this.id,
    required this.name,
    this.icon,
    required this.memberCount,
    required this.role,
    required this.createdAt,
    this.members = const [],
    this.sharedBudgets = const [],
    this.pendingInvites = const [],
  });

  final String id;
  final String name;
  final String? icon;
  final int memberCount;
  final FamilyRole role;
  final DateTime createdAt;
  final List<FamilyMemberModel> members;
  final List<SharedBudgetModel> sharedBudgets;
  final List<FamilyInviteModel> pendingInvites;

  factory FamilyGroupModel.fromJson(Map<String, dynamic> json) =>
      FamilyGroupModel(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String?,
        memberCount: (json['memberCount'] as num?)?.toInt() ??
            (json['members'] as List?)?.length ??
            0,
        role: FamilyRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => FamilyRole.MEMBER,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        members: (json['members'] as List?)
                ?.map((e) =>
                    FamilyMemberModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        sharedBudgets: (json['sharedBudgets'] as List?)
                ?.map((e) =>
                    SharedBudgetModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        pendingInvites: (json['pendingInvites'] as List?)
                ?.map((e) =>
                    FamilyInviteModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class FamilyMemberModel {
  const FamilyMemberModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String email;
  final FamilyRole role;
  final DateTime joinedAt;

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) =>
      FamilyMemberModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: FamilyRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => FamilyRole.MEMBER,
        ),
        joinedAt: DateTime.parse(json['joinedAt'] as String),
      );
}

class FamilyInviteModel {
  const FamilyInviteModel({
    required this.id,
    required this.groupId,
    required this.email,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    this.token,
    this.inviteLink,
  });

  final String id;
  final String groupId;
  final String email;
  final InviteStatus status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String? token;
  final String? inviteLink;

  factory FamilyInviteModel.fromJson(Map<String, dynamic> json) =>
      FamilyInviteModel(
        id: json['id'] as String,
        groupId: json['groupId'] as String,
        email: json['email'] as String,
        status: InviteStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => InviteStatus.PENDING,
        ),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        token: json['token'] as String?,
        inviteLink: json['inviteLink'] as String?,
      );
}

class SharedBudgetModel {
  const SharedBudgetModel({
    required this.id,
    required this.groupId,
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    required this.name,
    required this.amount,
    required this.spent,
    required this.remainingPercent,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  final String id;
  final String groupId;
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String name;
  final double amount;
  final double spent;
  final double remainingPercent;
  final String period;
  final String startDate;
  final DateTime endDate;
  final bool isActive;

  double get spentPercent => amount > 0 ? (spent / amount).clamp(0.0, 1.0) : 0.0;

  factory SharedBudgetModel.fromJson(Map<String, dynamic> json) =>
      SharedBudgetModel(
        id: json['id'] as String,
        groupId: json['groupId'] as String,
        categoryId: json['categoryId'] as String,
        categoryName: json['categoryName'] as String,
        categoryIcon: json['categoryIcon'] as String?,
        categoryColor: json['categoryColor'] as String?,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        spent: (json['spent'] as num).toDouble(),
        remainingPercent: (json['remainingPercent'] as num).toDouble(),
        period: json['period'] as String,
        startDate: json['startDate'] as String,
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : DateTime.parse(json['startDate'] as String),
        isActive: json['isActive'] as bool,
      );
}

class MySharedBudgetModel {
  const MySharedBudgetModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.categoryId,
    required this.categoryName,
    required this.name,
  });

  final String id;
  final String groupId;
  final String groupName;
  final String categoryId;
  final String categoryName;
  final String name;

  factory MySharedBudgetModel.fromJson(Map<String, dynamic> json) =>
      MySharedBudgetModel(
        id: json['id'] as String,
        groupId: json['groupId'] as String,
        groupName: (json['groupName'] as String?) ?? '',
        categoryId: json['categoryId'] as String,
        categoryName: json['categoryName'] as String,
        name: json['name'] as String,
      );
}

class SharedBudgetExpenseModel {
  const SharedBudgetExpenseModel({
    required this.id,
    required this.transactionId,
    required this.userId,
    required this.userName,
    required this.amount,
    this.description,
    this.note,
    required this.transactionDate,
    required this.createdAt,
  });

  final String id;
  final String transactionId;
  final String userId;
  final String userName;
  final double amount;
  final String? description;
  final String? note;
  final DateTime transactionDate;
  final DateTime createdAt;

  factory SharedBudgetExpenseModel.fromJson(Map<String, dynamic> json) =>
      SharedBudgetExpenseModel(
        id: json['id'] as String,
        transactionId: json['transactionId'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        amount: (json['amount'] as num).toDouble(),
        description: json['description'] as String?,
        note: json['note'] as String?,
        transactionDate: DateTime.parse(json['transactionDate'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class SharedBudgetDetailModel {
  const SharedBudgetDetailModel({
    required this.budget,
    required this.expenses,
  });

  final SharedBudgetModel budget;
  final List<SharedBudgetExpenseModel> expenses;

  factory SharedBudgetDetailModel.fromJson(Map<String, dynamic> json) =>
      SharedBudgetDetailModel(
        budget: SharedBudgetModel.fromJson(
            json['budget'] as Map<String, dynamic>),
        expenses: (json['expenses'] as List)
            .map((e) =>
                SharedBudgetExpenseModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ContributionMemberModel {
  const ContributionMemberModel({
    required this.userId,
    required this.name,
    required this.totalAmount,
    required this.percentage,
    required this.byCategory,
  });

  final String userId;
  final String name;
  final double totalAmount;
  final double percentage;
  final List<CategoryContributionModel> byCategory;

  factory ContributionMemberModel.fromJson(Map<String, dynamic> json) =>
      ContributionMemberModel(
        userId: json['userId'] as String,
        name: json['name'] as String,
        totalAmount: (json['totalAmount'] as num).toDouble(),
        percentage: (json['percentage'] as num).toDouble(),
        byCategory: (json['byCategory'] as List)
            .map((e) =>
                CategoryContributionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CategoryContributionModel {
  const CategoryContributionModel({
    required this.categoryName,
    required this.amount,
  });

  final String categoryName;
  final double amount;

  factory CategoryContributionModel.fromJson(Map<String, dynamic> json) =>
      CategoryContributionModel(
        categoryName: json['categoryName'] as String,
        amount: (json['amount'] as num).toDouble(),
      );
}

class ContributionReportModel {
  const ContributionReportModel({
    required this.period,
    required this.members,
  });

  final String period;
  final List<ContributionMemberModel> members;

  factory ContributionReportModel.fromJson(Map<String, dynamic> json) =>
      ContributionReportModel(
        period: json['period'] as String,
        members: (json['members'] as List)
            .map((e) =>
                ContributionMemberModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

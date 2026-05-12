import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/data/models/family_model.dart';
import 'package:wallet_app/data/repositories/family_repository.dart';
import 'package:wallet_app/presentation/family/bloc/family_bloc.dart';
import 'package:wallet_app/presentation/family/bloc/family_event.dart';
import 'package:wallet_app/presentation/family/bloc/family_state.dart';

class MockFamilyRepository extends Mock implements FamilyRepository {}

final _now = DateTime(2026, 5, 12);

final _group1 = FamilyGroupModel(
  id: 'g-1',
  name: 'Ev Bütçesi',
  icon: 'home',
  memberCount: 2,
  role: FamilyRole.OWNER,
  createdAt: _now,
);

final _group1Detail = FamilyGroupModel(
  id: 'g-1',
  name: 'Ev Bütçesi',
  icon: 'home',
  memberCount: 2,
  role: FamilyRole.OWNER,
  createdAt: _now,
  members: [
    FamilyMemberModel(
      id: 'm-1',
      userId: 'u-1',
      name: 'Batuhan',
      email: 'batuhan@example.com',
      role: FamilyRole.OWNER,
      joinedAt: _now,
    ),
    FamilyMemberModel(
      id: 'm-2',
      userId: 'u-2',
      name: 'Ayşe',
      email: 'ayse@example.com',
      role: FamilyRole.MEMBER,
      joinedAt: _now,
    ),
  ],
  sharedBudgets: [
    SharedBudgetModel(
      id: 'sb-1',
      groupId: 'g-1',
      categoryId: 'cat-1',
      categoryName: 'Market',
      name: 'Ev Market Bütçesi',
      amount: 5000,
      spent: 2100,
      remainingPercent: 58,
      period: 'MONTHLY',
      startDate: '2026-05-01',
      isActive: true,
    ),
  ],
);

final _invite = FamilyInviteModel(
  id: 'inv-1',
  groupId: 'g-1',
  email: 'ayse@example.com',
  status: InviteStatus.PENDING,
  expiresAt: _now.add(const Duration(days: 7)),
  createdAt: _now,
);

final _contributionReport = ContributionReportModel(
  period: '2026-05',
  members: [
    ContributionMemberModel(
      userId: 'u-1',
      name: 'Batuhan',
      totalAmount: 3200,
      percentage: 64,
      byCategory: [
        CategoryContributionModel(categoryName: 'Market', amount: 2100),
      ],
    ),
    ContributionMemberModel(
      userId: 'u-2',
      name: 'Ayşe',
      totalAmount: 1800,
      percentage: 36,
      byCategory: [
        CategoryContributionModel(categoryName: 'Faturalar', amount: 600),
      ],
    ),
  ],
);

void main() {
  late MockFamilyRepository repo;

  setUp(() => repo = MockFamilyRepository());

  FamilyBloc buildBloc() => FamilyBloc(familyRepository: repo);

  group('FamilyGroupsLoadRequested', () {
    blocTest<FamilyBloc, FamilyState>(
      'başarılı fetch — Loading → Loaded',
      build: () {
        when(() => repo.getGroups()).thenAnswer((_) async => [_group1]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const FamilyGroupsLoadRequested()),
      expect: () => [
        isA<FamilyGroupsLoading>(),
        isA<FamilyGroupsLoaded>()
            .having((s) => s.groups.length, 'grup sayısı', 1)
            .having((s) => s.groups.first.name, 'grup adı', 'Ev Bütçesi'),
      ],
    );

    blocTest<FamilyBloc, FamilyState>(
      'boş liste — Loaded (boş)',
      build: () {
        when(() => repo.getGroups()).thenAnswer((_) async => []);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const FamilyGroupsLoadRequested()),
      expect: () => [
        isA<FamilyGroupsLoading>(),
        isA<FamilyGroupsLoaded>()
            .having((s) => s.groups.isEmpty, 'boş', true),
      ],
    );

    blocTest<FamilyBloc, FamilyState>(
      'API hatası — Loading → Error',
      build: () {
        when(() => repo.getGroups()).thenThrow(Exception('network error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const FamilyGroupsLoadRequested()),
      expect: () => [
        isA<FamilyGroupsLoading>(),
        isA<FamilyGroupsError>(),
      ],
    );
  });

  group('FamilyGroupCreateRequested', () {
    blocTest<FamilyBloc, FamilyState>(
      'başarılı oluşturma — Creating → Created',
      build: () {
        when(() => repo.createGroup(name: 'Ev Bütçesi', icon: 'home'))
            .thenAnswer((_) async => _group1);
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const FamilyGroupCreateRequested(name: 'Ev Bütçesi', icon: 'home'),
      ),
      expect: () => [
        isA<FamilyGroupCreating>(),
        isA<FamilyGroupCreated>()
            .having((s) => s.group.name, 'grup adı', 'Ev Bütçesi')
            .having((s) => s.group.role, 'rol', FamilyRole.OWNER),
      ],
    );

    blocTest<FamilyBloc, FamilyState>(
      'grup limiti aşıldı — Creating → CreateError',
      build: () {
        when(() => repo.createGroup(name: any(named: 'name'), icon: any(named: 'icon')))
            .thenThrow(Exception('400 limit'));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const FamilyGroupCreateRequested(name: 'Yeni Grup')),
      expect: () => [
        isA<FamilyGroupCreating>(),
        isA<FamilyGroupCreateError>()
            .having((s) => s.message, 'hata mesajı', contains('sınırına')),
      ],
    );
  });

  group('FamilyInviteAcceptRequested', () {
    blocTest<FamilyBloc, FamilyState>(
      'başarılı kabul — Processing → Accepted',
      build: () {
        when(() => repo.acceptInvite('token-abc'))
            .thenAnswer((_) async => _group1);
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const FamilyInviteAcceptRequested(token: 'token-abc'),
      ),
      expect: () => [
        isA<FamilyInviteProcessing>(),
        isA<FamilyInviteAccepted>()
            .having((s) => s.group.name, 'grup adı', 'Ev Bütçesi'),
      ],
    );

    blocTest<FamilyBloc, FamilyState>(
      'süresi dolmuş davet — Processing → Expired',
      build: () {
        when(() => repo.acceptInvite(any()))
            .thenThrow(Exception('410 süresi dolmuş'));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const FamilyInviteAcceptRequested(token: 'expired-token')),
      expect: () => [
        isA<FamilyInviteProcessing>(),
        isA<FamilyInviteExpired>(),
      ],
    );

    blocTest<FamilyBloc, FamilyState>(
      'geçersiz token — Processing → Error',
      build: () {
        when(() => repo.acceptInvite(any()))
            .thenThrow(Exception('404 not found'));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const FamilyInviteAcceptRequested(token: 'bad-token')),
      expect: () => [
        isA<FamilyInviteProcessing>(),
        isA<FamilyInviteError>()
            .having((s) => s.message, 'hata mesajı', contains('bulunamadı')),
      ],
    );
  });

  group('FamilyInviteRejectRequested', () {
    blocTest<FamilyBloc, FamilyState>(
      'başarılı red — Processing → Rejected',
      build: () {
        when(() => repo.rejectInvite('token-abc'))
            .thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const FamilyInviteRejectRequested(token: 'token-abc')),
      expect: () => [
        isA<FamilyInviteProcessing>(),
        isA<FamilyInviteRejected>(),
      ],
    );
  });

  group('FamilyInviteSendRequested', () {
    blocTest<FamilyBloc, FamilyState>(
      'başarılı davet gönderme — Sending → Sent',
      build: () {
        when(() => repo.sendInvite(
              groupId: 'g-1',
              email: 'ayse@example.com',
            )).thenAnswer((_) async => _invite);
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const FamilyInviteSendRequested(
          groupId: 'g-1',
          email: 'ayse@example.com',
        ),
      ),
      expect: () => [
        isA<FamilyInviteSending>(),
        isA<FamilyInviteSent>()
            .having((s) => s.invite.email, 'davet e-postası', 'ayse@example.com')
            .having((s) => s.invite.status, 'davet durumu', InviteStatus.PENDING),
      ],
    );

    blocTest<FamilyBloc, FamilyState>(
      'yetkisiz kullanıcı — Sending → SendError',
      build: () {
        when(() => repo.sendInvite(
              groupId: any(named: 'groupId'),
              email: any(named: 'email'),
            )).thenThrow(Exception('403 forbidden'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const FamilyInviteSendRequested(groupId: 'g-1', email: 'x@x.com'),
      ),
      expect: () => [
        isA<FamilyInviteSending>(),
        isA<FamilyInviteSendError>()
            .having((s) => s.message, 'hata mesajı', contains('yetkiniz')),
      ],
    );
  });

  group('FamilyContributionsLoadRequested', () {
    blocTest<FamilyBloc, FamilyState>(
      'başarılı katkı raporu fetch — Loading → Loaded',
      build: () {
        when(() => repo.getContributions(
              groupId: 'g-1',
              period: '2026-05',
            )).thenAnswer((_) async => _contributionReport);
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const FamilyContributionsLoadRequested(
          groupId: 'g-1',
          period: '2026-05',
        ),
      ),
      expect: () => [
        isA<FamilyContributionsLoading>(),
        isA<FamilyContributionsLoaded>()
            .having((s) => s.report.period, 'period', '2026-05')
            .having((s) => s.report.members.length, 'üye sayısı', 2)
            .having(
              (s) => s.report.members.first.percentage,
              'ilk üye yüzdesi',
              64.0,
            ),
      ],
    );

    blocTest<FamilyBloc, FamilyState>(
      'katkı raporu API hatası — Loading → Error',
      build: () {
        when(() => repo.getContributions(
              groupId: any(named: 'groupId'),
              period: any(named: 'period'),
            )).thenThrow(Exception('server error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const FamilyContributionsLoadRequested(groupId: 'g-1'),
      ),
      expect: () => [
        isA<FamilyContributionsLoading>(),
        isA<FamilyContributionsError>(),
      ],
    );
  });

  group('FamilyMemberRemoveRequested', () {
    blocTest<FamilyBloc, FamilyState>(
      'başarılı üye çıkarma — Removing → Removed',
      build: () {
        when(() =>
                repo.removeMember(groupId: 'g-1', userId: 'u-2'))
            .thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const FamilyMemberRemoveRequested(groupId: 'g-1', userId: 'u-2'),
      ),
      expect: () => [
        isA<FamilyMemberRemoving>(),
        isA<FamilyMemberRemoved>()
            .having((s) => s.userId, 'çıkarılan userId', 'u-2'),
      ],
    );
  });

  group('FamilyGroupDetailLoadRequested', () {
    blocTest<FamilyBloc, FamilyState>(
      'başarılı grup detayı — Loading → Loaded',
      build: () {
        when(() => repo.getGroupDetail('g-1'))
            .thenAnswer((_) async => _group1Detail);
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const FamilyGroupDetailLoadRequested(groupId: 'g-1')),
      expect: () => [
        isA<FamilyGroupDetailLoading>(),
        isA<FamilyGroupDetailLoaded>()
            .having((s) => s.group.members.length, 'üye sayısı', 2)
            .having(
                (s) => s.group.sharedBudgets.length, 'ortak bütçe sayısı', 1),
      ],
    );
  });
}

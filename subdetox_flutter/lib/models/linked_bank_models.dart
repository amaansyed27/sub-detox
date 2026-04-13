class AccountAvailabilityResponse {
  const AccountAvailabilityResponse({
    required this.accounts,
    required this.linkedBanks,
    required this.traceId,
  });

  final List<AccountAvailabilityItem> accounts;
  final List<LinkedBankInstitution> linkedBanks;
  final String traceId;

  factory AccountAvailabilityResponse.fromJson(Map<String, dynamic> json) {
    final accountItems = (json['accounts'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AccountAvailabilityItem.fromJson)
        .toList();

    final linkedBanksRaw =
        (json['linkedBanks'] ?? json['linked_banks']) as List<dynamic>? ?? [];
    final linkedInstitutions = linkedBanksRaw
        .whereType<Map<String, dynamic>>()
        .map(LinkedBankInstitution.fromJson)
        .toList();

    return AccountAvailabilityResponse(
      accounts: accountItems,
      linkedBanks: linkedInstitutions,
      traceId: (json['traceId'] ?? json['trace_id'] ?? '') as String,
    );
  }
}

class AccountAvailabilityItem {
  const AccountAvailabilityItem({
    required this.aa,
    required this.vua,
    required this.status,
  });

  final String aa;
  final String vua;
  final bool status;

  factory AccountAvailabilityItem.fromJson(Map<String, dynamic> json) {
    return AccountAvailabilityItem(
      aa: (json['aa'] ?? '') as String,
      vua: (json['vua'] ?? '') as String,
      status: (json['status'] ?? false) as bool,
    );
  }
}

class LinkedBankInstitution {
  const LinkedBankInstitution({
    required this.fipId,
    required this.bankName,
    required this.status,
    required this.accounts,
  });

  final String fipId;
  final String bankName;
  final String status;
  final List<LinkedBankAccount> accounts;

  factory LinkedBankInstitution.fromJson(Map<String, dynamic> json) {
    final rawAccounts = (json['accounts'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(LinkedBankAccount.fromJson)
        .toList();

    return LinkedBankInstitution(
      fipId: (json['fipId'] ?? json['fip_id'] ?? '') as String,
      bankName: (json['bankName'] ?? json['bank_name'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      accounts: rawAccounts,
    );
  }
}

class LinkedBankAccount {
  const LinkedBankAccount({
    required this.fipId,
    required this.linkRefNumber,
    required this.maskedAccNumber,
    required this.accType,
    required this.fiType,
    required this.nickname,
  });

  final String fipId;
  final String linkRefNumber;
  final String maskedAccNumber;
  final String accType;
  final String fiType;
  final String nickname;

  factory LinkedBankAccount.fromJson(Map<String, dynamic> json) {
    return LinkedBankAccount(
      fipId: (json['fipId'] ?? json['fip_id'] ?? '') as String,
      linkRefNumber:
          (json['linkRefNumber'] ?? json['link_ref_number'] ?? '') as String,
      maskedAccNumber: (json['maskedAccNumber'] ??
          json['masked_acc_number'] ??
          '') as String,
      accType: (json['accType'] ?? json['acc_type'] ?? '') as String,
      fiType: (json['fiType'] ?? json['fi_type'] ?? '') as String,
      nickname: (json['nickname'] ?? '') as String,
    );
  }
}

class AccountSelectionResponse {
  const AccountSelectionResponse({
    required this.status,
    required this.selectedAccounts,
    required this.traceId,
  });

  final String status;
  final List<LinkedBankAccount> selectedAccounts;
  final String traceId;

  factory AccountSelectionResponse.fromJson(Map<String, dynamic> json) {
    final selected = (json['selectedAccounts'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(LinkedBankAccount.fromJson)
        .toList();

    return AccountSelectionResponse(
      status: (json['status'] ?? '') as String,
      selectedAccounts: selected,
      traceId: (json['traceId'] ?? json['trace_id'] ?? '') as String,
    );
  }
}

class UserSelectionProfile {
  const UserSelectionProfile({
    required this.phoneNumber,
    required this.selectionMobileNumber,
    required this.selectedLinkRefNumbers,
  });

  final String? phoneNumber;
  final String? selectionMobileNumber;
  final List<String> selectedLinkRefNumbers;

  factory UserSelectionProfile.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final profileMap =
        profile is Map<String, dynamic> ? profile : <String, dynamic>{};

    final selectedAccounts =
        (profileMap['selectedAccounts'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();

    final selectedRefs = selectedAccounts
        .map((item) => (item['linkRefNumber'] ?? '') as String)
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    final selectionMobile =
        (profileMap['selectionMobileNumber'] as String?)?.trim();

    return UserSelectionProfile(
      phoneNumber: (json['phone_number'] ?? json['phoneNumber']) as String?,
      selectionMobileNumber: selectionMobile == null || selectionMobile.isEmpty
          ? null
          : selectionMobile,
      selectedLinkRefNumbers: selectedRefs,
    );
  }

  bool hasSelectedAccountsForMobile(String mobileNumber) {
    if (selectedLinkRefNumbers.isEmpty) {
      return false;
    }

    final requested = _normalizedMobile(mobileNumber);
    final selected = _normalizedMobile(selectionMobileNumber ?? '');
    return requested.isNotEmpty && requested == selected;
  }

  static String _normalizedMobile(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 10) {
      return digits;
    }
    return digits.substring(digits.length - 10);
  }
}

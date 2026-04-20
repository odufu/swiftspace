enum UserRole {
  user,
  agent,
  owner,
  developer,
  company,
  admin,
  sadmin;

  String get displayName {
    switch (this) {
      case UserRole.user: return 'Explorer';
      case UserRole.agent: return 'Agent';
      case UserRole.owner: return 'Owner';
      case UserRole.developer: return 'Developer';
      case UserRole.company: return 'Company';
      case UserRole.admin: return 'Admin';
      case UserRole.sadmin: return 'Super Admin';
    }
  }

  String get portalName {
    switch (this) {
      case UserRole.agent: return 'Agent Portal';
      case UserRole.owner: return 'Owner Hub';
      case UserRole.developer: return 'Developer Studio';
      case UserRole.company: return 'Corporate Office';
      default: return 'Professional Suite';
    }
  }
}

class UserProfile {
  final String id;
  final String email;
  final UserRole role;
  final String? fullName;
  final String? avatarUrl;
  final bool isVerified;
  final int yearsExperience;
  final String? governmentIdUrl;
  final String? brokerLicenseUrl;
  final bool termsAccepted;
  final bool isBlocked;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.avatarUrl,
    this.isVerified = false,
    this.yearsExperience = 0,
    this.governmentIdUrl,
    this.brokerLicenseUrl,
    this.termsAccepted = false,
    this.isBlocked = false,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      role: _parseRole(json['role'] as String?),
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      yearsExperience: json['years_experience'] as int? ?? 0,
      governmentIdUrl: json['government_id_url'] as String?,
      brokerLicenseUrl: json['broker_license_url'] as String?,
      termsAccepted: json['terms_accepted'] as bool? ?? false,
      isBlocked: json['is_blocked'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.name,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'is_verified': isVerified,
      'years_experience': yearsExperience,
      'government_id_url': governmentIdUrl,
      'broker_license_url': brokerLicenseUrl,
      'terms_accepted': termsAccepted,
      'is_blocked': isBlocked,
    };
  }

  static UserRole _parseRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'agent':
        return UserRole.agent;
      case 'owner':
        return UserRole.owner;
      case 'developer':
        return UserRole.developer;
      case 'company':
        return UserRole.company;
      case 'admin':
        return UserRole.admin;
      case 'sadmin':
        return UserRole.sadmin;
      case 'buyer': // Backward compatibility
      case 'user':
        return UserRole.user;
      default:
        return UserRole.user;
    }
  }

  UserProfile copyWith({
    String? fullName,
    String? avatarUrl,
    UserRole? role,
    bool? isVerified,
    int? yearsExperience,
    String? governmentIdUrl,
    String? brokerLicenseUrl,
    bool? termsAccepted,
    bool? isBlocked,
  }) {
    return UserProfile(
      id: id,
      email: email,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      governmentIdUrl: governmentIdUrl ?? this.governmentIdUrl,
      brokerLicenseUrl: brokerLicenseUrl ?? this.brokerLicenseUrl,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt,
    );
  }
}

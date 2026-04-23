import 'package:latlong2/latlong.dart';
import 'virtual_tour.dart';

enum PropertyType { shops, officeSpace, flatsAndApartments, lands, semiDetachedBungalows, semiDetachedDuplex, coWorkingSpace, detachedBungalows, warehouse, shopInAMall, detachedDuplex, terracedBungalows, commercialProperties, terracedDuplex, house }

enum ListerType { agent, owner, developer, realEstateCompany }

extension ListerTypeExtension on ListerType {
  String get displayName {
    switch (this) {
      case ListerType.agent:
        return 'Verified Agent';
      case ListerType.owner:
        return 'Property Owner';
      case ListerType.developer:
        return 'Official Developer';
      case ListerType.realEstateCompany:
        return 'Real Estate Company';
    }
  }
}

extension PropertyTypeExtension on PropertyType {
  String get displayName {
    switch (this) {
      case PropertyType.shops: return 'Shops';
      case PropertyType.officeSpace: return 'Office space';
      case PropertyType.flatsAndApartments: return 'Flats and apartments';
      case PropertyType.lands: return 'Lands';
      case PropertyType.semiDetachedBungalows: return 'Semi detached bungalows';
      case PropertyType.semiDetachedDuplex: return 'Semi detached duplex';
      case PropertyType.coWorkingSpace: return 'Co working space';
      case PropertyType.detachedBungalows: return 'Detached bungalows';
      case PropertyType.warehouse: return 'Warehouse';
      case PropertyType.shopInAMall: return 'Shop in a mall';
      case PropertyType.detachedDuplex: return 'Detached duplex';
      case PropertyType.terracedBungalows: return 'Terraced bungalows';
      case PropertyType.commercialProperties: return 'Commercial properties';
      case PropertyType.terracedDuplex: return 'Terraced duplex';
      case PropertyType.house: return 'House';
    }
  }
}

enum PropertyCategory {
  residential,
  commercial,
  land
}

extension PropertyTypeCategoryExtension on PropertyType {
  PropertyCategory get category {
    switch (this) {
      case PropertyType.shops:
      case PropertyType.officeSpace:
      case PropertyType.coWorkingSpace:
      case PropertyType.warehouse:
      case PropertyType.shopInAMall:
      case PropertyType.commercialProperties:
        return PropertyCategory.commercial;
      case PropertyType.lands:
        return PropertyCategory.land;
      case PropertyType.flatsAndApartments:
      case PropertyType.semiDetachedBungalows:
      case PropertyType.semiDetachedDuplex:
      case PropertyType.detachedBungalows:
      case PropertyType.detachedDuplex:
      case PropertyType.terracedBungalows:
      case PropertyType.terracedDuplex:
      case PropertyType.house:
        return PropertyCategory.residential;
    }
  }
}

enum LegalDocumentStatus {
  pending,
  verified,
  rejected
}

enum PropertyVerificationStatus {
  unverified,
  pendingReview,
  verified,
  issuesFlagged,
  fraudBlocked
}

class LegalDocument {
  final String title;
  final String documentType;
  final DateTime verificationDate;
  final String? url;
  final bool isVerified; // Legacy getter, true if status == verified
  final LegalDocumentStatus status;
  final String? adminFeedback;

  LegalDocument({
    required this.title,
    required this.documentType,
    required this.verificationDate,
    this.url,
    this.status = LegalDocumentStatus.pending,
    this.adminFeedback,
  }) : isVerified = status == LegalDocumentStatus.verified;
}

class Property {
  final String id;
  final String title;
  final double price;
  final String priceTerm; // "day", "wk", "mo", "yr", "buy"
  final String formattedPrice;
  final String locationName;
  final LatLng location;
  final PropertyType type;
  final int beds;
  final int baths;
  final String imageUrl;
  final String description;
  final List<String> imagesGallery;
  final String? planImageUrl;
  final bool has360View;
  final bool hasVideo;
  final List<String> amenities;
  final String listerName;
  final ListerType listerType;
  final String? companyName;
  final String? listerLogoUrl;
  final String agentPhone; // Keeping this for contact
  final bool isVerified;
  final bool isActive;
  final bool isTest;
  final int viewsCount;
  final int favoritesCount;
  final int videoViewsCount;
  final String? listerId; // Links to auth.users.id
  final bool isPremium; // Indicates if this is a premium listing locked behind a paywall

  // Document URLs for serious interests
  final String? coOfOUrl;
  final String? governorsConsentUrl;
  final String? surveyPlanUrl;
  final String? deedOfAssignmentUrl;
  final String? buildingPlanApprovalUrl;
  final String? soilTestReportUrl;
  final String? structuralIntegrityReportUrl;

  String get agentName => listerName;
  final int proximityToRoadMeters;
  final double electricitySupplyHours;
  final bool hasRunningWater;
  final double proximityToHospitalKm;
  
  // Technical & Detail fields
  final int? yearBuilt;
  final double? totalSquareFootage;
  final bool floodingHistory;
  final String? foundationType;

  // Legal & Documents Checklist
  final bool hasCertificateOfOccupancy;
  final bool hasGovernorsConsent;
  final bool hasSurveyPlan;
  final bool hasDeedOfAssignment;
  final bool hasBuildingPlanApproval;
  
  // Due Diligence
  final bool hasSoilTestReport;
  final bool hasStructuralIntegrityReport;
  final String? dueDiligenceNotes;
  final bool hasLawyerVerifiedTerms;
  
  final String? videoUrl;
  final String? panoramaUrl;
  final VirtualTour? virtualTour;
  final List<LegalDocument> legalDocuments;
  final String? termsAndConditions;
  final PropertyVerificationStatus verificationStatus;
  
  // Fee configuration
  final bool appliesCautionFee;
  final bool appliesAgencyFee;
  final bool appliesLegalFee;
  final bool appliesServiceFee;

  // Geo-fencing for lands
  final List<LatLng>? geoFencePoints;

  Property({
    required this.id,
    required this.title,
    required this.locationName,
    required this.price,
    required this.priceTerm,
    required this.formattedPrice,
    required this.location,
    required this.type,
    required this.beds,
    required this.baths,
    required this.imageUrl,
    required this.description,
    required this.imagesGallery,
    this.planImageUrl,
    required this.has360View,
    required this.hasVideo,
    required this.amenities,
    required this.listerName,
    required this.listerType,
    this.companyName,
    this.listerLogoUrl,
    required this.agentPhone,
    required this.isVerified,
    required this.proximityToRoadMeters,
    required this.electricitySupplyHours,
    required this.hasRunningWater,
    required this.proximityToHospitalKm,
    this.isActive = true,
    this.isTest = false,
    this.yearBuilt,
    this.totalSquareFootage,
    this.floodingHistory = false,
    this.foundationType,
    this.hasCertificateOfOccupancy = false,
    this.hasGovernorsConsent = false,
    this.hasSurveyPlan = false,
    this.hasDeedOfAssignment = false,
    this.hasBuildingPlanApproval = false,
    this.hasSoilTestReport = false,
    this.hasStructuralIntegrityReport = false,
    this.dueDiligenceNotes,
    this.hasLawyerVerifiedTerms = false,
    this.videoUrl,
    this.panoramaUrl,
    this.viewsCount = 0,
    this.favoritesCount = 0,
    this.videoViewsCount = 0,
    this.virtualTour,
    this.legalDocuments = const [],
    this.termsAndConditions,
    this.verificationStatus = PropertyVerificationStatus.unverified,
    this.appliesCautionFee = true,
    this.appliesAgencyFee = true,
    this.appliesLegalFee = true,
    this.appliesServiceFee = true,
    this.geoFencePoints,
    this.listerId,
    this.isPremium = false,
    this.coOfOUrl,
    this.governorsConsentUrl,
    this.surveyPlanUrl,
    this.deedOfAssignmentUrl,
    this.buildingPlanApprovalUrl,
    this.soilTestReportUrl,
    this.structuralIntegrityReportUrl,
  });

  Property copyWith({
    String? id,
    String? title,
    double? price,
    String? priceTerm,
    String? formattedPrice,
    String? locationName,
    LatLng? location,
    PropertyType? type,
    int? beds,
    int? baths,
    String? imageUrl,
    String? description,
    List<String>? imagesGallery,
    String? planImageUrl,
    bool? has360View,
    bool? hasVideo,
    List<String>? amenities,
    String? listerName,
    ListerType? listerType,
    String? companyName,
    String? listerLogoUrl,
    String? agentPhone,
    bool? isVerified,
    bool? isActive,
    bool? isTest,
    int? viewsCount,
    int? favoritesCount,
    int? videoViewsCount,
    int? proximityToRoadMeters,
    double? electricitySupplyHours,
    bool? hasRunningWater,
    double? proximityToHospitalKm,
    int? yearBuilt,
    double? totalSquareFootage,
    bool? floodingHistory,
    String? foundationType,
    bool? hasCertificateOfOccupancy,
    bool? hasGovernorsConsent,
    bool? hasSurveyPlan,
    bool? hasDeedOfAssignment,
    bool? hasBuildingPlanApproval,
    bool? hasSoilTestReport,
    bool? hasStructuralIntegrityReport,
    String? dueDiligenceNotes,
    String? videoUrl,
    String? panoramaUrl,
    bool? hasLawyerVerifiedTerms,
    List<LegalDocument>? legalDocuments,
    String? termsAndConditions,
    PropertyVerificationStatus? verificationStatus,
    bool? appliesCautionFee,
    bool? appliesAgencyFee,
    bool? appliesLegalFee,
    bool? appliesServiceFee,
    VirtualTour? virtualTour,
    List<LatLng>? geoFencePoints,
    String? listerId,
    bool? isPremium,
    String? coOfOUrl,
    String? governorsConsentUrl,
    String? surveyPlanUrl,
    String? deedOfAssignmentUrl,
    String? buildingPlanApprovalUrl,
    String? soilTestReportUrl,
    String? structuralIntegrityReportUrl,
  }) {
    return Property(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      priceTerm: priceTerm ?? this.priceTerm,
      formattedPrice: formattedPrice ?? this.formattedPrice,
      locationName: locationName ?? this.locationName,
      location: location ?? this.location,
      type: type ?? this.type,
      beds: beds ?? this.beds,
      baths: baths ?? this.baths,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      imagesGallery: imagesGallery ?? this.imagesGallery,
      planImageUrl: planImageUrl ?? this.planImageUrl,
      has360View: has360View ?? this.has360View,
      hasVideo: hasVideo ?? this.hasVideo,
      amenities: amenities ?? this.amenities,
      listerName: listerName ?? this.listerName,
      listerType: listerType ?? this.listerType,
      companyName: companyName ?? this.companyName,
      listerLogoUrl: listerLogoUrl ?? this.listerLogoUrl,
      agentPhone: agentPhone ?? this.agentPhone,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      isTest: isTest ?? this.isTest,
      viewsCount: viewsCount ?? this.viewsCount,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      videoViewsCount: videoViewsCount ?? this.videoViewsCount,
      proximityToRoadMeters: proximityToRoadMeters ?? this.proximityToRoadMeters,
      electricitySupplyHours: electricitySupplyHours ?? this.electricitySupplyHours,
      hasRunningWater: hasRunningWater ?? this.hasRunningWater,
      proximityToHospitalKm: proximityToHospitalKm ?? this.proximityToHospitalKm,
      yearBuilt: yearBuilt ?? this.yearBuilt,
      totalSquareFootage: totalSquareFootage ?? this.totalSquareFootage,
      floodingHistory: floodingHistory ?? this.floodingHistory,
      foundationType: foundationType ?? this.foundationType,
      hasCertificateOfOccupancy: hasCertificateOfOccupancy ?? this.hasCertificateOfOccupancy,
      hasGovernorsConsent: hasGovernorsConsent ?? this.hasGovernorsConsent,
      hasSurveyPlan: hasSurveyPlan ?? this.hasSurveyPlan,
      hasDeedOfAssignment: hasDeedOfAssignment ?? this.hasDeedOfAssignment,
      hasBuildingPlanApproval: hasBuildingPlanApproval ?? this.hasBuildingPlanApproval,
      hasSoilTestReport: hasSoilTestReport ?? this.hasSoilTestReport,
      hasStructuralIntegrityReport: hasStructuralIntegrityReport ?? this.hasStructuralIntegrityReport,
      dueDiligenceNotes: dueDiligenceNotes ?? this.dueDiligenceNotes,
      videoUrl: videoUrl ?? this.videoUrl,
      panoramaUrl: panoramaUrl ?? this.panoramaUrl,
      hasLawyerVerifiedTerms: hasLawyerVerifiedTerms ?? this.hasLawyerVerifiedTerms,
      legalDocuments: legalDocuments ?? this.legalDocuments,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      appliesCautionFee: appliesCautionFee ?? this.appliesCautionFee,
      appliesAgencyFee: appliesAgencyFee ?? this.appliesAgencyFee,
      appliesLegalFee: appliesLegalFee ?? this.appliesLegalFee,
      appliesServiceFee: appliesServiceFee ?? this.appliesServiceFee,
      virtualTour: virtualTour ?? this.virtualTour,
      geoFencePoints: geoFencePoints ?? this.geoFencePoints,
      listerId: listerId ?? this.listerId,
      isPremium: isPremium ?? this.isPremium,
      coOfOUrl: coOfOUrl ?? this.coOfOUrl,
      governorsConsentUrl: governorsConsentUrl ?? this.governorsConsentUrl,
      surveyPlanUrl: surveyPlanUrl ?? this.surveyPlanUrl,
      deedOfAssignmentUrl: deedOfAssignmentUrl ?? this.deedOfAssignmentUrl,
      buildingPlanApprovalUrl: buildingPlanApprovalUrl ?? this.buildingPlanApprovalUrl,
      soilTestReportUrl: soilTestReportUrl ?? this.soilTestReportUrl,
      structuralIntegrityReportUrl: structuralIntegrityReportUrl ?? this.structuralIntegrityReportUrl,
    );
  }

  static String formatPrice(double price) {
    if (price >= 1000000) return '₦${(price / 1000000).toStringAsFixed(1)}M';
    if (price >= 1000) return '₦${(price / 1000).toStringAsFixed(1)}k';
    return '₦${price.toStringAsFixed(0)}';
  }

  factory Property.fromMap(Map<String, dynamic> map) {
    final price = (map['price'] as num).toDouble();
    return Property(
      id: map['id'],
      title: map['title'],
      locationName: map['location_name'],
      price: price,
      priceTerm: map['price_term'],
      formattedPrice: map['formatted_price'] ?? formatPrice(price),
      location: LatLng(
        (map['latitude'] as num).toDouble(),
        (map['longitude'] as num).toDouble(),
      ),
      type: PropertyType.values.byName(map['type']),
      beds: map['beds'] ?? 0,
      baths: map['baths'] ?? 0,
      imageUrl: map['image_url'],
      description: map['description'],
      imagesGallery: List<String>.from(map['images_gallery'] ?? []),
      planImageUrl: map['plan_image_url'],
      has360View: map['has_360_view'] ?? false,
      hasVideo: map['has_video'] ?? false,
      amenities: List<String>.from(map['amenities'] ?? []),
      listerName: map['lister_name'],
      listerType: ListerType.values.byName(map['lister_type']),
      companyName: map['company_name'],
      listerLogoUrl: map['lister_logo_url'],
      agentPhone: map['agent_phone'],
      isVerified: map['is_verified'] ?? false,
      isActive: map['is_active'] ?? true,
      isTest: map['is_test'] ?? false,
      proximityToRoadMeters: map['proximity_to_road_meters'] ?? 0,
      electricitySupplyHours: (map['electricity_supply_hours'] as num?)?.toDouble() ?? 0.0,
      hasRunningWater: map['has_running_water'] ?? false,
      proximityToHospitalKm: (map['proximity_to_hospital_km'] as num?)?.toDouble() ?? 0.0,
      yearBuilt: map['year_built'],
      totalSquareFootage: (map['total_square_footage'] as num?)?.toDouble(),
      floodingHistory: map['flooding_history'] ?? false,
      foundationType: map['foundation_type'],
      hasCertificateOfOccupancy: map['has_certificate_of_occupancy'] ?? false,
      hasGovernorsConsent: map['has_governors_consent'] ?? false,
      hasSurveyPlan: map['has_survey_plan'] ?? false,
      hasDeedOfAssignment: map['has_deed_of_assignment'] ?? false,
      hasBuildingPlanApproval: map['has_building_plan_approval'] ?? false,
      hasSoilTestReport: map['has_soil_test_report'] ?? false,
      hasStructuralIntegrityReport: map['has_structural_integrity_report'] ?? false,
      dueDiligenceNotes: map['due_diligence_notes'],
      hasLawyerVerifiedTerms: map['has_lawyer_verified_terms'] ?? false,
      videoUrl: map['video_url'],
      panoramaUrl: map['panorama_url'],
      viewsCount: map['views_count'] ?? 0,
      favoritesCount: map['favorites_count'] ?? 0,
      videoViewsCount: map['video_views_count'] ?? 0,
      termsAndConditions: map['terms_and_conditions'],
      verificationStatus: PropertyVerificationStatus.values.byName(map['verification_status'] ?? 'unverified'),
      appliesCautionFee: map['applies_caution_fee'] ?? true,
      appliesAgencyFee: map['applies_agency_fee'] ?? true,
      appliesLegalFee: map['applies_legal_fee'] ?? true,
      appliesServiceFee: map['applies_service_fee'] ?? true,
      virtualTour: map['virtual_tour_data'] != null ? VirtualTour.fromMap(map['virtual_tour_data']) : null,
      geoFencePoints: (map['geo_fence_points'] as List<dynamic>?)?.map((e) {
        final pointMap = e as Map<String, dynamic>;
        return LatLng((pointMap['lat'] as num).toDouble(), (pointMap['lng'] as num).toDouble());
      }).toList(),
      listerId: map['lister_id'],
      isPremium: map['is_premium'] ?? false,
      coOfOUrl: map['co_of_o_url'],
      governorsConsentUrl: map['governors_consent_url'],
      surveyPlanUrl: map['survey_plan_url'],
      deedOfAssignmentUrl: map['deed_of_assignment_url'],
      buildingPlanApprovalUrl: map['building_plan_approval_url'],
      soilTestReportUrl: map['soil_test_report_url'],
      structuralIntegrityReportUrl: map['structural_integrity_report_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location_name': locationName,
      'price': price,
      'price_term': priceTerm,
      // Removed 'formatted_price' to fix Supabase schema mismatch
      'latitude': location.latitude,
      'longitude': location.longitude,
      'type': type.name,
      'beds': beds,
      'baths': baths,
      'image_url': imageUrl,
      'description': description,
      'images_gallery': imagesGallery,
      'plan_image_url': planImageUrl,
      'has_360_view': has360View,
      'has_video': hasVideo,
      'amenities': amenities,
      'lister_name': listerName,
      'lister_type': listerType.name,
      'company_name': companyName,
      'lister_logo_url': listerLogoUrl,
      'agent_phone': agentPhone,
      'is_verified': isVerified,
      'is_active': isActive,
      'is_test': isTest,
      'proximity_to_road_meters': proximityToRoadMeters,
      'electricity_supply_hours': electricitySupplyHours,
      'has_running_water': hasRunningWater,
      'proximity_to_hospital_km': proximityToHospitalKm,
      'year_built': yearBuilt,
      'total_square_footage': totalSquareFootage,
      'flooding_history': floodingHistory,
      'foundation_type': foundationType,
      'has_certificate_of_occupancy': hasCertificateOfOccupancy,
      'has_governors_consent': hasGovernorsConsent,
      'has_survey_plan': hasSurveyPlan,
      'has_deed_of_assignment': hasDeedOfAssignment,
      'has_building_plan_approval': hasBuildingPlanApproval,
      'has_soil_test_report': hasSoilTestReport,
      'has_structural_integrity_report': hasStructuralIntegrityReport,
      'due_diligence_notes': dueDiligenceNotes,
      'has_lawyer_verified_terms': hasLawyerVerifiedTerms,
      'video_url': videoUrl,
      'panorama_url': panoramaUrl,
      'views_count': viewsCount,
      'favorites_count': favoritesCount,
      'video_views_count': videoViewsCount,
      'terms_and_conditions': termsAndConditions,
      'verification_status': verificationStatus.name,
      'applies_caution_fee': appliesCautionFee,
      'applies_agency_fee': appliesAgencyFee,
      'applies_legal_fee': appliesLegalFee,
      'applies_service_fee': appliesServiceFee,
      'virtual_tour_data': virtualTour?.toMap(),
      'geo_fence_points': geoFencePoints?.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'lister_id': listerId,
      'is_premium': isPremium,
      'co_of_o_url': coOfOUrl,
      'governors_consent_url': governorsConsentUrl,
      'survey_plan_url': surveyPlanUrl,
      'deed_of_assignment_url': deedOfAssignmentUrl,
      'building_plan_approval_url': buildingPlanApprovalUrl,
      'soil_test_report_url': soilTestReportUrl,
      'structural_integrity_report_url': structuralIntegrityReportUrl,
    };
  }
}

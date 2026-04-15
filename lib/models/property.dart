import 'dart:math';
import 'package:latlong2/latlong.dart';

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
  final int viewsCount;
  final int favoritesCount;
  final int videoViewsCount;

  String get agentName => listerName;
  final int proximityToRoadMeters;
  final double electricitySupplyHours;
  final bool hasRunningWater;
  final double proximityToHospitalKm;
  final bool hasCertificateOfOccupancy;
  final bool hasLawyerVerifiedTerms;
  final String? videoUrl;
  final String? panoramaUrl;
  final List<LegalDocument> legalDocuments;
  final String? termsAndConditions;
  final PropertyVerificationStatus verificationStatus;
  
  // Fee configuration
  final bool appliesCautionFee;
  final bool appliesAgencyFee;
  final bool appliesLegalFee;
  final bool appliesServiceFee;

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
    this.hasCertificateOfOccupancy = false,
    this.hasLawyerVerifiedTerms = false,
    this.videoUrl,
    this.panoramaUrl,
    this.viewsCount = 0,
    this.favoritesCount = 0,
    this.videoViewsCount = 0,
    this.legalDocuments = const [],
    this.termsAndConditions,
    this.verificationStatus = PropertyVerificationStatus.unverified,
    this.appliesCautionFee = true,
    this.appliesAgencyFee = true,
    this.appliesLegalFee = true,
    this.appliesServiceFee = true,
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
    int? viewsCount,
    int? favoritesCount,
    int? videoViewsCount,
    int? proximityToRoadMeters,
    double? electricitySupplyHours,
    bool? hasRunningWater,
    double? proximityToHospitalKm,
    String? videoUrl,
    String? panoramaUrl,
    bool? hasCertificateOfOccupancy,
    bool? hasLawyerVerifiedTerms,
    List<LegalDocument>? legalDocuments,
    String? termsAndConditions,
    PropertyVerificationStatus? verificationStatus,
    bool? appliesCautionFee,
    bool? appliesAgencyFee,
    bool? appliesLegalFee,
    bool? appliesServiceFee,
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
      viewsCount: viewsCount ?? this.viewsCount,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      videoViewsCount: videoViewsCount ?? this.videoViewsCount,
      proximityToRoadMeters: proximityToRoadMeters ?? this.proximityToRoadMeters,
      electricitySupplyHours: electricitySupplyHours ?? this.electricitySupplyHours,
      hasRunningWater: hasRunningWater ?? this.hasRunningWater,
      proximityToHospitalKm: proximityToHospitalKm ?? this.proximityToHospitalKm,
      videoUrl: videoUrl ?? this.videoUrl,
      panoramaUrl: panoramaUrl ?? this.panoramaUrl,
      hasCertificateOfOccupancy: hasCertificateOfOccupancy ?? this.hasCertificateOfOccupancy,
      hasLawyerVerifiedTerms: hasLawyerVerifiedTerms ?? this.hasLawyerVerifiedTerms,
      legalDocuments: legalDocuments ?? this.legalDocuments,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      appliesCautionFee: appliesCautionFee ?? this.appliesCautionFee,
      appliesAgencyFee: appliesAgencyFee ?? this.appliesAgencyFee,
      appliesLegalFee: appliesLegalFee ?? this.appliesLegalFee,
      appliesServiceFee: appliesServiceFee ?? this.appliesServiceFee,
    );
  }
}

// ── City Centers ────────────────────────────────────────────────────────────
const LatLng kubwaAbuja = LatLng(9.1538, 7.3220);
const LatLng portHarcourt = LatLng(4.8156, 7.0498);
const LatLng lagos = LatLng(6.5244, 3.3792);
const LatLng lekki = LatLng(6.4698, 3.5852);
const LatLng ikeja = LatLng(6.5965, 3.3421);
const LatLng ibadan = LatLng(7.3775, 3.9470);
const LatLng kano = LatLng(12.0022, 8.5920);
const LatLng enugu = LatLng(6.4584, 7.5464);
const LatLng benin = LatLng(6.3350, 5.6037);

List<Property> _generateMockData() {
  final random = Random(42);

  // ── Rich property image pool (24 unique Unsplash images) ─────────────────
  final Map<PropertyType, List<String>> typeImages = {
    PropertyType.flatsAndApartments: [
      'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=700&q=80',
      'https://images.unsplash.com/photo-1502672260266-1c1e5250fe0b?w=700&q=80',
      'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=700&q=80',
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=700&q=80',
      'https://images.unsplash.com/photo-1554995207-c18c203602cb?w=700&q=80',
    ],
    PropertyType.house: [
      'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=700&q=80',
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=700&q=80',
      'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=700&q=80',
      'https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?w=700&q=80',
      'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=700&q=80',
    ],
    PropertyType.detachedDuplex: [
      'https://images.unsplash.com/photo-1605276374104-dee2a0ed3cd6?w=700&q=80',
      'https://images.unsplash.com/photo-1617104678098-de229db51175?w=700&q=80',
      'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=700&q=80',
      'https://images.unsplash.com/photo-1558036117-15d82a90b9b1?w=700&q=80',
    ],
    PropertyType.semiDetachedDuplex: [
      'https://images.unsplash.com/photo-1523217582562-09d0def993a6?w=700&q=80',
      'https://images.unsplash.com/photo-1574362848149-11496d93a7c7?w=700&q=80',
      'https://images.unsplash.com/photo-1464146072230-91cabc968266?w=700&q=80',
    ],
    PropertyType.terracedDuplex: [
      'https://images.unsplash.com/photo-1518780664697-55e3ad937233?w=700&q=80',
      'https://images.unsplash.com/photo-1449844908441-8829872d2607?w=700&q=80',
      'https://images.unsplash.com/photo-1459767129954-1b1c1f9b9ace?w=700&q=80',
    ],
    PropertyType.detachedBungalows: [
      'https://images.unsplash.com/photo-1598228723793-52759bba239c?w=700&q=80',
      'https://images.unsplash.com/photo-1599427303058-f04cbcf4756f?w=700&q=80',
      'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=700&q=80',
      'https://images.unsplash.com/photo-1614596683670-958fe77b0e63?w=700&q=80',
    ],
    PropertyType.semiDetachedBungalows: [
      'https://images.unsplash.com/photo-1576941089067-2de3c901e126?w=700&q=80',
      'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=700&q=80',
      'https://images.unsplash.com/photo-1516455590571-18256e5bb9ff?w=700&q=80',
    ],
    PropertyType.terracedBungalows: [
      'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=700&q=80',
      'https://images.unsplash.com/photo-1502005229762-cf1b2da7c5d6?w=700&q=80',
      'https://images.unsplash.com/photo-1571055107559-3e67626fa8be?w=700&q=80',
    ],
    PropertyType.lands: [
      'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=700&q=80',
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=700&q=80',
      'https://images.unsplash.com/photo-1416331108676-a22ccb276e35?w=700&q=80',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=700&q=80',
    ],
    PropertyType.shops: [
      'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=700&q=80',
      'https://images.unsplash.com/photo-1472851294608-062f824d29cc?w=700&q=80',
      'https://images.unsplash.com/photo-1534531173927-aeb928d54385?w=700&q=80',
    ],
    PropertyType.shopInAMall: [
      'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=700&q=80',
      'https://images.unsplash.com/photo-1519566335946-e6f65f0f4fdf?w=700&q=80',
      'https://images.unsplash.com/photo-1570222094114-d054a817e56b?w=700&q=80',
    ],
    PropertyType.officeSpace: [
      'https://images.unsplash.com/photo-1497366216548-37526070297c?w=700&q=80',
      'https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=700&q=80',
      'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=700&q=80',
      'https://images.unsplash.com/photo-1604328698692-f76ea9498e76?w=700&q=80',
    ],
    PropertyType.coWorkingSpace: [
      'https://images.unsplash.com/photo-1556761175-4b46a572b786?w=700&q=80',
      'https://images.unsplash.com/photo-1573164713988-8665fc963095?w=700&q=80',
      'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=700&q=80',
    ],
    PropertyType.warehouse: [
      'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=700&q=80',
      'https://images.unsplash.com/photo-1553413077-190dd305871c?w=700&q=80',
      'https://images.unsplash.com/photo-1564182842519-8a3b2af3e228?w=700&q=80',
    ],
    PropertyType.commercialProperties: [
      'https://images.unsplash.com/photo-1486325212027-8081e485255e?w=700&q=80',
      'https://images.unsplash.com/photo-1554469384-e58fac16e23a?w=700&q=80',
      'https://images.unsplash.com/photo-1519999482648-25049ddd37b1?w=700&q=80',
    ],
  };

  final List<String> planImages = [
    'https://images.unsplash.com/photo-1600607688969-a5bfcd64bd15?w=600&q=80',
    'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=600&q=80',
    'https://images.unsplash.com/photo-1561715276-a2d087060f1d?w=600&q=80',
  ];

  final List<String> panoramaUrls = [
    'https://images.unsplash.com/photo-1557971370-e7298ea47302?w=2000&q=80',
    'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=2000&q=80',
    'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=2000&q=80',
  ];

  const videoUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';

  // ── Amenities pool ────────────────────────────────────────────────────────
  final List<String> amenitiesPool = [
    '24/7 Power',
    'Running Water',
    'Security Guard',
    'Fenced & Gated',
    'Pre-paid Meter',
    'Generator House',
    'Tarred Road',
    'En-suite',
    'POP Ceiling',
    'Wardrobe',
    'Ample Parking',
    'Swimming Pool',
    'CCTV Cameras',
    'Boys Quarters',
    'Tiled Floors',
    'Air Conditioning',
    'Intercom',
    'Water Heater',
    'Spacious Kitchen',
    'Dining Room',
    'Smart Home System',
    'Solar Power',
    'Fiber Internet',
    'Gym',
    'Playground',
    'Garden',
    'Store Room',
    'Carport',
  ];

  // ── Agents pool ───────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> listers = [
    {'name': 'Chief Okafor', 'phone': '+234 803 421 8876', 'type': ListerType.owner},
    {
      'name': 'Agent Tunji', 
      'phone': '+234 812 305 7742', 
      'type': ListerType.realEstateCompany,
      'companyName': 'Bode Thomas Properties',
      'logo': 'https://api.dicebear.com/7.x/initials/png?seed=BT&backgroundColor=1e293b'
    },
    {'name': 'Nnamdi Estates Ltd', 'phone': '+234 808 112 3344', 'type': ListerType.developer},
    {'name': 'Alhaji Musa Realty', 'phone': '+234 705 993 0011', 'type': ListerType.agent},
    {'name': 'Oluwaseun & Sons', 'phone': '+234 901 221 4490', 'type': ListerType.developer},
    {'name': 'Caleb Homes Agency', 'phone': '+234 802 887 6543', 'type': ListerType.agent},
    {'name': 'Amarachi Properties', 'phone': '+234 814 551 8293', 'type': ListerType.owner},
    {'name': 'Engr. Tunde Fasola', 'phone': '+234 811 390 5631', 'type': ListerType.developer},
    {'name': 'Mrs. Ngozi Dike', 'phone': '+234 907 774 0082', 'type': ListerType.agent},
    {
      'name': 'Agent Haruna', 
      'phone': '+234 703 445 9123', 
      'type': ListerType.realEstateCompany,
      'companyName': 'Haruna & Partners',
      'logo': 'https://api.dicebear.com/7.x/initials/png?seed=HP&backgroundColor=0284c7'
    },
    {
      'name': 'Agent Pearl', 
      'phone': '+234 817 264 7700', 
      'type': ListerType.realEstateCompany,
      'companyName': 'Pearl Estate Mgmt',
      'logo': 'https://api.dicebear.com/7.x/initials/png?seed=PE&backgroundColor=8b5cf6'
    },
    {
      'name': 'Agent Sky', 
      'phone': '+234 909 113 5588', 
      'type': ListerType.realEstateCompany,
      'companyName': 'SkyLine Properties NG',
      'logo': 'https://api.dicebear.com/7.x/initials/png?seed=SKY&backgroundColor=0f766e'
    },
  ];

  // ── Neighbourhood data per city ───────────────────────────────────────────
  final List<Map<String, dynamic>> cityData = [
    {
      'city': 'Abuja',
      'center': kubwaAbuja,
      'scatter': 0.09,
      'hoods': [
        'Kubwa',
        'Gwarinpa',
        'Wuse 2',
        'Maitama',
        'Garki',
        'Jabi',
        'Utako',
        'Asokoro',
        'Lugbe',
        'Karu',
        'Lokogoma',
        'Kafe',
      ],
    },
    {
      'city': 'Port Harcourt',
      'center': portHarcourt,
      'scatter': 0.07,
      'hoods': [
        'GRA Phase 1',
        'GRA Phase 2',
        'Rumuola',
        'Rumuokoro',
        'Peter Odili',
        'Eliozu',
        'Choba',
        'Woji',
        'Ada-George',
        'Diobu',
        'Borikiri',
      ],
    },
    {
      'city': 'Lagos Island',
      'center': lagos,
      'scatter': 0.06,
      'hoods': [
        'Victoria Island',
        'Ikoyi',
        'Lagos Island',
        'Onikan',
        'Marina',
        'Surulere',
        'Yaba',
        'Ebute-Meta',
        'Apapa',
      ],
    },
    {
      'city': 'Lekki',
      'center': lekki,
      'scatter': 0.05,
      'hoods': [
        'Lekki Phase 1',
        'Lekki Phase 2',
        'Chevron',
        'VGC',
        'Ajah',
        'Sangotedo',
        'Abraham Adesanya',
        'Jakande',
        'Thomas Estate',
      ],
    },
    {
      'city': 'Ikeja',
      'center': ikeja,
      'scatter': 0.05,
      'hoods': [
        'GRA Ikeja',
        'Alausa',
        'Maryland',
        'Ogba',
        'Agege',
        'Omole Phase 1',
        'Omole Phase 2',
        'Magodo',
        'Ojodu Berger',
      ],
    },
    {
      'city': 'Ibadan',
      'center': ibadan,
      'scatter': 0.08,
      'hoods': [
        'Bodija',
        'Jericho',
        'New Bodija',
        'Akobo',
        'Oluyole',
        'Ring Road',
        'Iyaganku',
        'Agodi',
        'Molete',
      ],
    },
    {
      'city': 'Kano',
      'center': kano,
      'scatter': 0.08,
      'hoods': [
        'Nassarawa GRA',
        'Bompai',
        'Sabon Gari',
        'Fagge',
        'Zoo Road',
        'Kofar Wambai',
        'Gwale',
        'Tarauni',
      ],
    },
    {
      'city': 'Enugu',
      'center': enugu,
      'scatter': 0.07,
      'hoods': [
        'GRA Enugu',
        'Independence Layout',
        'Trans Ekulu',
        'New Haven',
        'Achara Layout',
        'Maryland',
        'Abakpa',
      ],
    },
    {
      'city': 'Benin City',
      'center': benin,
      'scatter': 0.07,
      'hoods': [
        'GRA Benin',
        'Ugbowo',
        'Aduwawa',
        'Sapele Road',
        'Upper Sokponba',
        'Ekehuan Road',
        'Ikpoba Hill',
        'Egor',
      ],
    },
  ];

  // ── Property title templates ───────────────────────────────────────────────
  final Map<PropertyType, List<String>> titleTemplates = {
    PropertyType.flatsAndApartments: [
      'Spacious Apartment', 'Luxury Flat', 'Newly Built Apartment',
      'Tastefully Furnished Flat', 'Modern Studio Apartment', 'Executive Penthouse Flat',
    ],
    PropertyType.house: [
      'Executive Family House', 'Modern 4-Bedroom House', 'Luxury Detached House',
      'Corner-piece House', 'Newly Built House',
    ],
    PropertyType.detachedDuplex: [
      'Exquisite 4-Bedroom Duplex', 'Contemporary Duplex', 'Luxury 5-Bed Duplex', 'Executive Twin-Duplex',
    ],
    PropertyType.semiDetachedDuplex: [
      'Semi-Detached Duplex', 'Elegant Semi-Duplex', 'Smart Semi-Detached', 'Affordable Semi-Duplex',
    ],
    PropertyType.terracedDuplex: [
      'Terraced Duplex', 'Modern Terraced Unit', 'Luxury Terrace Duplex', 'Executive Terrace',
    ],
    PropertyType.detachedBungalows: [
      'Detached Bungalow', '4-Bed Executive Bungalow', 'Corner-piece Bungalow', 'Classic Bungalow',
    ],
    PropertyType.semiDetachedBungalows: [
      'Semi-Detached Bungalow', '3-Bed Semi-Bungalow', 'Affordable Semi-Detached', 'Smart Bungalow',
    ],
    PropertyType.terracedBungalows: [
      'Terraced Bungalow', 'Modern Terraced Bungalow', 'Neat Terrace Unit', 'Family Terrace Bungalow',
    ],
    PropertyType.lands: [
      'Dry Land Plot', 'Gated Estate Plot', 'Corner Plot (Fenced)', 'Survey Plan Land',
      'Commercial Land with C of O', 'Strategic Land Investment',
    ],
    PropertyType.shops: [
      'Shop Space', 'Open-Plan Shop', 'Roadside Shop', 'Retail Space', 'Ground-Floor Shop',
    ],
    PropertyType.shopInAMall: [
      'Shop in a Mall', 'Prime Mall Unit', 'Retail Unit in Plaza', 'Commercial Store in Mall',
    ],
    PropertyType.officeSpace: [
      'Open Plan Office', 'Private Office Suite', 'Executive Office Floor', 'Corporate Office Space',
    ],
    PropertyType.coWorkingSpace: [
      'Shared Co-Working Hub', 'Hot-Desk Office Space', 'Creative Co-Working Studio', 'Tech Co-Work Space',
    ],
    PropertyType.warehouse: [
      'Industrial Warehouse', 'Storage Facility', 'Factory Warehouse', 'Logistics Warehouse',
    ],
    PropertyType.commercialProperties: [
      'Commercial Complex', 'Mixed-Use Commercial Property', 'Investment Commercial Property', 'Plaza & Retail Block',
    ],
  };

  // ── Descriptions templates ────────────────────────────────────────────────
  final Map<String, List<String>> descTemplates = {
    'buy': [
      'This property is a rare find in one of the most sought-after locations. C of O available. Ideal for family living or investment.',
      'Beautifully finished property with modern fittings. All documents intact — survey, C of O, and deed of assignment available.',
      'Strategically located property with excellent road access, covered by an estate perimeter fence, and power infrastructure.',
      'Ready-to-move-in property in a highbrow estate. Title document is governor\'s consent — fully transferable.',
    ],
    'yr': [
      'A well-maintained property in a peaceful neighborhood. Power supply is exceptional; predominantly estate power.',
      'Freshly painted and tiled. Borehole water supply guaranteed. Agent is honest and responsive — no hidden charges.',
      'Newly renovated with new plumbing and electrical fittings throughout. Located on a tarred road with good drainage.',
    ],
    'mo': [
      'Available for short-term stay on a monthly basis. Furnished options negotiable with agent directly.',
      'Perfect for workers on secondment or project teams. Close to major offices and amenities.',
      'Serviced apartment available monthly. Bills are sometimes inclusive — confirm with the agent.',
    ],
    'wk': [
      'Weekly short-let available. Fully kitted — washing machine, kitchen appliances, Wi-Fi, generator.',
      'Great for business travelers. Clean, secure, and well-maintained property in a prime area.',
      'Short-let option available weekly. Contact agent for availability calendar.',
    ],
    'day': [
      'Available for daily short-let and Airbnb bookings. Contact agent 24hrs in advance.',
      'Ideal for events, weekend getaways, or transit lodging. Professionally managed property.',
      'Daily short-let with housekeeping included at premium rate. Book directly through the agent.',
    ],
  };

  final List<Property> properties = [];
  int idCounter = 1;

  String formatPrice(double price) {
    if (price >= 1000000000) {
      return '₦${(price / 1000000000).toStringAsFixed(1)}B';
    } else if (price >= 1000000) {
      return '₦${(price / 1000000).toStringAsFixed(price >= 10000000 ? 0 : 1)}M';
    } else if (price >= 1000) {
      return '₦${(price / 1000).toStringAsFixed(0)}k';
    }
    return '₦${price.toStringAsFixed(0)}';
  }

  // Guarantee all terms are well-represented:
  // For each city we explicitly assign term distribution
  // buy: 25%, yr: 30%, mo: 20%, wk: 15%, day: 10%
  final List<String> termDistribution = [
    'buy', 'buy', 'buy', // 3
    'yr', 'yr', 'yr', 'yr', // 4
    'mo', 'mo', 'mo', // 3
    'wk', 'wk', // 2
    'day', 'day', // 2
  ]; // cycle of 14

  for (final cityInfo in cityData) {
    final String cityName = cityInfo['city'] as String;
    final LatLng center = cityInfo['center'] as LatLng;
    final double scatter = cityInfo['scatter'] as double;
    final List<String> hoods = List<String>.from(cityInfo['hoods'] as List);

    // Vary property count per city
    final int count =
        cityName == 'Abuja' || cityName == 'Lagos Island' || cityName == 'Lekki'
        ? 22
        : cityName == 'Port Harcourt' || cityName == 'Ikeja'
        ? 18
        : 12;

    for (int i = 0; i < count; i++) {
      final latOffset = (random.nextDouble() - 0.5) * scatter;
      final lngOffset = (random.nextDouble() - 0.5) * scatter;
      final loc = LatLng(
        center.latitude + latOffset,
        center.longitude + lngOffset,
      );

      final typeIdx = random.nextInt(PropertyType.values.length);
      final type = PropertyType.values[typeIdx];
      final term = termDistribution[(idCounter - 1) % termDistribution.length];
      final hood = hoods[random.nextInt(hoods.length)];

      // Pricing based on term + type + city premium
      double basePrice;
      final cityMultiplier = cityName == 'Lekki' || cityName == 'Ikeja'
          ? 1.4
          : cityName == 'Abuja'
          ? 1.2
          : cityName == 'Lagos Island'
          ? 1.3
          : 1.0;

      switch (term) {
        case 'day':
          basePrice = (12000 + random.nextInt(38000)) * cityMultiplier;
          break;
        case 'wk':
          basePrice = (60000 + random.nextInt(140000)) * cityMultiplier;
          break;
        case 'mo':
          basePrice = (150000 + random.nextInt(700000)) * cityMultiplier;
          break;
        case 'buy':
          // Wide range: from ₦2M (shop) up to ₦350M (luxury duplex)
          if (type == PropertyType.lands) {
            basePrice = (4500000 + random.nextInt(30000000)) * cityMultiplier;
          } else if (type == PropertyType.detachedDuplex || type == PropertyType.house) {
            basePrice = (60000000 + random.nextInt(220000000)) * cityMultiplier;
          } else if (type == PropertyType.semiDetachedDuplex || type == PropertyType.terracedDuplex) {
            basePrice = (35000000 + random.nextInt(80000000)) * cityMultiplier;
          } else if (type == PropertyType.detachedBungalows) {
            basePrice = (25000000 + random.nextInt(60000000)) * cityMultiplier;
          } else if (type == PropertyType.semiDetachedBungalows || type == PropertyType.terracedBungalows) {
            basePrice = (15000000 + random.nextInt(35000000)) * cityMultiplier;
          } else if (type == PropertyType.flatsAndApartments) {
            basePrice = (10000000 + random.nextInt(40000000)) * cityMultiplier;
          } else if (type == PropertyType.commercialProperties || type == PropertyType.warehouse) {
            basePrice = (20000000 + random.nextInt(100000000)) * cityMultiplier;
          } else if (type == PropertyType.officeSpace || type == PropertyType.coWorkingSpace) {
            basePrice = (8000000 + random.nextInt(30000000)) * cityMultiplier;
          } else {
            // shops, shopInAMall
            basePrice = (2000000 + random.nextInt(12000000)) * cityMultiplier;
          }
          break;
        default: // yr
          basePrice = (700000 + random.nextInt(5300000)) * cityMultiplier;
      }

      // Beds & baths based on type
      final bool isCommercial = type == PropertyType.lands ||
          type == PropertyType.shops || type == PropertyType.shopInAMall ||
          type == PropertyType.officeSpace || type == PropertyType.coWorkingSpace ||
          type == PropertyType.warehouse || type == PropertyType.commercialProperties;
      final beds = isCommercial ? 0
          : type == PropertyType.flatsAndApartments ? 1 + random.nextInt(3)
          : type == PropertyType.semiDetachedBungalows || type == PropertyType.terracedBungalows ? 2 + random.nextInt(2)
          : type == PropertyType.detachedBungalows ? 3 + random.nextInt(2)
          : type == PropertyType.semiDetachedDuplex || type == PropertyType.terracedDuplex ? 3 + random.nextInt(2)
          : 4 + random.nextInt(2); // duplex, house
      final baths = isCommercial ? 0 : max(1, beds - random.nextInt(2));

      final imgPool = typeImages[type] ?? typeImages[PropertyType.house]!;
      final mainImg = imgPool[random.nextInt(imgPool.length)];
      final gallerySet = <String>{mainImg};
      int targetGallery = 3 + random.nextInt(4);
      if (targetGallery > imgPool.length) {
        targetGallery = imgPool.length;
      }
      while (gallerySet.length < targetGallery) {
        gallerySet.add(imgPool[random.nextInt(imgPool.length)]);
      }

      // Amenities
      final amensCount = type == PropertyType.lands ? 2 : 4 + random.nextInt(6);
      final shuffled = List<String>.from(amenitiesPool)..shuffle(random);
      final amens = shuffled.take(amensCount).toList();

      // Lister
      final lister = listers[random.nextInt(listers.length)];

      // has video / 360 / plan
      final bool isCommercialType = type == PropertyType.lands ||
          type == PropertyType.shops || type == PropertyType.shopInAMall ||
          type == PropertyType.officeSpace || type == PropertyType.coWorkingSpace ||
          type == PropertyType.warehouse || type == PropertyType.commercialProperties;
      final has360 = random.nextDouble() > 0.6;
      final hasVid = !isCommercialType && random.nextDouble() > 0.45;
      final hasPlan = random.nextDouble() > 0.5;

      // Description
      final descList = descTemplates[term] ?? descTemplates['yr']!;
      final desc =
          '${descList[random.nextInt(descList.length)]} '
          'This ${type.name} is situated in $hood, $cityName. '
          '${amens.take(3).join(', ')} and more.';

      // Title
      final titleList = titleTemplates[type] ?? ['Property'];
      final titleBase = titleList[random.nextInt(titleList.length)];
      final title = '$titleBase in $hood';

      properties.add(
        Property(
          id: 'prop_$idCounter',
          title: title,
          locationName: '$hood, $cityName',
          price: basePrice,
          priceTerm: term,
          formattedPrice: formatPrice(basePrice),
          location: loc,
          type: type,
          beds: beds,
          baths: baths,
          imageUrl: mainImg,
          description: desc,
          imagesGallery: gallerySet.toList(),
          planImageUrl: hasPlan
              ? planImages[random.nextInt(planImages.length)]
              : null,
          has360View: has360,
          hasVideo: hasVid,
          amenities: amens,
          listerName: lister['name'] as String,
          listerType: lister['type'] as ListerType,
          companyName: lister['companyName'] as String?,
          listerLogoUrl: lister['logo'] as String?,
          agentPhone: lister['phone'] as String,
          isVerified: random.nextDouble() > 0.45,
          proximityToRoadMeters: 10 + random.nextInt(800),
          electricitySupplyHours: 4.0 + random.nextInt(20).toDouble(),
          hasRunningWater: random.nextBool(),
          proximityToHospitalKm: 0.5 + random.nextDouble() * 14.5,
          videoUrl: hasVid ? videoUrl : null,
          panoramaUrl: has360
              ? panoramaUrls[random.nextInt(panoramaUrls.length)]
              : null,
          hasCertificateOfOccupancy: type == PropertyType.lands || type == PropertyType.house || random.nextDouble() > 0.7,
          hasLawyerVerifiedTerms: random.nextDouble() > 0.5,
          legalDocuments: [
            LegalDocument(
              title: 'Survey Plan',
              documentType: 'PDF',
              verificationDate: DateTime.now().subtract(Duration(days: random.nextInt(365))),
              status: LegalDocumentStatus.verified,
            ),
            if (random.nextDouble() > 0.6)
              LegalDocument(
                title: 'Deed of Assignment',
                documentType: 'PDF',
                verificationDate: DateTime.now().subtract(Duration(days: random.nextInt(730))),
                status: LegalDocumentStatus.verified,
              ),
          ],
          termsAndConditions: '1. All payments must be made to the designated company account.\n'
              '2. Inspection must be booked at least 24 hours in advance.\n'
              '3. Agency fee of 5-10% applies depending on the final transaction value.\n'
              '4. This property has been verified by our legal partners for authenticity.',
        ),
      );

      idCounter++;
    }
  }

  // ── 6 hand-crafted featured "hero" properties ─────────────────────────────
  properties.addAll([
    Property(
      id: 'hero_1',
      title: 'Waterfront Luxury Duplex in VGC',
      locationName: 'VGC, Lekki',
      price: 280000000,
      priceTerm: 'buy',
      formattedPrice: '₦280M',
      location: const LatLng(6.4421, 3.5512),
      type: PropertyType.detachedDuplex,
      beds: 6,
      baths: 6,
      imageUrl:
          'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=700&q=80',
      description:
          'A trophy property on the water in VGC. 6-bedroom luxury duplex with private pool, smart home system, BQ, and double garage. C of O intact. This is the pinnacle of Nigerian residential real estate.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=700&q=80',
        'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=700&q=80',
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=700&q=80',
        'https://images.unsplash.com/photo-1605276374104-dee2a0ed3cd6?w=700&q=80',
        'https://images.unsplash.com/photo-1614596683670-958fe77b0e63?w=700&q=80',
      ],
      planImageUrl:
          'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=600&q=80',
      has360View: true,
      hasVideo: true,
      amenities: [
        'Swimming Pool',
        'Smart Home System',
        'Solar Power',
        'CCTV Cameras',
        'Security Guard',
        'Fiber Internet',
        '24/7 Power',
        'Boys Quarters',
        'Gym',
        'Garden',
      ],
      listerName: 'SkyLine Properties NG',
      listerType: ListerType.realEstateCompany,
      agentPhone: '+234 909 113 5588',
      isVerified: true,
      proximityToRoadMeters: 20,
      electricitySupplyHours: 24,
      hasRunningWater: true,
      proximityToHospitalKm: 1.2,
      videoUrl:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      panoramaUrl:
          'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=2000&q=80',
    ),
    Property(
      id: 'hero_2',
      title: 'Luxury Penthouse — Short Stay',
      locationName: 'Maitama, Abuja',
      price: 185000,
      priceTerm: 'day',
      formattedPrice: '₦185k',
      location: const LatLng(9.0814, 7.4866),
      type: PropertyType.flatsAndApartments,
      beds: 3,
      baths: 3,
      imageUrl:
          'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=700&q=80',
      description:
          'Top-floor penthouse with panoramic Abuja city views. All bills inclusive — power, Wi-Fi, housekeeping, security. Available for daily short-let.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=700&q=80',
        'https://images.unsplash.com/photo-1554995207-c18c203602cb?w=700&q=80',
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=700&q=80',
      ],
      has360View: true,
      hasVideo: true,
      amenities: [
        '24/7 Power',
        'Air Conditioning',
        'Fiber Internet',
        'Water Heater',
        'Smart Home System',
        'Security Guard',
      ],
      listerName: 'Pearl Estate Mgmt',
      listerType: ListerType.realEstateCompany,
      agentPhone: '+234 817 264 7700',
      isVerified: true,
      proximityToRoadMeters: 5,
      electricitySupplyHours: 24,
      hasRunningWater: true,
      proximityToHospitalKm: 2.1,
      videoUrl:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      panoramaUrl:
          'https://images.unsplash.com/photo-1557971370-e7298ea47302?w=2000&q=80',
    ),
    Property(
      id: 'hero_3',
      title: 'Fully Serviced 3-Bed — Monthly',
      locationName: 'GRA Phase 2, Port Harcourt',
      price: 450000,
      priceTerm: 'mo',
      formattedPrice: '₦450k',
      location: const LatLng(4.8290, 7.0378),
      type: PropertyType.flatsAndApartments,
      beds: 3,
      baths: 3,
      imageUrl:
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=700&q=80',
      description:
          'Serviced apartment in GRA PH. Generator 24hrs, estate water, parking. Perfect for oil & gas executives on project tours.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=700&q=80',
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=700&q=80',
        'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=700&q=80',
      ],
      has360View: false,
      hasVideo: true,
      amenities: [
        '24/7 Power',
        'Running Water',
        'Security Guard',
        'Ample Parking',
        'Air Conditioning',
        'Generator House',
      ],
      listerName: 'Mrs. Ngozi Dike',
      listerType: ListerType.agent,
      agentPhone: '+234 907 774 0082',
      isVerified: true,
      proximityToRoadMeters: 30,
      electricitySupplyHours: 20,
      hasRunningWater: true,
      proximityToHospitalKm: 3.5,
      videoUrl:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    ),
    Property(
      id: 'hero_4',
      title: 'Massive Land — Gated Estate',
      locationName: 'Gwarinpa, Abuja',
      price: 18000000,
      priceTerm: 'buy',
      formattedPrice: '₦18M',
      location: const LatLng(9.1126, 7.3803),
      type: PropertyType.lands,
      beds: 0,
      baths: 0,
      imageUrl:
          'https://images.unsplash.com/photo-1574362848149-11496d93a7c7?w=700&q=80',
      description:
          '600sqm corner plot in Gwarinpa Estate Phase 2. Survey and C of O available. Gazette approved — no government acquisition risk. Perfect for residential or commercial development.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1574362848149-11496d93a7c7?w=700&q=80',
        'https://images.unsplash.com/photo-1449844908441-8829872d2607?w=700&q=80',
      ],
      planImageUrl:
          'https://images.unsplash.com/photo-1561715276-a2d087060f1d?w=600&q=80',
      has360View: false,
      hasVideo: false,
      amenities: ['Tarred Road', 'Fenced & Gated', 'Pre-paid Meter'],
      listerName: 'Engr. Tunde Fasola',
      listerType: ListerType.developer,
      agentPhone: '+234 811 390 5631',
      isVerified: true,
      proximityToRoadMeters: 15,
      electricitySupplyHours: 18,
      hasRunningWater: false,
      proximityToHospitalKm: 6.4,
    ),
    Property(
      id: 'hero_5',
      title: 'Weekend Getaway — Mini Flat',
      locationName: 'Lekki Phase 1, Lagos',
      price: 75000,
      priceTerm: 'wk',
      formattedPrice: '₦75k',
      location: const LatLng(6.4501, 3.5204),
      type: PropertyType.flatsAndApartments,
      beds: 1,
      baths: 1,
      imageUrl:
          'https://images.unsplash.com/photo-1523217582562-09d0def993a6?w=700&q=80',
      description:
          'Cozy Lekki studio for weekly short-lets. Fully furnished — bed, sofa, kitchen appliances, Netflix, Wi-Fi. Managed professionally. Book 48hrs ahead.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1523217582562-09d0def993a6?w=700&q=80',
        'https://images.unsplash.com/photo-1558036117-15d82a90b9b1?w=700&q=80',
        'https://images.unsplash.com/photo-1502672260266-1c1e5250fe0b?w=700&q=80',
      ],
      has360View: false,
      hasVideo: true,
      amenities: [
        'Air Conditioning',
        'Fiber Internet',
        'Water Heater',
        '24/7 Power',
      ],
      listerType: ListerType.agent, listerName: 'Caleb Homes Agency',
      agentPhone: '+234 802 887 6543',
      isVerified: true,
      proximityToRoadMeters: 100,
      electricitySupplyHours: 22,
      hasRunningWater: true,
      proximityToHospitalKm: 0.8,
      videoUrl:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    ),
    Property(
      id: 'hero_6',
      title: '5-Bed Executive Bungalow for Sale',
      locationName: 'Bodija, Ibadan',
      price: 55000000,
      priceTerm: 'buy',
      formattedPrice: '₦55M',
      location: const LatLng(7.4102, 3.9066),
      type: PropertyType.detachedBungalows,
      beds: 5,
      baths: 4,
      imageUrl:
          'https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?w=700&q=80',
      description:
          'Massive well-finished 5-bedroom bungalow with BQ in Bodija. All rooms en-suite. Custom kitchen design with island. Solar power + inverter installed. Deed of assignment + survey.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?w=700&q=80',
        'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=700&q=80',
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=700&q=80',
        'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=700&q=80',
      ],
      planImageUrl:
          'https://images.unsplash.com/photo-1600607688969-a5bfcd64bd15?w=600&q=80',
      has360View: true,
      hasVideo: false,
      amenities: [
        'Solar Power',
        'Boys Quarters',
        'En-suite',
        'Spacious Kitchen',
        'Garden',
        'Ample Parking',
        'CCTV Cameras',
        'Tiled Floors',
      ],
      listerType: ListerType.agent, listerName: 'Bode Thomas Properties',
      agentPhone: '+234 812 305 7742',
      isVerified: true,
      proximityToRoadMeters: 60,
      electricitySupplyHours: 20,
      hasRunningWater: true,
      proximityToHospitalKm: 4.5,
      panoramaUrl:
          'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=2000&q=80',
    ),
  ]);

  // ── Abuja Buy Properties (hand-crafted — 15 listings) ────────────────────
  properties.addAll([
    Property(
      id: 'abj_buy_1',
      title: '4-Bed Detached Duplex in Maitama',
      locationName: 'Maitama, Abuja',
      price: 145000000,
      priceTerm: 'buy',
      formattedPrice: '₦145M',
      location: const LatLng(9.0760, 7.4912),
      type: PropertyType.detachedDuplex,
      beds: 4,
      baths: 4,
      imageUrl:
          'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=700&q=80',
      description:
          'Exquisite 4-bedroom fully detached duplex with BQ in the prestigious Maitama district. All rooms en-suite with imported fittings. Certificate of Occupancy (C of O) available. Smart home-ready with fibre optic infrastructure.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=700&q=80',
        'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=700&q=80',
        'https://images.unsplash.com/photo-1605276374104-dee2a0ed3cd6?w=700&q=80',
        'https://images.unsplash.com/photo-1614596683670-958fe77b0e63?w=700&q=80',
      ],
      planImageUrl:
          'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=600&q=80',
      has360View: true,
      hasVideo: true,
      amenities: [
        '24/7 Power',
        'Boys Quarters',
        'Swimming Pool',
        'Smart Home System',
        'CCTV Cameras',
        'Security Guard',
        'Fiber Internet',
        'Ample Parking',
      ],
      listerName: 'SkyLine Properties NG',
      listerType: ListerType.realEstateCompany,
      agentPhone: '+234 909 113 5588',
      isVerified: true,
      proximityToRoadMeters: 25,
      electricitySupplyHours: 24,
      hasRunningWater: true,
      proximityToHospitalKm: 1.5,
      videoUrl:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      panoramaUrl:
          'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=2000&q=80',
    ),
    Property(
      id: 'abj_buy_2',
      title: '3-Bedroom Apartment in Wuse 2',
      locationName: 'Wuse 2, Abuja',
      price: 48000000,
      priceTerm: 'buy',
      formattedPrice: '₦48M',
      location: const LatLng(9.0642, 7.4786),
      type: PropertyType.flatsAndApartments,
      beds: 3,
      baths: 3,
      imageUrl:
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=700&q=80',
      description:
          'Tastefully finished 3-bedroom apartment on the 3rd floor in a secured Wuse 2 estate. 24hrs power supply, centralised water system, CCTV, and controlled access gate. Deed of Assignment ready.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=700&q=80',
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=700&q=80',
        'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=700&q=80',
      ],
      has360View: false,
      hasVideo: true,
      amenities: [
        '24/7 Power',
        'Running Water',
        'CCTV Cameras',
        'Fenced & Gated',
        'Ample Parking',
        'POP Ceiling',
        'Tiled Floors',
      ],
      listerName: 'Nnamdi Estates Ltd',
      listerType: ListerType.realEstateCompany,
      agentPhone: '+234 808 112 3344',
      isVerified: true,
      proximityToRoadMeters: 50,
      electricitySupplyHours: 22,
      hasRunningWater: true,
      proximityToHospitalKm: 2.3,
      videoUrl:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    ),
    Property(
      id: 'abj_buy_3',
      title: 'Corner-Piece Bungalow in Gwarinpa',
      locationName: 'Gwarinpa, Abuja',
      price: 32000000,
      priceTerm: 'buy',
      formattedPrice: '₦32M',
      location: const LatLng(9.1210, 7.3845),
      type: PropertyType.detachedBungalows,
      beds: 4,
      baths: 3,
      imageUrl:
          'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=700&q=80',
      description:
          'Corner-piece 4-bedroom bungalow on a 500sqm plot in Gwarinpa. Comes with a BQ and carport for 3 vehicles. Gazette survey and C of O available. Very quiet street with estate management.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=700&q=80',
        'https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?w=700&q=80',
        'https://images.unsplash.com/photo-1617104678098-de229db51175?w=700&q=80',
      ],
      planImageUrl:
          'https://images.unsplash.com/photo-1561715276-a2d087060f1d?w=600&q=80',
      has360View: false,
      hasVideo: false,
      amenities: [
        'Boys Quarters',
        'Carport',
        'Fenced & Gated',
        'Tarred Road',
        'Security Guard',
        'Generator House',
      ],
      listerName: 'Engr. Tunde Fasola',
      listerType: ListerType.developer,
      agentPhone: '+234 811 390 5631',
      isVerified: true,
      proximityToRoadMeters: 80,
      electricitySupplyHours: 16,
      hasRunningWater: true,
      proximityToHospitalKm: 3.1,
    ),
    Property(
      id: 'abj_buy_4',
      title: '500sqm Dry Land in Kafe District',
      locationName: 'Kafe, Abuja',
      price: 9500000,
      priceTerm: 'buy',
      formattedPrice: '₦9.5M',
      location: const LatLng(9.0935, 7.4401),
      type: PropertyType.lands,
      beds: 0,
      baths: 0,
      imageUrl:
          'https://images.unsplash.com/photo-1574362848149-11496d93a7c7?w=700&q=80',
      description:
          '500sqm fully dry land with survey plan in Kafe. No government acquisition. Title: Deed of Assignment with governors consent in progress. Immediate development allowed.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1574362848149-11496d93a7c7?w=700&q=80',
        'https://images.unsplash.com/photo-1449844908441-8829872d2607?w=700&q=80',
      ],
      has360View: false,
      hasVideo: false,
      amenities: ['Tarred Road', 'Survey Available', 'Fenced & Gated'],
      listerType: ListerType.agent, listerName: 'Haruna & Partners',
      agentPhone: '+234 703 445 9123',
      isVerified: false,
      proximityToRoadMeters: 200,
      electricitySupplyHours: 12,
      hasRunningWater: false,
      proximityToHospitalKm: 5.4,
    ),
    Property(
      id: 'abj_buy_5',
      title: 'Luxury 5-Bed Duplex in Asokoro',
      locationName: 'Asokoro, Abuja',
      price: 220000000,
      priceTerm: 'buy',
      formattedPrice: '₦220M',
      location: const LatLng(9.0412, 7.5190),
      type: PropertyType.detachedDuplex,
      beds: 5,
      baths: 5,
      imageUrl:
          'https://images.unsplash.com/photo-1605276374104-dee2a0ed3cd6?w=700&q=80',
      description:
          'Trophy property in Asokoro — Abuja\'s most exclusive address. 5-bed luxury duplex with private cinema, home office, 3 living rooms, fully automated lighting, landscaped garden and swimming pool. Governor\'s Consent issued.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1605276374104-dee2a0ed3cd6?w=700&q=80',
        'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=700&q=80',
        'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=700&q=80',
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=700&q=80',
        'https://images.unsplash.com/photo-1614596683670-958fe77b0e63?w=700&q=80',
      ],
      planImageUrl:
          'https://images.unsplash.com/photo-1600607688969-a5bfcd64bd15?w=600&q=80',
      has360View: true,
      hasVideo: true,
      amenities: [
        'Swimming Pool',
        'Smart Home System',
        'Solar Power',
        'Gym',
        'Boys Quarters',
        'CCTV Cameras',
        'Fiber Internet',
        '24/7 Power',
        'Garden',
        'Security Guard',
      ],
      listerType: ListerType.agent, listerName: 'Pearl Estate Mgmt',
      agentPhone: '+234 817 264 7700',
      isVerified: true,
      proximityToRoadMeters: 15,
      electricitySupplyHours: 24,
      hasRunningWater: true,
      proximityToHospitalKm: 0.9,
      videoUrl:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      panoramaUrl:
          'https://images.unsplash.com/photo-1557971370-e7298ea47302?w=2000&q=80',
    ),
    Property(
      id: 'abj_buy_6',
      title: '2-Bed Apartment in Jabi Lake View',
      locationName: 'Jabi, Abuja',
      price: 28500000,
      priceTerm: 'buy',
      formattedPrice: '₦28.5M',
      location: const LatLng(9.0817, 7.4456),
      type: PropertyType.flatsAndApartments,
      beds: 2,
      baths: 2,
      imageUrl:
          'https://images.unsplash.com/photo-1554995207-c18c203602cb?w=700&q=80',
      description:
          '2-bedroom apartment with a partial view of Jabi Lake. Modern open-plan kitchen, quality tiles throughout, centralised inverter. Perfect first home or investment rental. Registered deed available.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1554995207-c18c203602cb?w=700&q=80',
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=700&q=80',
        'https://images.unsplash.com/photo-1523217582562-09d0def993a6?w=700&q=80',
      ],
      has360View: false,
      hasVideo: false,
      amenities: [
        '24/7 Power',
        'Air Conditioning',
        'Tiled Floors',
        'Spacious Kitchen',
        'Ample Parking',
        'Fenced & Gated',
      ],
      listerType: ListerType.agent, listerName: 'Amarachi Properties',
      agentPhone: '+234 814 551 8293',
      isVerified: true,
      proximityToRoadMeters: 40,
      electricitySupplyHours: 20,
      hasRunningWater: true,
      proximityToHospitalKm: 2.7,
    ),
    Property(
      id: 'abj_buy_7',
      title: 'Self-Contain Studio Investment in Lugbe',
      locationName: 'Lugbe, Abuja',
      price: 5800000,
      priceTerm: 'buy',
      formattedPrice: '₦5.8M',
      location: const LatLng(8.9988, 7.3654),
      type: PropertyType.flatsAndApartments,
      beds: 1,
      baths: 1,
      imageUrl:
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=700&q=80',
      description:
          'Affordable studio self-contain in Lugbe — great entry-level investment property. Currently occupied and generating ₦450k/yr rental income. Registered survey. Suitable for NHF mortgage.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=700&q=80',
        'https://images.unsplash.com/photo-1502672260266-1c1e5250fe0b?w=700&q=80',
      ],
      has360View: false,
      hasVideo: false,
      amenities: ['Pre-paid Meter', 'Running Water', 'Tarred Road'],
      listerType: ListerType.agent, listerName: 'Alhaji Musa Realty',
      agentPhone: '+234 705 993 0011',
      isVerified: false,
      proximityToRoadMeters: 300,
      electricitySupplyHours: 10,
      hasRunningWater: true,
      proximityToHospitalKm: 8.2,
    ),
    Property(
      id: 'abj_buy_8',
      title: '3-Bed Terrace House in Utako',
      locationName: 'Utako, Abuja',
      price: 55000000,
      priceTerm: 'buy',
      formattedPrice: '₦55M',
      location: const LatLng(9.0748, 7.4638),
      type: PropertyType.terracedDuplex,
      beds: 3,
      baths: 3,
      imageUrl:
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=700&q=80',
      description:
          '3-bedroom terrace house in a serene Utako estate. Newly built with modern architectural design. Comes with 1 room BQ, rooftop access, tiled compound and parking for 2 cars. C of O in process.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=700&q=80',
        'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=700&q=80',
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=700&q=80',
      ],
      planImageUrl:
          'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=600&q=80',
      has360View: true,
      hasVideo: false,
      amenities: [
        'Boys Quarters',
        'Tiled Floors',
        'POP Ceiling',
        'Ample Parking',
        'Fenced & Gated',
        'Pre-paid Meter',
      ],
      listerType: ListerType.agent, listerName: 'Caleb Homes Agency',
      agentPhone: '+234 802 887 6543',
      isVerified: true,
      proximityToRoadMeters: 70,
      electricitySupplyHours: 18,
      hasRunningWater: true,
      proximityToHospitalKm: 3.3,
      panoramaUrl:
          'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=2000&q=80',
    ),
    Property(
      id: 'abj_buy_9',
      title: '1,000sqm Land in Lokogoma Estate',
      locationName: 'Lokogoma, Abuja',
      price: 22000000,
      priceTerm: 'buy',
      formattedPrice: '₦22M',
      location: const LatLng(8.9705, 7.4012),
      type: PropertyType.lands,
      beds: 0,
      baths: 0,
      imageUrl:
          'https://images.unsplash.com/photo-1449844908441-8829872d2607?w=700&q=80',
      description:
          '1,000sqm plot in Lokogoma estate. Gazette survey and deed of assignment available. Suitable for duplex, block of flats, or commercial development. Infrastructure (road, light, water) fully provided by estate.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1449844908441-8829872d2607?w=700&q=80',
        'https://images.unsplash.com/photo-1574362848149-11496d93a7c7?w=700&q=80',
      ],
      planImageUrl:
          'https://images.unsplash.com/photo-1561715276-a2d087060f1d?w=600&q=80',
      has360View: false,
      hasVideo: false,
      amenities: [
        'Tarred Road',
        'Running Water',
        'Pre-paid Meter',
        'Fenced & Gated',
      ],
      listerType: ListerType.agent, listerName: 'Bode Thomas Properties',
      agentPhone: '+234 812 305 7742',
      isVerified: true,
      proximityToRoadMeters: 50,
      electricitySupplyHours: 14,
      hasRunningWater: false,
      proximityToHospitalKm: 6.1,
    ),
    Property(
      id: 'abj_buy_10',
      title: '4-Bed Bungalow in Karu Estate',
      locationName: 'Karu, Abuja',
      price: 26000000,
      priceTerm: 'buy',
      formattedPrice: '₦26M',
      location: const LatLng(8.9912, 7.5481),
      type: PropertyType.detachedBungalows,
      beds: 4,
      baths: 3,
      imageUrl:
          'https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?w=700&q=80',
      description:
          '4-bedroom detached bungalow with tiled compound and borehole in Karu. En-suite master bedroom, spacious kitchen, and large sitting room. Survey plan and deed of assignment available. Suitable for NHF and cooperative housing mortgage.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?w=700&q=80',
        'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=700&q=80',
        'https://images.unsplash.com/photo-1617104678098-de229db51175?w=700&q=80',
      ],
      has360View: false,
      hasVideo: true,
      amenities: [
        'Running Water',
        'En-suite',
        'Tiled Floors',
        'Spacious Kitchen',
        'Generator House',
        'Tarred Road',
      ],
      listerType: ListerType.owner, listerName: 'Chief Okafor',
      agentPhone: '+234 803 421 8876',
      isVerified: false,
      proximityToRoadMeters: 150,
      electricitySupplyHours: 14,
      hasRunningWater: true,
      proximityToHospitalKm: 4.8,
      videoUrl:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    ),
    Property(
      id: 'abj_buy_11',
      title: 'Off-Plan 3-Bed in Garki 2',
      locationName: 'Garki, Abuja',
      price: 38000000,
      priceTerm: 'buy',
      formattedPrice: '₦38M',
      location: const LatLng(9.0502, 7.4837),
      type: PropertyType.flatsAndApartments,
      beds: 3,
      baths: 2,
      imageUrl:
          'https://images.unsplash.com/photo-1617104678098-de229db51175?w=700&q=80',
      description:
          'Off-plan 3-bedroom apartment in a new Garki 2 development. 30% deposit secures your unit — balance spread over 24 months before completion. High ROI location with easy access to federal ministries.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1617104678098-de229db51175?w=700&q=80',
        'https://images.unsplash.com/photo-1599427303058-f04cbcf4756f?w=700&q=80',
        'https://images.unsplash.com/photo-1598228723793-52759bba239c?w=700&q=80',
      ],
      planImageUrl:
          'https://images.unsplash.com/photo-1600607688969-a5bfcd64bd15?w=600&q=80',
      has360View: false,
      hasVideo: false,
      amenities: [
        '24/7 Power',
        'CCTV Cameras',
        'Ample Parking',
        'POP Ceiling',
        'Intercom',
        'Fenced & Gated',
      ],
      listerType: ListerType.realEstateCompany, listerName: 'Oluwaseun & Sons',
      agentPhone: '+234 901 221 4490',
      isVerified: true,
      proximityToRoadMeters: 30,
      electricitySupplyHours: 20,
      hasRunningWater: true,
      proximityToHospitalKm: 2.5,
    ),
    Property(
      id: 'abj_buy_12',
      title: 'Newly Built Semi-Detached in Kubwa',
      locationName: 'Kubwa, Abuja',
      price: 19500000,
      priceTerm: 'buy',
      formattedPrice: '₦19.5M',
      location: const LatLng(9.1621, 7.3008),
      type: PropertyType.semiDetachedBungalows,
      beds: 3,
      baths: 2,
      imageUrl:
          'https://images.unsplash.com/photo-1558036117-15d82a90b9b1?w=700&q=80',
      description:
          'Newly built semi-detached 3-bed house in Kubwa Phase 4. Modern design, ample parking, good road. Closest estate to the Kubwa expressway for easy commute. Survey plan available. Installment payment acceptable.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1558036117-15d82a90b9b1?w=700&q=80',
        'https://images.unsplash.com/photo-1584738766473-61c083514bf4?w=700&q=80',
        'https://images.unsplash.com/photo-1593696140826-c58b021acf8b?w=700&q=80',
      ],
      has360View: false,
      hasVideo: false,
      amenities: [
        'Tarred Road',
        'Pre-paid Meter',
        'Ample Parking',
        'Fenced & Gated',
        'Wardrobe',
      ],
      listerType: ListerType.agent, listerName: 'Haruna & Partners',
      agentPhone: '+234 703 445 9123',
      isVerified: false,
      proximityToRoadMeters: 100,
      electricitySupplyHours: 12,
      hasRunningWater: true,
      proximityToHospitalKm: 5.2,
    ),
    Property(
      id: 'abj_buy_13',
      title: '6-Bed Mansion in Katampe Extension',
      locationName: 'Katampe, Abuja',
      price: 310000000,
      priceTerm: 'buy',
      formattedPrice: '₦310M',
      location: const LatLng(9.0912, 7.4588),
      type: PropertyType.detachedDuplex,
      beds: 6,
      baths: 6,
      imageUrl:
          'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=700&q=80',
      description:
          'Breathtaking 6-bedroom mansion on the Katampe Extension hilltop with panoramic city views. Private pool, home cinema, 3 BQs, underground water tank 50,000L, solar farm. One of Abuja\'s finest properties. Governor\'s Consent available.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=700&q=80',
        'https://images.unsplash.com/photo-1605276374104-dee2a0ed3cd6?w=700&q=80',
        'https://images.unsplash.com/photo-1614596683670-958fe77b0e63?w=700&q=80',
        'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=700&q=80',
        'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=700&q=80',
      ],
      planImageUrl:
          'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=600&q=80',
      has360View: true,
      hasVideo: true,
      amenities: [
        'Swimming Pool',
        'Solar Power',
        'Smart Home System',
        'Gym',
        '3 Boys Quarters',
        'CCTV Cameras',
        'Fiber Internet',
        '24/7 Power',
        'Landscaped Garden',
        'Security Guard',
      ],
      listerType: ListerType.agent, listerName: 'Pearl Estate Mgmt',
      agentPhone: '+234 817 264 7700',
      isVerified: true,
      proximityToRoadMeters: 10,
      electricitySupplyHours: 24,
      hasRunningWater: true,
      proximityToHospitalKm: 1.1,
      videoUrl:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      panoramaUrl:
          'https://images.unsplash.com/photo-1557971370-e7298ea47302?w=2000&q=80',
    ),
    Property(
      id: 'abj_buy_14',
      title: '2-Bed Flat in Mpape Hills',
      locationName: 'Mpape, Abuja',
      price: 8500000,
      priceTerm: 'buy',
      formattedPrice: '₦8.5M',
      location: const LatLng(9.0991, 7.4302),
      type: PropertyType.flatsAndApartments,
      beds: 2,
      baths: 1,
      imageUrl:
          'https://images.unsplash.com/photo-1523217582562-09d0def993a6?w=700&q=80',
      description:
          'Affordable 2-bedroom flat in Mpape — one of the fastest-growing Abuja suburbs. Great starter home or buy-to-let investment. On a tarred road. Deed of assignment in seller\'s possession. Suitable for NHF first-time buyer scheme.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1523217582562-09d0def993a6?w=700&q=80',
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=700&q=80',
      ],
      has360View: false,
      hasVideo: false,
      amenities: ['Pre-paid Meter', 'Tarred Road', 'Running Water', 'Wardrobe'],
      listerType: ListerType.owner, listerName: 'Mrs. Ngozi Dike',
      agentPhone: '+234 907 774 0082',
      isVerified: false,
      proximityToRoadMeters: 200,
      electricitySupplyHours: 10,
      hasRunningWater: true,
      proximityToHospitalKm: 7.4,
    ),
    Property(
      id: 'abj_buy_15',
      title: '3-Bed Bungalow — NHF Ready, Lugbe',
      locationName: 'Lugbe, Abuja',
      price: 15500000,
      priceTerm: 'buy',
      formattedPrice: '₦15.5M',
      location: const LatLng(9.0023, 7.3455),
      type: PropertyType.detachedBungalows,
      beds: 3,
      baths: 2,
      imageUrl:
          'https://images.unsplash.com/photo-1464146072230-91cabc968266?w=700&q=80',
      description:
          '3-bedroom bungalow in Lugbe Extension — priced within the NHF mortgage band. All documents intact: survey, deed of assignment, building plan approval. Move-in ready. Tiled floors, granite worktops, ample compound space.',
      imagesGallery: [
        'https://images.unsplash.com/photo-1464146072230-91cabc968266?w=700&q=80',
        'https://images.unsplash.com/photo-1518780664697-55e3ad937233?w=700&q=80',
        'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=700&q=80',
      ],
      has360View: false,
      hasVideo: true,
      amenities: [
        'Tiled Floors',
        'Spacious Kitchen',
        'Pre-paid Meter',
        'Tarred Road',
        'Running Water',
        'En-suite',
      ],
      listerType: ListerType.agent, listerName: 'Amarachi Properties',
      agentPhone: '+234 814 551 8293',
      isVerified: true,
      proximityToRoadMeters: 120,
      electricitySupplyHours: 14,
      hasRunningWater: true,
      proximityToHospitalKm: 3.8,
      videoUrl:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      viewsCount: 1240,
      favoritesCount: 45,
      videoViewsCount: 12,
    ),
  ]);

  return properties;
}

final List<Property> mockProperties = _generateMockData();

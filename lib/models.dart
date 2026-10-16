import 'package:cloud_firestore/cloud_firestore.dart';

// ==================== USER MODEL ====================
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? imageUrl;
  final String? fcmToken;
  final bool isAdmin;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.imageUrl,
    this.fcmToken,
    this.isAdmin = false,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      imageUrl: map['imageUrl'],
      fcmToken: map['fcmToken'],
      isAdmin: map['isAdmin'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'imageUrl': imageUrl,
        'fcmToken': fcmToken,
        'isAdmin': isAdmin,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserModel copyWith({
    String? name,
    String? phone,
    String? imageUrl,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      isAdmin: isAdmin,
      createdAt: createdAt,
    );
  }
}

// ==================== CATEGORY MODEL ====================
class CategoryModel {
  final String id;
  final String name;
  final String imagePath;
  final int order;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    this.imagePath = '',
    this.order = 0,
    this.isActive = true,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      name: map['name'] ?? '',
      imagePath: map['imagePath'] ?? '',
      order: map['order'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'imagePath': imagePath,
        'order': order,
        'isActive': isActive,
      };
}

// ==================== SIZE MODEL ====================
class SizeModel {
  final String name;
  final double price;

  SizeModel({required this.name, required this.price});

  factory SizeModel.fromMap(Map<String, dynamic> map) => SizeModel(
        name: map['name'] ?? '',
        price: (map['price'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toMap() => {'name': name, 'price': price};
}

// ==================== ADDON MODEL ====================
class AddonModel {
  final String name;
  final double price;

  AddonModel({required this.name, required this.price});

  factory AddonModel.fromMap(Map<String, dynamic> map) => AddonModel(
        name: map['name'] ?? '',
        price: (map['price'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toMap() => {'name': name, 'price': price};
}

// ==================== PRODUCT MODEL ====================
class ProductModel {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final String categoryId;
  final String categoryName;
  final double basePrice;
  final List<SizeModel> sizes;
  final List<AddonModel> addons;
  final bool isAvailable;
  final bool isPopular;
  final int order;
  final DateTime? createdAt;

  ProductModel({
    required this.id,
    required this.name,
    this.description = '',
    this.imagePath = '',
    required this.categoryId,
    this.categoryName = '',
    required this.basePrice,
    this.sizes = const [],
    this.addons = const [],
    this.isAvailable = true,
    this.isPopular = false,
    this.order = 0,
    this.createdAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imagePath: map['imagePath'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      basePrice: (map['basePrice'] ?? 0).toDouble(),
      sizes: (map['sizes'] as List<dynamic>?)
              ?.map((e) => SizeModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      addons: (map['addons'] as List<dynamic>?)
              ?.map((e) => AddonModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      isAvailable: map['isAvailable'] ?? true,
      isPopular: map['isPopular'] ?? false,
      order: map['order'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'imagePath': imagePath,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'basePrice': basePrice,
        'sizes': sizes.map((e) => e.toMap()).toList(),
        'addons': addons.map((e) => e.toMap()).toList(),
        'isAvailable': isAvailable,
        'isPopular': isPopular,
        'order': order,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}

// ==================== DEAL MODEL ====================
class DealModel {
  final String id;
  final String title;
  final String description;
  final String imagePath;
  final double price;
  final double originalPrice;
  final List<String> items;
  final DateTime? validTill;
  final bool isActive;
  final int order;
  final DateTime? createdAt;

  DealModel({
    required this.id,
    required this.title,
    this.description = '',
    this.imagePath = '',
    required this.price,
    this.originalPrice = 0,
    this.items = const [],
    this.validTill,
    this.isActive = true,
    this.order = 0,
    this.createdAt,
  });

  double get discount => originalPrice > 0 ? originalPrice - price : 0;

  factory DealModel.fromMap(Map<String, dynamic> map, String id) {
    return DealModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imagePath: map['imagePath'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      originalPrice: (map['originalPrice'] ?? 0).toDouble(),
      items: (map['items'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      validTill: (map['validTill'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] ?? true,
      order: map['order'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'imagePath': imagePath,
        'price': price,
        'originalPrice': originalPrice,
        'items': items,
        'validTill': validTill != null ? Timestamp.fromDate(validTill!) : null,
        'isActive': isActive,
        'order': order,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}

// ==================== BANNER MODEL ====================
class BannerModel {
  final String id;
  final String imagePath;
  final String? title;
  final int order;
  final bool isActive;

  BannerModel({
    required this.id,
    this.imagePath = '',
    this.title,
    this.order = 0,
    this.isActive = true,
  });

  factory BannerModel.fromMap(Map<String, dynamic> map, String id) {
    return BannerModel(
      id: id,
      imagePath: map['imagePath'] ?? '',
      title: map['title'],
      order: map['order'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'imagePath': imagePath,
        'title': title,
        'order': order,
        'isActive': isActive,
      };
}

// ==================== CART ITEM MODEL ====================
class CartItemModel {
  final String productId;
  final String name;
  final String imagePath;
  final String? sizeName;
  final List<String> addonNames;
  final int quantity;
  final double unitPrice;
  final String? instruction;

  CartItemModel({
    required this.productId,
    required this.name,
    this.imagePath = '',
    this.sizeName,
    this.addonNames = const [],
    this.quantity = 1,
    required this.unitPrice,
    this.instruction,
  });

  double get lineTotal => unitPrice * quantity;

  String get key =>
      '$productId-${sizeName ?? "default"}-${addonNames.join(",")}';

  CartItemModel copyWith({int? quantity}) => CartItemModel(
        productId: productId,
        name: name,
        imagePath: imagePath,
        sizeName: sizeName,
        addonNames: addonNames,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice,
        instruction: instruction,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'imagePath': imagePath,
        'sizeName': sizeName,
        'addonNames': addonNames,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'instruction': instruction,
      };
}

// ==================== ADDRESS MODEL ====================
class AddressModel {
  final String id;
  final String label;
  final String houseNumber;
  final String street;
  final String area;
  final String? landmark;
  final String phone;
  final double lat;
  final double lng;
  final bool isDefault;

  AddressModel({
    required this.id,
    this.label = 'Home',
    required this.houseNumber,
    this.street = '',
    this.area = '',
    this.landmark,
    required this.phone,
    this.lat = 0,
    this.lng = 0,
    this.isDefault = false,
  });

  String get fullAddress => [
        houseNumber,
        street,
        area,
      ].where((s) => s.trim().isNotEmpty).join(', ');

  factory AddressModel.fromMap(Map<String, dynamic> map, String id) {
    return AddressModel(
      id: id,
      label: map['label'] ?? 'Home',
      houseNumber: map['houseNumber'] ?? '',
      street: map['street'] ?? '',
      area: map['area'] ?? '',
      landmark: map['landmark'],
      phone: map['phone'] ?? '',
      lat: (map['lat'] ?? 0).toDouble(),
      lng: (map['lng'] ?? 0).toDouble(),
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'label': label,
        'houseNumber': houseNumber,
        'street': street,
        'area': area,
        'landmark': landmark,
        'phone': phone,
        'lat': lat,
        'lng': lng,
        'isDefault': isDefault,
      };
}

// ==================== ORDER ITEM MODEL ====================
class OrderItemModel {
  final String productId;
  final String name;
  final String imagePath;
  final String? sizeName;
  final List<String> addonNames;
  final int quantity;
  final double unitPrice;

  OrderItemModel({
    required this.productId,
    required this.name,
    this.imagePath = '',
    this.sizeName,
    this.addonNames = const [],
    required this.quantity,
    required this.unitPrice,
  });

  double get lineTotal => unitPrice * quantity;

  factory OrderItemModel.fromMap(Map<String, dynamic> map) => OrderItemModel(
        productId: map['productId'] ?? '',
        name: map['name'] ?? '',
        imagePath: map['imagePath'] ?? '',
        sizeName: map['sizeName'],
        addonNames: (map['addonNames'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        quantity: map['quantity'] ?? 1,
        unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'imagePath': imagePath,
        'sizeName': sizeName,
        'addonNames': addonNames,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };
}

// ==================== ORDER MODEL ====================
class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final List<OrderItemModel> items;
  final String orderType;
  final AddressModel? address;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double tip;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final String? note;
  final String? promoCode;
  final DateTime createdAt;
  final double liveLat;
  final double liveLng;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.items,
    this.orderType = 'delivery',
    this.address,
    required this.subtotal,
    this.deliveryFee = 0,
    this.discount = 0,
    this.tip = 0,
    required this.total,
    this.paymentMethod = 'cod',
    this.paymentStatus = 'pending',
    this.status = 'placed',
    this.note,
    this.promoCode,
    required this.createdAt,
    this.liveLat = 0,
    this.liveLng = 0,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      orderType: map['orderType'] ?? 'delivery',
      address: map['address'] != null
          ? AddressModel.fromMap(map['address'] as Map<String, dynamic>, '')
          : null,
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      tip: (map['tip'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'cod',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      status: map['status'] ?? 'placed',
      note: map['note'],
      promoCode: map['promoCode'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      liveLat: (map['liveLat'] ?? 0).toDouble(),
      liveLng: (map['liveLng'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'items': items.map((e) => e.toMap()).toList(),
        'orderType': orderType,
        'address': address?.toMap(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'discount': discount,
        'tip': tip,
        'total': total,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'status': status,
        'note': note,
        'promoCode': promoCode,
        'createdAt': Timestamp.fromDate(createdAt),
        'liveLat': liveLat,
        'liveLng': liveLng,
      };
}

// ==================== PROMO MODEL ====================
class PromoModel {
  final String id;
  final String code;
  final String type;
  final double value;
  final double minOrder;
  final double maxDiscount;
  final DateTime? expiry;
  final bool isActive;

  PromoModel({
    required this.id,
    required this.code,
    this.type = 'percent',
    required this.value,
    this.minOrder = 0,
    this.maxDiscount = 0,
    this.expiry,
    this.isActive = true,
  });

  factory PromoModel.fromMap(Map<String, dynamic> map, String id) {
    return PromoModel(
      id: id,
      code: map['code'] ?? '',
      type: map['type'] ?? 'percent',
      value: (map['value'] ?? 0).toDouble(),
      minOrder: (map['minOrder'] ?? 0).toDouble(),
      maxDiscount: (map['maxDiscount'] ?? 0).toDouble(),
      expiry: (map['expiry'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'code': code,
        'type': type,
        'value': value,
        'minOrder': minOrder,
        'maxDiscount': maxDiscount,
        'expiry': expiry != null ? Timestamp.fromDate(expiry!) : null,
        'isActive': isActive,
      };
}

// ==================== SETTINGS MODEL ====================
class SettingsModel {
  final double deliveryFee;
  final double minOrder;
  final double freeDelivery;
  final bool isOpen;
  final String contactNumber;
  final String whatsappNumber;
  final String restaurantAddress;
  final double deliveryRadiusKm;
  final double restaurantLat;
  final double restaurantLng;
  final bool holidayMode;
  final String holidayReason;

  SettingsModel({
    this.deliveryFee = 100,
    this.minOrder = 1000,
    this.freeDelivery = 1500,
    this.isOpen = true,
    this.contactNumber = '0314-3636434',
    this.whatsappNumber = '03259869056',
    this.restaurantAddress = 'Pakpattan Chowk, Sahiwal',
    this.deliveryRadiusKm = 5,
    this.restaurantLat = 30.653329349399,
    this.restaurantLng = 73.1191797513746,
    this.holidayMode = false,
    this.holidayReason = '',
  });

  factory SettingsModel.fromMap(Map<String, dynamic> map) => SettingsModel(
        deliveryFee: (map['deliveryFee'] ?? 100).toDouble(),
        minOrder: (map['minOrder'] ?? 1000).toDouble(),
        freeDelivery: (map['freeDelivery'] ?? 1500).toDouble(),
        isOpen: map['isOpen'] ?? true,
        contactNumber: map['contactNumber'] ?? '0314-3636434',
        whatsappNumber: map['whatsappNumber'] ?? '03259869056',
        restaurantAddress:
            map['restaurantAddress'] ?? 'Pakpattan Chowk, Sahiwal',
        deliveryRadiusKm: (map['deliveryRadiusKm'] ?? 5).toDouble(),
        restaurantLat:
            (map['restaurantLat'] ?? 30.653329349399).toDouble(),
        restaurantLng:
            (map['restaurantLng'] ?? 73.1191797513746).toDouble(),
        holidayMode: map['holidayMode'] ?? false,
        holidayReason: map['holidayReason'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'deliveryFee': deliveryFee,
        'minOrder': minOrder,
        'freeDelivery': freeDelivery,
        'isOpen': isOpen,
        'contactNumber': contactNumber,
        'whatsappNumber': whatsappNumber,
        'restaurantAddress': restaurantAddress,
        'deliveryRadiusKm': deliveryRadiusKm,
        'restaurantLat': restaurantLat,
        'restaurantLng': restaurantLng,
        'holidayMode': holidayMode,
        'holidayReason': holidayReason,
      };
}

// ==================== DELIVERY LOCATION MODEL ====================
class DeliveryLocation {
  final double lat;
  final double lng;
  final String address;
  final String house;
  final String landmark;
  final double distanceKm;

  DeliveryLocation({
    required this.lat,
    required this.lng,
    required this.address,
    required this.house,
    this.landmark = '',
    required this.distanceKm,
  });

  String get fullAddress => [
        house,
        address,
        landmark,
      ].where((s) => s.trim().isNotEmpty).join(', ');

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        'address': address,
        'house': house,
        'landmark': landmark,
        'distanceKm': double.parse(distanceKm.toStringAsFixed(2)),
      };
}

// ==================== REVIEW MODEL ====================
class ReviewModel {
  final String id;
  final String orderId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment = '',
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      orderId: map['orderId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'orderId': orderId,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ==================== NOTIFICATION MODEL ====================
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
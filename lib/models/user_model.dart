class UserProfile {
  final String? name;
  final String? surname;
  final String? profileUrl;
  final bool? active;
  final bool? phoneVerified;
  final String? birthday;
  final String? identityNumber;
  final String? email;
  final String? address;
  final String? createdAt;
  final String? updatedAt;

  UserProfile({
    this.name,
    this.surname,
    this.profileUrl,
    this.active,
    this.phoneVerified,
    this.birthday,
    this.identityNumber,
    this.email,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  // API yanıtından model oluştur
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'],
      surname: json['surname'],
      profileUrl: json['profileUrl'],
      active: json['active'],
      phoneVerified: json['phoneVerified'],
      birthday: json['birthday'],
      identityNumber: json['identityNumber'],
      email: json['email'],
      address: json['address'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  // Modeli JSON'a dönüştür (API'ye gönderilecek)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'surname': surname,
      'profileUrl': profileUrl,
      'email': email,
      'address': address,
      'birthday': birthday,
      'identityNumber': identityNumber,
    };
  }

  // Tam ad döndürme yardımcı metodu
  String get fullName => '$name $surname'.trim();

  // Oluşturma tarihini formatla
  String get formattedCreatedAt {
    if (createdAt == null) return '';
    final date = DateTime.parse(createdAt!);
    return '${date.day}.${date.month}.${date.year}';
  }

  // Güncelleme tarihini formatla
  String get formattedUpdatedAt {
    if (updatedAt == null) return '';
    final date = DateTime.parse(updatedAt!);
    return '${date.day}.${date.month}.${date.year}';
  }

  // Doğum tarihini formatla
  String get formattedBirthday {
    if (birthday == null) return '';
    final date = DateTime.parse(birthday!);
    return '${date.day}.${date.month}.${date.year}';
  }

  // Boş profil oluştur
  factory UserProfile.empty() {
    return UserProfile(
      name: '',
      surname: '',
      email: '',
      address: '',
      active: true,
      phoneVerified: false,
    );
  }
} 
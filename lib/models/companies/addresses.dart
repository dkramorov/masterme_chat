import 'package:masterme_chat/db/database_singletone.dart';

class Addresses extends AbstractModel {
  final int id;
  final String city;
  final int branchesCount;
  final String district;
  final String additionalData;
  final String country;
  final String subdistrict;
  final String searchTerms;
  final double longitude;
  final double latitude;
  final String county;
  final String state;
  final String street;
  final String place;
  final String addressLines;
  final String postalCode;
  final String houseNumber;

  static final String dbName = AbstractModel.dbCompaniesName;
  static final String tableName = 'addresses';

  @override
  String getDbName() {
    return dbName;
  }

  @override
  String getTableName() {
    return Addresses.tableName;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'city': city,
      'branchesCount': branchesCount,
      'district': district,
      'additionalData': additionalData,
      'country': country,
      'subdistrict': subdistrict,
      'searchTerms': searchTerms,
      'longitude': longitude,
      'latitude': latitude,
      'county': county,
      'state': state,
      'street': street,
      'place': place,
      'addressLines': addressLines,
      'postalCode': postalCode,
      'houseNumber': houseNumber,
    };
  }

  Addresses({
    this.id,
    this.city,
    this.branchesCount,
    this.district,
    this.additionalData,
    this.country,
    this.subdistrict,
    this.searchTerms,
    this.longitude,
    this.latitude,
    this.county,
    this.state,
    this.street,
    this.place,
    this.addressLines,
    this.postalCode,
    this.houseNumber,
  });

  @override
  String toString() {
    String result = '';
    /*
    return 'id: $id, city: $city, branchesCount: $branchesCount, ' +
        'district: $district, additionalData: $additionalData, ' +
        'country: $country, subdistrict: $subdistrict, ' +
        'searchTerms: $searchTerms, longitude: $longitude, ' +
        'latitude: $latitude, county: $county, state: $state, ' +
        'street: $street, place: $place, addressLines: $addressLines, ' +
        'postalCode: $postalCode, houseNumber: $houseNumber';
    */
    if (postalCode != null && postalCode != '') {
      result += '$postalCode, ';
    }
    if (city != null && city != '') {
      result += '$city';
    }
    if (district != null && district != '') {
      result += ', $district';
    }
    if (subdistrict != null && subdistrict != '') {
      result += ', $subdistrict';
    }
    if (street != null && street != '') {
      result += ', $street';
    }
    if (houseNumber != null && houseNumber != '') {
      result += ', $houseNumber';
    }
    return result;
  }

  static List<Addresses> jsonFromList(List<dynamic> arr) {
    List<Addresses> result = [];
    arr.forEach((item) {
      result.add(Addresses.fromJson(item));
    });
    return result;
  }

  factory Addresses.fromJson(Map<String, dynamic> json) {
    return Addresses(
      id: json['id'] as int,
      city: json['city'] as String,
      branchesCount: json['branches_count'] as int,
      district: json['district'] as String,
      additionalData: json['additionalData'] as String,
      country: json['country'] as String,
      subdistrict: json['subdistrict'] as String,
      searchTerms: json['search_terms'] as String,
      longitude: AbstractModel.getDouble(json['longitude']),
      latitude: AbstractModel.getDouble(json['latitude']),
      county: json['county'] as String,
      state: json['state'] as String,
      street: json['street'] as String,
      place: json['place'] as String,
      addressLines: json['addressLines'] as String,
      postalCode: json['postalCode'] as String,
      houseNumber: json['houseNumber'] as String,
    );
  }

  /* Перегоняем данные из базы в модельку */
  static Addresses toModel(Map<String, dynamic> dbItem) {
    return Addresses(
      id: dbItem['id'],
      city: dbItem['city'],
      branchesCount: dbItem['branchesCount'],
      district: dbItem['district'],
      additionalData: dbItem['additionalData'],
      country: dbItem['country'],
      subdistrict: dbItem['subdistrict'],
      searchTerms: dbItem['searchTerms'],
      longitude: dbItem['longitude'].toDouble(),
      latitude: dbItem['latitude'].toDouble(),
      county: dbItem['county'],
      state: dbItem['state'],
      street: dbItem['street'],
      place: dbItem['place'],
      addressLines: dbItem['addressLines'],
      postalCode: dbItem['postalCode'],
      houseNumber: dbItem['houseNumber'],
    );
  }

  static Future<Addresses> getAddress(int addressId) async {
    final db = await openCompaniesDB();
    final List<Map<String, dynamic>> addresses = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [addressId],
    );
    if (addresses.isEmpty) {
      return null;
    }
    return toModel(addresses[0]);
  }
}

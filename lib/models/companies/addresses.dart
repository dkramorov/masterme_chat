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
  final String longitude;
  final String county;
  final String latitude;
  final String state;
  final String street;
  final String place;
  final String addressLines;
  final String postalCode;
  final String houseNumber;

  static final String tableName = 'addresses';

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
      'county': county,
      'latitude': latitude,
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
    this.county,
    this.latitude,
    this.state,
    this.street,
    this.place,
    this.addressLines,
    this.postalCode,
    this.houseNumber,
  });

  @override
  String toString() {
    return 'id: $id, city: $city, branchesCount: $branchesCount, ' +
        'district: $district, additionalData: $additionalData, ' +
        'country: $country, subdistrict: $subdistrict, ' +
        'searchTerms: $searchTerms, longitude: $longitude, ' +
        'county: $county, latitude: $latitude, state: $state, ' +
        'street: $street, place: $place, addressLines: $addressLines, ' +
        'postalCode: $postalCode, houseNumber: $houseNumber';
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
      branchesCount: json['branchesCount'] as int,
      district: json['district'] as String,
      additionalData: json['additionalData'] as String,
      country: json['country'] as String,
      subdistrict: json['subdistrict'] as String,
      searchTerms: json['searchTerms'] as String,
      longitude: json['longitude'] as String,
      county: json['county'] as String,
      latitude: json['latitude'] as String,
      state: json['state'] as String,
      street: json['street'] as String,
      place: json['place'] as String,
      addressLines: json['addressLines'] as String,
      postalCode: json['postalCode'] as String,
      houseNumber: json['houseNumber'] as String,
    );
  }
}

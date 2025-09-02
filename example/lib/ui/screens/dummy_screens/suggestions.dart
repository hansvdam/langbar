import 'dart:convert';

import 'package:http/http.dart' as http;

class Suggestions {
  List<Locations>? locations;

  Suggestions({this.locations});

  Suggestions.fromJson(Map<String, dynamic> json) {
    if (json['locations'] != null) {
      locations = <Locations>[];
      json['locations'].forEach((v) {
        locations!.add(Locations.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (locations != null) {
      data['locations'] = locations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Locations {
  String? type;
  String? categoryTitle;
  String? name;
  String? displayname;
  String? subType;
  String? region;
  String? url;

  Locations(
      {this.type,
        this.categoryTitle,
        this.name,
        this.displayname,
        this.subType,
        this.region,
        this.url});

  Locations.fromJson(Map<String, dynamic> json) {
    type = json['Type'];
    categoryTitle = json['CategoryTitle'];
    name = json['Name'];
    displayname = json['Displayname'];
    subType = json['SubType'];
    region = json['Region'];
    url = json['Url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Type'] = type;
    data['CategoryTitle'] = categoryTitle;
    data['Name'] = name;
    data['Displayname'] = displayname;
    data['SubType'] = subType;
    data['Region'] = region;
    data['Url'] = url;
    return data;
  }
}

Future<String> fetchSuggestion (String placeName) async {
  var result = await fetchSuggestions(placeName);
  return result.locations!.first.displayname!;
}

Future<Suggestions> fetchSuggestions(String placeName) async {

    String baseUrl = "9292.nl";
    String endpoint = "suggest";
    Map<String, String> queryParams = {
      'locationType': 'AllLocationTypes',
      'userInput': placeName,
    };

    // for api explanation see: https://open-meteo.com/en/docs
    Uri url = Uri.https(baseUrl, endpoint, queryParams);
    var response = await http.get(url);
    if (response.statusCode == 200) {
      return Suggestions.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch data');
    }
}


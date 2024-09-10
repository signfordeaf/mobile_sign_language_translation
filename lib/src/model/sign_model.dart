class SignModel {
  bool? state;
  String? baseUrl;
  String? name;
  String? cid;
  bool? st;

  SignModel({this.state, this.baseUrl, this.name, this.cid, this.st});

  SignModel.fromJson(Map<String, dynamic> json) {
    state = json['state'];
    baseUrl = json['baseUrl'];
    name = json['name'];
    cid = json['cid'];
    st = json['st'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['state'] = state;
    data['baseUrl'] = baseUrl;
    data['name'] = name;
    data['cid'] = cid;
    data['st'] = st;
    return data;
  }
}

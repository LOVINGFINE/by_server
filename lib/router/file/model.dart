class CloudFile {
  String url;
  String mineType;
  String filename;
  String uploadTime;
  CloudFile(
      {this.url = '',
      this.mineType = '',
      this.filename = '',
      this.uploadTime = ''});

  Map<String, dynamic> get toJson {
    return {
      'url': url,
      'mineType': mineType,
      'filename': filename,
      'uploadTime': uploadTime,
    };
  }

  CloudFile.fromJson(Map<String, dynamic> json)
      : url = json['url'],
        filename = json['filename'],
        mineType = json['mineType'],
        uploadTime = json['uploadTime'];
}

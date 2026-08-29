class WeatherStringUtils {
  WeatherStringUtils._();

  /// Hàm loại bỏ dấu tiếng Việt để so sánh tìm kiếm thông minh
  static String removeDiacritics(String str, {bool toLowerCase = false}) {
    const vietnameseMap = {
      'a': 'áàảãạăắằẳẵặâấầẩẫậ',
      'A': 'ÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬ',
      'd': 'đ',
      'D': 'Đ',
      'e': 'éèẻẽẹêếềểễệ',
      'E': 'ÉÈẺẼẸÊẾỀỂỄỆ',
      'i': 'íìỉĩị',
      'I': 'ÍÌỈĨỊ',
      'o': 'óòỏõọôốồổỗộơớờởỡợ',
      'O': 'ÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢ',
      'u': 'úùủũụưứừửữự',
      'U': 'ÚÙỦŨỤƯỨỪỬỮỰ',
      'y': 'ýỳỷỹỵ',
      'Y': 'ÝỲỶỸỴ',
    };
    String result = str;
    vietnameseMap.forEach((nonDiacritic, diacritics) {
      for (int i = 0; i < diacritics.length; i++) {
        result = result.replaceAll(diacritics[i], nonDiacritic);
      }
    });
    return toLowerCase ? result.toLowerCase() : result;
  }
}

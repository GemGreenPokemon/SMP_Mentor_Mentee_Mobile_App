import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class Responsive {
  static bool isWeb() {
    return kIsWeb;
  }
  
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }
  
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768 &&
           MediaQuery.of(context).size.width <= 1024;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > 1024;
  }
  
  static bool isWebDesktop(BuildContext context) {
    return kIsWeb && isDesktop(context);
  }
  
  static bool isWebTablet(BuildContext context) {
    return kIsWeb && isTablet(context);
  }
  
  static bool isWebMobile(BuildContext context) {
    return kIsWeb && isMobile(context);
  }
} 
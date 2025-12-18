/// Form validators for input validation
class Validators {
  Validators._();

  /// Email validation
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    
    return null;
  }

  /// Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    return null;
  }

  /// Strong password validation
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain an uppercase letter';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain a lowercase letter';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain a number';
    }
    
    return null;
  }

  /// Confirm password validation
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      
      if (value != password) {
        return 'Passwords do not match';
      }
      
      return null;
    };
  }

  /// Required field validation
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Name validation
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    
    return null;
  }

  /// Phone number validation
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    
    // Remove common formatting
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    
    // Check if it's a valid phone number
    if (!RegExp(r'^\+?[1-9]\d{9,14}$').hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  /// Min length validation
  static String? Function(String?) minLength(int min, [String? fieldName]) {
    return (String? value) {
      if (value == null || value.trim().length < min) {
        return '${fieldName ?? 'This field'} must be at least $min characters';
      }
      return null;
    };
  }

  /// Max length validation
  static String? Function(String?) maxLength(int max, [String? fieldName]) {
    return (String? value) {
      if (value != null && value.trim().length > max) {
        return '${fieldName ?? 'This field'} must be less than $max characters';
      }
      return null;
    };
  }

  /// URL validation
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // URL is optional
    }
    
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );
    
    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  /// Price validation
  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }
    
    final price = double.tryParse(value.trim());
    if (price == null) {
      return 'Please enter a valid price';
    }
    
    if (price < 0) {
      return 'Price cannot be negative';
    }
    
    if (price > 9999) {
      return 'Price must be less than \$10,000';
    }
    
    return null;
  }

  /// Duration validation (minutes)
  static String? duration(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Duration is required';
    }
    
    final minutes = int.tryParse(value.trim());
    if (minutes == null) {
      return 'Please enter a valid duration';
    }
    
    if (minutes < 5) {
      return 'Duration must be at least 5 minutes';
    }
    
    if (minutes > 480) {
      return 'Duration must be less than 8 hours';
    }
    
    return null;
  }

  /// Compose multiple validators
  static String? Function(String?) compose(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }
}

/// Extension for easy validator chaining
extension ValidatorExtension on String? Function(String?) {
  String? Function(String?) and(String? Function(String?) other) {
    return (String? value) {
      final result = this(value);
      if (result != null) return result;
      return other(value);
    };
  }
}

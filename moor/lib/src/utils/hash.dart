// Shamelessly stolen from https://github.com/google/built_value.dart/blob/1fa5da43b5e121a1d3ec2e205f29ca80927958b0/built_value/lib/built_value.dart#L195-L209

/// For use by generated code in calculating hash codes. Do not use directly.
int $mrjc(int hash, int value) {
  // Jenkins hash "combine".
  hash = 0x1fffffff & (hash + value);
  hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
  return hash ^ (hash >> 6);
}

/// For use by generated code in calculating hash codes. Do not use directly.
int $mrjf(int hash) {
  // Jenkins hash "finish".
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash = hash ^ (hash >> 11);
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}

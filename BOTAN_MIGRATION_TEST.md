# Botan Dynamic Linking Migration Test Plan

## Changes Made

### 1. Build Configuration Changes
- **Before**: Botan built with `--disable-shared` (static linking)
- **After**: Botan built with `--enable-shared` (dynamic linking)

### 2. Library Distribution
- **Before**: Static library embedded in binary
- **After**: Shared libraries (`libbotan*.so*`) copied to runtime image

### 3. Library Discovery
- **Before**: No dynamic library setup needed
- **After**: Added `ldconfig` to register shared libraries

## Testing Checklist

### Build Test
```bash
# Test the build process
./build.sh kcptube-dynamic

# Alternative direct build
docker build -t kcptube-dynamic .
```

### Runtime Test
```bash
# Test the binary can load shared libraries
docker run --rm kcptube-dynamic ldd /usr/local/bin/kcptube

# Expected output should show libbotan-3.so.X linked dynamically
# Example expected line: 
#   libbotan-3.so.3 => /usr/local/lib/libbotan-3.so.3.6.1
```

### Functionality Test
```bash
# Test basic functionality
docker run --rm kcptube-dynamic --help

# Test with config file (if available)
docker run --rm -v ./config.example.conf:/tmp/config.conf:ro kcptube-dynamic /tmp/config.conf
```

### Library Size Verification
```bash
# Check if shared libraries are properly installed
docker run --rm kcptube-dynamic ls -la /usr/local/lib/libbotan*

# Check binary size reduction (should be smaller than static build)
docker run --rm kcptube-dynamic ls -lh /usr/local/bin/kcptube
```

## Benefits Achieved

1. **Reduced Binary Size**: Dynamic linking reduces the final binary size
2. **Library Sharing**: Multiple processes can share the same library in memory  
3. **Security Updates**: Botan library can be updated independently
4. **Flexibility**: Library versions can be managed separately

## Verification Points

- [ ] Build completes successfully
- [ ] `ldd` shows `libbotan-3.so` dynamically linked (not static)
- [ ] Runtime libraries are present in `/usr/local/lib/`
- [ ] Binary is smaller than previous static build
- [ ] Application functionality remains intact
- [ ] No missing library errors at runtime
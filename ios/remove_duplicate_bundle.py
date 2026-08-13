#!/usr/bin/env python3
"""
Removes RevenueCatUI-RevenueCat_RevenueCatUI target from Pods.xcodeproj
to fix "Multiple commands produce RevenueCat_RevenueCatUI.bundle" Xcode error.
The bundle is already provided by SPM's RevenueCat package.
"""

import re
import sys

PBXPROJ = "ios/Pods/Pods.xcodeproj/project.pbxproj"

with open(PBXPROJ, "r") as f:
    content = f.read()

original_len = len(content)

# 1. Find the target UUID for RevenueCatUI-RevenueCat_RevenueCatUI
target_uuid_match = re.search(
    r'([0-9A-F]{32})\s*/\*\s*RevenueCatUI-RevenueCat_RevenueCatUI\s*\*/\s*=\s*\{[^}]*isa\s*=\s*PBXNativeTarget',
    content
)
if not target_uuid_match:
    print("Target UUID not found, trying alternate pattern...")
    target_uuid_match = re.search(
        r'(CF57851EC915911B4B6C714AC16BCFFF)',
        content
    )

target_uuid = "CF57851EC915911B4B6C714AC16BCFFF"
print(f"Target UUID: {target_uuid}")

# 2. Find the product reference UUID (the .bundle file reference)
product_uuid_match = re.search(
    r'([0-9A-F]{32})\s*/\*\s*RevenueCatUI-RevenueCat_RevenueCatUI\s*\*/\s*=\s*\{[^}]*explicitFileType\s*=\s*wrapper\.cfbundle',
    content
)
if product_uuid_match:
    product_uuid = product_uuid_match.group(1)
else:
    product_uuid = "A11ADE067B216AB469480C2DE84D2D31"
print(f"Product UUID: {product_uuid}")

# 3. Find the PBXBuildFile UUID (RevenueCatUI-RevenueCat_RevenueCatUI in Resources)
build_file_uuid_match = re.search(
    r'([0-9A-F]{32})\s*/\*\s*RevenueCatUI-RevenueCat_RevenueCatUI in Resources\s*\*/',
    content
)
if build_file_uuid_match:
    build_file_uuid = build_file_uuid_match.group(1)
else:
    build_file_uuid = "274666BD336E8FD6C32E2112159442CA"
print(f"Build file UUID: {build_file_uuid}")

# 4. Find the Info.plist file reference UUID
plist_uuid_match = re.search(
    r'([0-9A-F]{32})\s*/\*\s*ResourceBundle-RevenueCat_RevenueCatUI-RevenueCatUI-Info\.plist\s*\*/',
    content
)
if plist_uuid_match:
    plist_uuid = plist_uuid_match.group(1)
else:
    plist_uuid = "44A3549E27B3B22F5C3DCDA0D5A3F2E9"
print(f"Info.plist UUID: {plist_uuid}")

# 5. Find and remove the PBXContainerItemProxy section for this target
# These look like: { isa = PBXContainerItemProxy; ... remoteInfo = "RevenueCatUI-RevenueCat_RevenueCatUI"; }
content = re.sub(
    r'\s*[0-9A-F]{32}\s*/\*.*?\*/\s*=\s*\{[^}]*remoteInfo\s*=\s*"RevenueCatUI-RevenueCat_RevenueCatUI"[^}]*\};\n?',
    '\n',
    content
)

# 6. Remove the PBXTargetDependency referencing our target
# These look like: UUID /* RevenueCatUI-RevenueCat_RevenueCatUI */ = { isa = PBXTargetDependency; ...}
content = re.sub(
    r'\s*[0-9A-F]{32}\s*/\*\s*RevenueCatUI-RevenueCat_RevenueCatUI\s*\*/\s*=\s*\{\s*isa\s*=\s*PBXTargetDependency[^}]*\};\n?',
    '\n',
    content
)

# 7. Remove the PBXNativeTarget section for our target  
content = re.sub(
    rf'\s*{target_uuid}\s*/\*\s*RevenueCatUI-RevenueCat_RevenueCatUI\s*\*/\s*=\s*\{{[^}}]*\}};\n?',
    '\n',
    content,
    flags=re.DOTALL
)

# 8. Remove PBXFileReference for the .bundle product
content = re.sub(
    rf'\s*{product_uuid}\s*/\*\s*RevenueCatUI-RevenueCat_RevenueCatUI\s*\*/[^\n]*\n',
    '\n',
    content
)

# 9. Remove PBXFileReference for the Info.plist
content = re.sub(
    rf'\s*{plist_uuid}\s*/\*\s*ResourceBundle-RevenueCat_RevenueCatUI-RevenueCatUI-Info\.plist\s*\*/[^\n]*\n',
    '\n',
    content
)

# 10. Remove PBXBuildFile entry
content = re.sub(
    rf'\s*{build_file_uuid}\s*/\*\s*RevenueCatUI-RevenueCat_RevenueCatUI in Resources\s*\*/[^\n]*\n',
    '\n',
    content
)

# 11. Remove the target UUID from any targets list
content = re.sub(
    rf'\s*{target_uuid}\s*/\*\s*RevenueCatUI-RevenueCat_RevenueCatUI\s*\*/,\n',
    '\n',
    content
)

# 12. Remove product UUID references from groups
content = re.sub(
    rf'\s*{product_uuid}\s*/\*\s*RevenueCatUI-RevenueCat_RevenueCatUI\s*\*/,\n',
    '\n',
    content
)

# 13. Remove plist UUID references from groups
content = re.sub(
    rf'\s*{plist_uuid}\s*/\*\s*ResourceBundle-RevenueCat_RevenueCatUI-RevenueCatUI-Info\.plist\s*\*/,\n',
    '\n',
    content
)

# 14. Remove the build file reference from resources copy phases
content = re.sub(
    rf'\s*{build_file_uuid}\s*/\*\s*RevenueCatUI-RevenueCat_RevenueCatUI in Resources\s*\*/,\n',
    '\n',
    content
)

new_len = len(content)
print(f"Removed {original_len - new_len} bytes")

with open(PBXPROJ, "w") as f:
    f.write(content)

print("Done! Pods.xcodeproj updated successfully.")

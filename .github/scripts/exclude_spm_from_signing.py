#!/usr/bin/env python3
"""
Exclude SPM targets from manual signing settings.
Keeps PROVISIONING_PROFILE_SPECIFIER only on the main app target release config.
"""

import os
import re
import sys


def find_release_config_variants(content: str, release_config_id: str):
    variants = []
    patterns = [
        ("with Release comment", rf'(\t\t{re.escape(release_config_id)} /\* Release \*/ = \{{)(.*?)(\t\t\}};)'),
        ("without comment", rf'(\t\t{re.escape(release_config_id)} = \{{)(.*?)(\t\t\}};)'),
        ("with any comment", rf'(\t\t{re.escape(release_config_id)} /\* [^*]+ \*/ = \{{)(.*?)(\t\t\}};)'),
    ]
    for name, pattern in patterns:
        match = re.search(pattern, content, flags=re.DOTALL)
        if match:
            variants.append((name, match))
    return variants


def add_profile_to_release_body(config_body: str, profile_uuid: str):
    body = re.sub(r'\t\t\t\tPROVISIONING_PROFILE_SPECIFIER\s*=\s*[^;]+;\s*\n?', "", config_body)
    if "CODE_SIGN_ENTITLEMENTS" in body:
        return re.sub(
            r'(CODE_SIGN_ENTITLEMENTS = [^;]+;)',
            rf"\1\n\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = {profile_uuid};",
            body,
            count=1,
        )
    if "CODE_SIGN_STYLE" in body:
        return re.sub(
            r'(CODE_SIGN_STYLE = [^;]+;)',
            rf"\1\n\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = {profile_uuid};",
            body,
            count=1,
        )
    if "DEVELOPMENT_TEAM" in body:
        return re.sub(
            r'(DEVELOPMENT_TEAM = [^;]+;)',
            rf"\1\n\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = {profile_uuid};",
            body,
            count=1,
        )
    return f"\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = {profile_uuid};\n" + body


def exclude_spm_from_signing(pbxproj_path: str, profile_uuid: str | None = None, target_name: str = "Bugs"):
    if not os.path.exists(pbxproj_path):
        print(f"❌ File not found: {pbxproj_path}")
        sys.exit(1)

    with open(pbxproj_path, "r", encoding="utf-8") as f:
        content = f.read()

    original = content
    changes_made = False

    config_list_id = None
    main_target_patterns = [
        rf'PBXNativeTarget "{re.escape(target_name)}" = \{{.*?buildConfigurationList = (\w{{24}})',
        rf'(\w{{24}}) /\* Build configuration list for PBXNativeTarget "{re.escape(target_name)}" \*/',
        rf'(\w{{24}}) /\* {re.escape(target_name)} \*/ = \{{.*?buildConfigurationList = (\w{{24}})',
    ]

    for idx, pattern in enumerate(main_target_patterns):
        match = re.search(pattern, content, flags=re.DOTALL)
        if not match:
            continue
        if idx == 2:
            config_list_id = match.group(2)
        else:
            config_list_id = match.group(1)
        break

    if not config_list_id:
        print(f"❌ Could not find target '{target_name}'")
        sys.exit(1)

    config_list_pattern = rf"{re.escape(config_list_id)} /\* Build configuration list[^}}]*?buildConfigurations = \(([^)]+)\);"
    config_list_match = re.search(config_list_pattern, content, flags=re.DOTALL)
    if not config_list_match:
        print("❌ Could not find buildConfigurations list for target")
        sys.exit(1)

    config_ids_text = config_list_match.group(1)
    main_config_ids = set()
    release_config_id = None
    for match in re.finditer(r"(\w{24}) /\* (Debug|Release) \*/", config_ids_text):
        cfg_id, cfg_name = match.group(1), match.group(2)
        main_config_ids.add(cfg_id)
        if cfg_name == "Release":
            release_config_id = cfg_id

    if not release_config_id:
        print("❌ Could not determine Release configuration ID")
        sys.exit(1)

    config_section_pattern = r"(\t\t)(\w{24}) (/\* [^*]+ \*/ = \{)(.*?)(\t\t\};)"

    def clean_non_main(match):
        nonlocal changes_made
        indent = match.group(1)
        config_id = match.group(2)
        config_header = match.group(3)
        config_body = match.group(4)
        config_footer = match.group(5)

        if config_id not in main_config_ids:
            new_body = re.sub(r"\t\t\t\tPROVISIONING_PROFILE_SPECIFIER\s*=\s*[^;]+;\s*\n?", "", config_body)
            new_body = re.sub(r"\t\t\t\tCODE_SIGN_ENTITLEMENTS\s*=\s*[^;]+;\s*\n?", "", new_body)
            if new_body != config_body:
                changes_made = True
                return indent + config_id + " " + config_header + new_body + config_footer
        return match.group(0)

    content = re.sub(config_section_pattern, clean_non_main, content, flags=re.DOTALL)

    if profile_uuid:
        variants = find_release_config_variants(content, release_config_id)
        if not variants:
            print("❌ Could not find Release configuration block to patch")
            sys.exit(1)

        patched = False
        for _, match in variants:
            header = match.group(1)
            body = match.group(2)
            footer = match.group(3)
            new_body = add_profile_to_release_body(body, profile_uuid)
            if f"PROVISIONING_PROFILE_SPECIFIER = {profile_uuid};" not in new_body:
                continue
            content = content[:match.start()] + header + new_body + footer + content[match.end():]
            changes_made = True
            patched = True
            break

        if not patched:
            print("❌ Failed to inject PROVISIONING_PROFILE_SPECIFIER into Release config")
            sys.exit(1)

    if changes_made and content != original:
        with open(pbxproj_path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"✅ Updated: {pbxproj_path}")
    else:
        print("ℹ️ No changes required")


if __name__ == "__main__":
    if len(sys.argv) < 2 or len(sys.argv) > 4:
        print("Usage: exclude_spm_from_signing.py <pbxproj_path> [profile_uuid] [target_name]")
        sys.exit(1)

    pbxproj = sys.argv[1]
    uuid = sys.argv[2] if len(sys.argv) > 2 else None
    target = sys.argv[3] if len(sys.argv) > 3 else "Bugs"
    exclude_spm_from_signing(pbxproj, uuid, target)

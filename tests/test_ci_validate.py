import unittest

from scripts.ci_validate import ValidationError, parse_mod_manifest


class ParseModManifestTests(unittest.TestCase):
    def test_parses_comments_and_declared_count(self):
        entries = parse_mod_manifest(
            "# pack (共 1 个 jar)\n"
            "example.jar | 0123456789abcdef0123456789abcdef01234567 | Modrinth: example\n"
        )

        self.assertEqual(len(entries), 1)
        self.assertEqual(entries[0].filename, "example.jar")
        self.assertEqual(entries[0].sha1, "0123456789abcdef0123456789abcdef01234567")

    def test_rejects_duplicate_jar_names_case_insensitively(self):
        manifest = (
            "Example.jar | 0123456789abcdef0123456789abcdef01234567 | Modrinth: example\n"
            "example.jar | 1123456789abcdef0123456789abcdef01234567 | Modrinth: other\n"
        )

        with self.assertRaisesRegex(ValidationError, "duplicate"):
            parse_mod_manifest(manifest)

    def test_rejects_invalid_hash_or_path(self):
        for row in (
            "../escape.jar | 0123456789abcdef0123456789abcdef01234567 | Modrinth: example",
            r"..\escape.jar | 0123456789abcdef0123456789abcdef01234567 | Modrinth: example",
            "example.jar | not-a-hash | Modrinth: example",
        ):
            with self.subTest(row=row), self.assertRaises(ValidationError):
                parse_mod_manifest(row)

    def test_rejects_stale_declared_count(self):
        with self.assertRaisesRegex(ValidationError, "declares 2 JARs"):
            parse_mod_manifest(
                "# 共 2 个 jar\n"
                "example.jar | 0123456789abcdef0123456789abcdef01234567 | Modrinth: example\n"
            )


if __name__ == "__main__":
    unittest.main()
